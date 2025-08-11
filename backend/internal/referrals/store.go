package referrals

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type store struct {
	db *pgxpool.Pool
}

func NewStore(db *pgxpool.Pool) Store {
	return &store{
		db: db,
	}
}

// CreateReferral creates a new referral in the database
func (s *store) CreateReferral(ctx context.Context, referral *Referral) (*Referral, error) {
	var metadataJSON *string
	if referral.Metadata != nil {
		metadataJSON = referral.Metadata
	}

	query := `
		INSERT INTO referrals (id, referred_by, referred_to, referral_type, item_id, reason, 
		                      status, is_urgent, metadata, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id, referred_by, referred_to, referral_type, item_id, reason, 
		          status, is_urgent, metadata, created_at, updated_at
	`

	var result Referral
	err := s.db.QueryRow(ctx, query,
		referral.ID, referral.ReferredBy, referral.ReferredTo, referral.ReferralType,
		referral.ItemID, referral.Reason, referral.Status, referral.IsUrgent,
		metadataJSON, referral.CreatedAt, referral.UpdatedAt,
	).Scan(
		&result.ID, &result.ReferredBy, &result.ReferredTo, &result.ReferralType,
		&result.ItemID, &result.Reason, &result.Status, &result.IsUrgent,
		&result.Metadata, &result.CreatedAt, &result.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create referral: %w", err)
	}

	// Get the referral with user details
	return s.GetReferralWithDetails(ctx, result.ID)
}

// GetReferralByID retrieves a referral by ID
func (s *store) GetReferralByID(ctx context.Context, referralID string) (*Referral, error) {
	query := `
		SELECT id, referred_by, referred_to, referral_type, item_id, reason, 
		       status, is_urgent, metadata, created_at, updated_at
		FROM referrals
		WHERE id = $1
	`

	var referral Referral
	err := s.db.QueryRow(ctx, query, referralID).Scan(
		&referral.ID, &referral.ReferredBy, &referral.ReferredTo, &referral.ReferralType,
		&referral.ItemID, &referral.Reason, &referral.Status, &referral.IsUrgent,
		&referral.Metadata, &referral.CreatedAt, &referral.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("referral not found")
		}
		return nil, fmt.Errorf("failed to get referral: %w", err)
	}

	return &referral, nil
}

// GetReferralWithDetails retrieves a referral with user and item details
func (s *store) GetReferralWithDetails(ctx context.Context, referralID string) (*Referral, error) {
	query := `
		SELECT r.id, r.referred_by, r.referred_to, r.referral_type, r.item_id, r.reason, 
		       r.status, r.is_urgent, r.metadata, r.created_at, r.updated_at,
		       referrer.full_name as referrer_name,
		       recipient.full_name as recipient_name,
		       COALESCE(
		           CASE 
		               WHEN r.referral_type = 'service' THEN s.name
		               WHEN r.referral_type = 'resource' THEN res.title
		               WHEN r.referral_type = 'support_group' THEN sg.name
		           END, 'Unknown Item'
		       ) as item_title,
		       COALESCE(
		           CASE 
		               WHEN r.referral_type = 'service' THEN s.description
		               WHEN r.referral_type = 'resource' THEN res.description
		               WHEN r.referral_type = 'support_group' THEN sg.description
		           END, ''
		       ) as item_description
		FROM referrals r
		JOIN users referrer ON r.referred_by = referrer.id
		JOIN users recipient ON r.referred_to = recipient.id
		LEFT JOIN services s ON r.referral_type = 'service' AND (r.item_id ~* '^[0-9a-fA-F-]{36}$') AND r.item_id::uuid = s.id
		LEFT JOIN resources res ON r.referral_type = 'resource' AND (r.item_id ~* '^[0-9a-fA-F-]{36}$') AND r.item_id::uuid = res.id
		LEFT JOIN support_groups sg ON r.referral_type = 'support_group' AND r.item_id = sg.id::text
		WHERE r.id = $1
	`

	var referral Referral
	err := s.db.QueryRow(ctx, query, referralID).Scan(
		&referral.ID, &referral.ReferredBy, &referral.ReferredTo, &referral.ReferralType,
		&referral.ItemID, &referral.Reason, &referral.Status, &referral.IsUrgent,
		&referral.Metadata, &referral.CreatedAt, &referral.UpdatedAt,
		&referral.ReferrerName, &referral.RecipientName, &referral.ItemTitle, &referral.ItemDescription,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("referral not found")
		}
		return nil, fmt.Errorf("failed to get referral with details: %w", err)
	}

	return &referral, nil
}

// ListReferralsSent retrieves sent referrals for a user
func (s *store) ListReferralsSent(ctx context.Context, referredBy string, req *ListReferralsRequest) (*ListReferralsResponse, error) {
	offset := (req.Page - 1) * req.PageSize

	var whereClause []string
	var args []interface{}
	argIndex := 1

	whereClause = append(whereClause, fmt.Sprintf("r.referred_by = $%d", argIndex))
	args = append(args, referredBy)
	argIndex++

	if req.Status != "" {
		whereClause = append(whereClause, fmt.Sprintf("r.status = $%d", argIndex))
		args = append(args, req.Status)
		argIndex++
	}

	if req.ReferralType != "" {
		whereClause = append(whereClause, fmt.Sprintf("r.referral_type = $%d", argIndex))
		args = append(args, req.ReferralType)
		argIndex++
	}

	if req.IsUrgent != nil {
		whereClause = append(whereClause, fmt.Sprintf("r.is_urgent = $%d", argIndex))
		args = append(args, *req.IsUrgent)
		argIndex++
	}

	whereSQL := "WHERE " + strings.Join(whereClause, " AND ")

	// Count total
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM referrals r %s", whereSQL)
	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count referrals: %w", err)
	}

	// Get referrals with details
	query := fmt.Sprintf(`
	SELECT r.id, r.referred_by, r.referred_to, r.referral_type, r.item_id, r.reason, 
	       r.status, r.is_urgent, r.metadata, r.created_at, r.updated_at,
	       referrer.full_name as referrer_name,
	       recipient.full_name as recipient_name,
	       COALESCE(
	           CASE 
	               WHEN r.referral_type = 'service' THEN s.name
	               WHEN r.referral_type = 'resource' THEN res.title
	               WHEN r.referral_type = 'support_group' THEN sg.name
	           END, 'Unknown Item'
	       ) as item_title,
	       COALESCE(
	           CASE 
	               WHEN r.referral_type = 'service' THEN s.description
	               WHEN r.referral_type = 'resource' THEN res.description
	               WHEN r.referral_type = 'support_group' THEN sg.description
	           END, ''
	       ) as item_description
	FROM referrals r
	JOIN users referrer ON r.referred_by = referrer.id
	JOIN users recipient ON r.referred_to = recipient.id
	LEFT JOIN services s ON r.referral_type = 'service' AND r.item_id ~* '^[0-9a-fA-F-]{36}$' AND r.item_id::uuid = s.id
	LEFT JOIN resources res ON r.referral_type = 'resource' AND r.item_id ~* '^[0-9a-fA-F-]{36}$' AND r.item_id::uuid = res.id
	LEFT JOIN support_groups sg ON r.referral_type = 'support_group' AND r.item_id = sg.id::text
	%s
	ORDER BY r.created_at DESC
	LIMIT $%d OFFSET $%d
`, whereSQL, argIndex, argIndex+1)

	args = append(args, req.PageSize, offset)

	rows, err := s.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query sent referrals: %w", err)
	}
	defer rows.Close()

	var referrals []Referral
	for rows.Next() {
		var referral Referral
		err := rows.Scan(
			&referral.ID, &referral.ReferredBy, &referral.ReferredTo, &referral.ReferralType,
			&referral.ItemID, &referral.Reason, &referral.Status, &referral.IsUrgent,
			&referral.Metadata, &referral.CreatedAt, &referral.UpdatedAt,
			&referral.ReferrerName, &referral.RecipientName, &referral.ItemTitle, &referral.ItemDescription,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan referral: %w", err)
		}
		referrals = append(referrals, referral)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	totalPages := int((total + int64(req.PageSize) - 1) / int64(req.PageSize))

	return &ListReferralsResponse{
		Referrals:  referrals,
		Total:      total,
		Page:       req.Page,
		PageSize:   req.PageSize,
		TotalPages: totalPages,
	}, nil
}

// ListReferralsReceived retrieves received referrals for a user
func (s *store) ListReferralsReceived(ctx context.Context, referredTo string, req *ListReferralsRequest) (*ListReferralsResponse, error) {
	offset := (req.Page - 1) * req.PageSize

	var whereClause []string
	var args []interface{}
	argIndex := 1

	whereClause = append(whereClause, fmt.Sprintf("r.referred_to = $%d", argIndex))
	args = append(args, referredTo)
	argIndex++

	if req.Status != "" {
		whereClause = append(whereClause, fmt.Sprintf("r.status = $%d", argIndex))
		args = append(args, req.Status)
		argIndex++
	}

	if req.ReferralType != "" {
		whereClause = append(whereClause, fmt.Sprintf("r.referral_type = $%d", argIndex))
		args = append(args, req.ReferralType)
		argIndex++
	}

	if req.IsUrgent != nil {
		whereClause = append(whereClause, fmt.Sprintf("r.is_urgent = $%d", argIndex))
		args = append(args, *req.IsUrgent)
		argIndex++
	}

	whereSQL := "WHERE " + strings.Join(whereClause, " AND ")

	// Count total
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM referrals r %s", whereSQL)
	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count referrals: %w", err)
	}

	// Get referrals with details
	query := fmt.Sprintf(`
		SELECT r.id, r.referred_by, r.referred_to, r.referral_type, r.item_id, r.reason, 
		       r.status, r.is_urgent, r.metadata, r.created_at, r.updated_at,
		       referrer.full_name as referrer_name,
		       recipient.full_name as recipient_name,
		       COALESCE(
		           CASE 
		               WHEN r.referral_type = 'service' THEN s.name
		               WHEN r.referral_type = 'resource' THEN res.title
		               WHEN r.referral_type = 'support_group' THEN sg.name
		           END, 'Unknown Item'
		       ) as item_title,
		       COALESCE(
		           CASE 
		               WHEN r.referral_type = 'service' THEN s.description
		               WHEN r.referral_type = 'resource' THEN res.description
		               WHEN r.referral_type = 'support_group' THEN sg.description
		           END, ''
		       ) as item_description
		FROM referrals r
		JOIN users referrer ON r.referred_by = referrer.id
		JOIN users recipient ON r.referred_to = recipient.id
		LEFT JOIN services s ON r.referral_type = 'service' AND r.item_id = s.id
		LEFT JOIN resources res ON r.referral_type = 'resource' AND r.item_id = res.id
		LEFT JOIN support_groups sg ON r.referral_type = 'support_group' AND r.item_id = sg.id::text
		%s
		ORDER BY r.created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereSQL, argIndex, argIndex+1)

	args = append(args, req.PageSize, offset)

	rows, err := s.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query received referrals: %w", err)
	}
	defer rows.Close()

	var referrals []Referral
	for rows.Next() {
		var referral Referral
		err := rows.Scan(
			&referral.ID, &referral.ReferredBy, &referral.ReferredTo, &referral.ReferralType,
			&referral.ItemID, &referral.Reason, &referral.Status, &referral.IsUrgent,
			&referral.Metadata, &referral.CreatedAt, &referral.UpdatedAt,
			&referral.ReferrerName, &referral.RecipientName, &referral.ItemTitle, &referral.ItemDescription,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan referral: %w", err)
		}
		referrals = append(referrals, referral)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	totalPages := int((total + int64(req.PageSize) - 1) / int64(req.PageSize))

	return &ListReferralsResponse{
		Referrals:  referrals,
		Total:      total,
		Page:       req.Page,
		PageSize:   req.PageSize,
		TotalPages: totalPages,
	}, nil
}

// UpdateReferral updates a referral
func (s *store) UpdateReferral(ctx context.Context, referralID string, req *UpdateReferralRequest) (*Referral, error) {
	var setParts []string
	var args []interface{}
	argIndex := 1

	if req.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, *req.Status)
		argIndex++
	}

	if req.Reason != nil {
		setParts = append(setParts, fmt.Sprintf("reason = $%d", argIndex))
		args = append(args, *req.Reason)
		argIndex++
	}

	if req.IsUrgent != nil {
		setParts = append(setParts, fmt.Sprintf("is_urgent = $%d", argIndex))
		args = append(args, *req.IsUrgent)
		argIndex++
	}

	if req.Metadata != nil {
		metadataJSON, err := json.Marshal(req.Metadata)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal metadata: %w", err)
		}
		metadataStr := string(metadataJSON)
		setParts = append(setParts, fmt.Sprintf("metadata = $%d", argIndex))
		args = append(args, &metadataStr)
		argIndex++
	}

	if len(setParts) == 0 {
		return s.GetReferralWithDetails(ctx, referralID)
	}

	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	query := fmt.Sprintf(`
		UPDATE referrals 
		SET %s
		WHERE id = $%d
		RETURNING id, referred_by, referred_to, referral_type, item_id, reason, 
		          status, is_urgent, metadata, created_at, updated_at
	`, strings.Join(setParts, ", "), argIndex)

	args = append(args, referralID)

	var referral Referral
	err := s.db.QueryRow(ctx, query, args...).Scan(
		&referral.ID, &referral.ReferredBy, &referral.ReferredTo, &referral.ReferralType,
		&referral.ItemID, &referral.Reason, &referral.Status, &referral.IsUrgent,
		&referral.Metadata, &referral.CreatedAt, &referral.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("referral not found")
		}
		return nil, fmt.Errorf("failed to update referral: %w", err)
	}

	return s.GetReferralWithDetails(ctx, referral.ID)
}

// UpdateReferralStatus updates only the status of a referral
func (s *store) UpdateReferralStatus(ctx context.Context, referralID string, status string) error {
	query := `
		UPDATE referrals 
		SET status = $1, updated_at = $2
		WHERE id = $3
	`

	result, err := s.db.Exec(ctx, query, status, time.Now(), referralID)
	if err != nil {
		return fmt.Errorf("failed to update referral status: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("referral not found")
	}

	return nil
}

// DeleteReferral soft deletes a referral (we might want to keep it for audit)
func (s *store) DeleteReferral(ctx context.Context, referralID string) error {
	query := `DELETE FROM referrals WHERE id = $1`

	result, err := s.db.Exec(ctx, query, referralID)
	if err != nil {
		return fmt.Errorf("failed to delete referral: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("referral not found")
	}

	return nil
}

// SearchUsers searches for users by name or email
func (s *store) SearchUsers(ctx context.Context, req *UserSearchRequest) (*UserSearchResponse, error) {
	var whereClause []string
	var args []interface{}
	argIndex := 1

	// Search in name and email
	searchQuery := "%" + strings.ToLower(req.Query) + "%"
	whereClause = append(whereClause, fmt.Sprintf("(LOWER(u.full_name) LIKE $%d OR LOWER(u.email) LIKE $%d)", argIndex, argIndex))
	args = append(args, searchQuery)
	argIndex++

	// Filter by role if specified
	if req.Role != "" {
		whereClause = append(whereClause, fmt.Sprintf("u.role = $%d", argIndex))
		args = append(args, req.Role)
		argIndex++
	}

	// Only active users
	whereClause = append(whereClause, "u.is_active = true")

	whereSQL := "WHERE " + strings.Join(whereClause, " AND ")

	// Count total
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM users u %s", whereSQL)
	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count users: %w", err)
	}

	// Get users with profile info
	query := fmt.Sprintf(`
		SELECT u.id, u.full_name, u.email, u.role, u.created_at, up.phone_number
		FROM users u
		LEFT JOIN user_profiles up ON u.id = up.user_id
		%s
		ORDER BY u.full_name ASC
		LIMIT $%d
	`, whereSQL, argIndex)

	args = append(args, req.Limit)

	rows, err := s.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to search users: %w", err)
	}
	defer rows.Close()

	var users []UserSearchResult
	for rows.Next() {
		var user UserSearchResult
		err := rows.Scan(
			&user.ID, &user.FullName, &user.Email, &user.Role, &user.CreatedAt, &user.PhoneNumber,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return &UserSearchResponse{
		Users: users,
		Total: total,
		Query: req.Query,
	}, nil
}

// GetReferralStats retrieves referral statistics for a user
func (s *store) GetReferralStats(ctx context.Context, userID string) (*ReferralStats, error) {
	stats := &ReferralStats{
		ReferralsByType:   make(map[string]int64),
		ReferralsByStatus: make(map[string]int64),
	}

	// Get basic counts (sent referrals)
	err := s.db.QueryRow(ctx, `
		SELECT 
			COUNT(*) as total,
			COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
			COUNT(CASE WHEN status = 'accepted' THEN 1 END) as accepted,
			COUNT(CASE WHEN status = 'declined' THEN 1 END) as declined,
			COUNT(CASE WHEN is_urgent = true THEN 1 END) as urgent
		FROM referrals 
		WHERE referred_by = $1
	`, userID).Scan(
		&stats.TotalReferrals, &stats.PendingReferrals, &stats.AcceptedReferrals,
		&stats.DeclinedReferrals, &stats.UrgentReferrals,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get basic stats: %w", err)
	}

	// Calculate acceptance rate
	if stats.TotalReferrals > 0 {
		stats.AcceptanceRate = float64(stats.AcceptedReferrals) / float64(stats.TotalReferrals) * 100
	}

	// Get referrals by type
	rows, err := s.db.Query(ctx, `
		SELECT referral_type, COUNT(*) 
		FROM referrals 
		WHERE referred_by = $1 
		GROUP BY referral_type
	`, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get referrals by type: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var refType string
		var count int64
		err := rows.Scan(&refType, &count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan type stats: %w", err)
		}
		stats.ReferralsByType[refType] = count
	}

	// Get referrals by status
	rows, err = s.db.Query(ctx, `
		SELECT status, COUNT(*) 
		FROM referrals 
		WHERE referred_by = $1 
		GROUP BY status
	`, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get referrals by status: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var status string
		var count int64
		err := rows.Scan(&status, &count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan status stats: %w", err)
		}
		stats.ReferralsByStatus[status] = count
	}

	// Get recent referrals (last 5)
	recentQuery := `
		SELECT r.id, r.referred_by, r.referred_to, r.referral_type, r.item_id, r.reason, 
		       r.status, r.is_urgent, r.metadata, r.created_at, r.updated_at,
		       referrer.full_name as referrer_name,
		       recipient.full_name as recipient_name,
		       COALESCE(
		           CASE 
		               WHEN r.referral_type = 'service' THEN s.name
		               WHEN r.referral_type = 'resource' THEN res.title
		               WHEN r.referral_type = 'support_group' THEN sg.name
		           END, 'Unknown Item'
		       ) as item_title,
		       COALESCE(
		           CASE 
		               WHEN r.referral_type = 'service' THEN s.description
		               WHEN r.referral_type = 'resource' THEN res.description
		               WHEN r.referral_type = 'support_group' THEN sg.description
		           END, ''
		       ) as item_description
		FROM referrals r
		JOIN users referrer ON r.referred_by = referrer.id
		JOIN users recipient ON r.referred_to = recipient.id
		LEFT JOIN services s ON r.referral_type = 'service' AND r.item_id = s.id
		LEFT JOIN resources res ON r.referral_type = 'resource' AND r.item_id = res.id
		LEFT JOIN support_groups sg ON r.referral_type = 'support_group' AND r.item_id = sg.id::text
		WHERE r.referred_by = $1
		ORDER BY r.created_at DESC
		LIMIT 5
	`

	rows, err = s.db.Query(ctx, recentQuery, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent referrals: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var referral Referral
		err := rows.Scan(
			&referral.ID, &referral.ReferredBy, &referral.ReferredTo, &referral.ReferralType,
			&referral.ItemID, &referral.Reason, &referral.Status, &referral.IsUrgent,
			&referral.Metadata, &referral.CreatedAt, &referral.UpdatedAt,
			&referral.ReferrerName, &referral.RecipientName, &referral.ItemTitle, &referral.ItemDescription,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan recent referral: %w", err)
		}
		stats.RecentReferrals = append(stats.RecentReferrals, referral)
	}

	return stats, nil
}

// GetReferralsByItem gets all referrals for a specific item
func (s *store) GetReferralsByItem(ctx context.Context, itemID string, itemType string) ([]Referral, error) {
	query := `
		SELECT r.id, r.referred_by, r.referred_to, r.referral_type, r.item_id, r.reason, 
		       r.status, r.is_urgent, r.metadata, r.created_at, r.updated_at,
		       referrer.full_name as referrer_name,
		       recipient.full_name as recipient_name
		FROM referrals r
		JOIN users referrer ON r.referred_by = referrer.id
		JOIN users recipient ON r.referred_to = recipient.id
		WHERE r.item_id = $1 AND r.referral_type = $2
		ORDER BY r.created_at DESC
	`

	rows, err := s.db.Query(ctx, query, itemID, itemType)
	if err != nil {
		return nil, fmt.Errorf("failed to get referrals by item: %w", err)
	}
	defer rows.Close()

	var referrals []Referral
	for rows.Next() {
		var referral Referral
		err := rows.Scan(
			&referral.ID, &referral.ReferredBy, &referral.ReferredTo, &referral.ReferralType,
			&referral.ItemID, &referral.Reason, &referral.Status, &referral.IsUrgent,
			&referral.Metadata, &referral.CreatedAt, &referral.UpdatedAt,
			&referral.ReferrerName, &referral.RecipientName,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan referral: %w", err)
		}
		referrals = append(referrals, referral)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return referrals, nil
}

// CheckDuplicateReferral checks if a similar referral already exists
func (s *store) CheckDuplicateReferral(ctx context.Context, referredBy, referredTo, itemID, itemType string) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM referrals 
			WHERE referred_by = $1 AND referred_to = $2 AND item_id = $3 AND referral_type = $4
			AND status != 'declined'
			AND created_at > NOW() - INTERVAL '30 days'
		)
	`

	var exists bool
	err := s.db.QueryRow(ctx, query, referredBy, referredTo, itemID, itemType).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check duplicate referral: %w", err)
	}

	return exists, nil
}

// ValidateUserExists checks if a user exists and is active
func (s *store) ValidateUserExists(ctx context.Context, userID string) error {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE id = $1 AND is_active = true)`

	var exists bool
	err := s.db.QueryRow(ctx, query, userID).Scan(&exists)
	if err != nil {
		return fmt.Errorf("failed to validate user existence: %w", err)
	}

	if !exists {
		return fmt.Errorf("user not found or inactive")
	}

	return nil
}

// ValidateUserCanReceiveReferrals checks if user can receive referrals (service_user role)
func (s *store) ValidateUserCanReceiveReferrals(ctx context.Context, userID string) error {
	query := `SELECT role FROM users WHERE id = $1 AND is_active = true`

	var role string
	err := s.db.QueryRow(ctx, query, userID).Scan(&role)
	if err != nil {
		if err == pgx.ErrNoRows {
			return fmt.Errorf("user not found")
		}
		return fmt.Errorf("failed to get user role: %w", err)
	}

	if role != "service_user" {
		return fmt.Errorf("user cannot receive referrals (role: %s)", role)
	}

	return nil
}

// ValidateUserCanMakeReferrals checks if user can make referrals (professional/nhs_staff roles)
func (s *store) ValidateUserCanMakeReferrals(ctx context.Context, userID string) error {
	query := `SELECT role FROM users WHERE id = $1 AND is_active = true`

	var role string
	err := s.db.QueryRow(ctx, query, userID).Scan(&role)
	if err != nil {
		if err == pgx.ErrNoRows {
			return fmt.Errorf("user not found")
		}
		return fmt.Errorf("failed to get user role: %w", err)
	}

	if role != "professional" && role != "nhs_staff" {
		return fmt.Errorf("user cannot make referrals (role: %s)", role)
	}

	return nil
}

func (s *store) ValidateItemExists(ctx context.Context, itemID string, itemType string) error {
	var query string
	var exists bool

	switch itemType {
	case "service":
		query = `SELECT EXISTS(SELECT 1 FROM services WHERE id = $1 AND is_active = true)`
	case "resource":
		query = `SELECT EXISTS(SELECT 1 FROM resources WHERE id = $1 AND is_active = true)`
	case "support_group":
		// Support groups use integer IDs, so we need to convert
		query = `SELECT EXISTS(SELECT 1 FROM support_groups WHERE id = $1::integer AND is_active = true)`
	default:
		return fmt.Errorf("invalid referral type: %s", itemType)
	}

	err := s.db.QueryRow(ctx, query, itemID).Scan(&exists)
	if err != nil {
		return fmt.Errorf("failed to validate item existence: %w", err)
	}

	if !exists {
		return fmt.Errorf("%s not found or inactive", itemType)
	}

	return nil
}
