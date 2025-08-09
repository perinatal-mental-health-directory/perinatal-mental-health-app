// backend/internal/privacy/store.go
package privacy

import (
	"context"
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

// GetPrivacyPreferences retrieves user's privacy preferences
func (s *store) GetPrivacyPreferences(ctx context.Context, userID string) (*PrivacyPreferences, error) {
	query := `
		SELECT user_id, data_tracking_enabled, data_sharing_enabled, cookies_enabled,
			   marketing_emails_enabled, analytics_enabled, created_at, updated_at
		FROM privacy_preferences
		WHERE user_id = $1
	`

	var preferences PrivacyPreferences
	err := s.db.QueryRow(ctx, query, userID).Scan(
		&preferences.UserID,
		&preferences.DataTrackingEnabled,
		&preferences.DataSharingEnabled,
		&preferences.CookiesEnabled,
		&preferences.MarketingEmailsEnabled,
		&preferences.AnalyticsEnabled,
		&preferences.CreatedAt,
		&preferences.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("privacy preferences not found")
		}
		return nil, fmt.Errorf("failed to get privacy preferences: %w", err)
	}

	return &preferences, nil
}

// CreatePrivacyPreferences creates default privacy preferences for a user
func (s *store) CreatePrivacyPreferences(ctx context.Context, preferences *PrivacyPreferences) error {
	query := `
		INSERT INTO privacy_preferences (user_id, data_tracking_enabled, data_sharing_enabled,
										cookies_enabled, marketing_emails_enabled, analytics_enabled,
										created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	_, err := s.db.Exec(ctx, query,
		preferences.UserID,
		preferences.DataTrackingEnabled,
		preferences.DataSharingEnabled,
		preferences.CookiesEnabled,
		preferences.MarketingEmailsEnabled,
		preferences.AnalyticsEnabled,
		preferences.CreatedAt,
		preferences.UpdatedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to create privacy preferences: %w", err)
	}

	return nil
}

// UpdatePrivacyPreferences updates user's privacy preferences
func (s *store) UpdatePrivacyPreferences(ctx context.Context, userID string, req *UpdatePrivacyPreferencesRequest) error {
	var setParts []string
	var args []interface{}
	argIndex := 1

	if req.DataTrackingEnabled != nil {
		setParts = append(setParts, fmt.Sprintf("data_tracking_enabled = $%d", argIndex))
		args = append(args, *req.DataTrackingEnabled)
		argIndex++
	}

	if req.DataSharingEnabled != nil {
		setParts = append(setParts, fmt.Sprintf("data_sharing_enabled = $%d", argIndex))
		args = append(args, *req.DataSharingEnabled)
		argIndex++
	}

	if req.CookiesEnabled != nil {
		setParts = append(setParts, fmt.Sprintf("cookies_enabled = $%d", argIndex))
		args = append(args, *req.CookiesEnabled)
		argIndex++
	}

	if req.MarketingEmailsEnabled != nil {
		setParts = append(setParts, fmt.Sprintf("marketing_emails_enabled = $%d", argIndex))
		args = append(args, *req.MarketingEmailsEnabled)
		argIndex++
	}

	if req.AnalyticsEnabled != nil {
		setParts = append(setParts, fmt.Sprintf("analytics_enabled = $%d", argIndex))
		args = append(args, *req.AnalyticsEnabled)
		argIndex++
	}

	if len(setParts) == 0 {
		return fmt.Errorf("no fields to update")
	}

	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	query := fmt.Sprintf(`
		UPDATE privacy_preferences 
		SET %s
		WHERE user_id = $%d
	`, strings.Join(setParts, ", "), argIndex)

	args = append(args, userID)

	result, err := s.db.Exec(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to update privacy preferences: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("privacy preferences not found")
	}

	return nil
}

// GetUserData retrieves user data for export
func (s *store) GetUserData(ctx context.Context, userID string) (map[string]interface{}, error) {
	query := `
		SELECT id, email, full_name, role, is_active, last_login_at, created_at, updated_at
		FROM users
		WHERE id = $1
	`

	var id, email, fullName, role string
	var isActive bool
	var lastLoginAt *time.Time
	var createdAt, updatedAt time.Time

	err := s.db.QueryRow(ctx, query, userID).Scan(
		&id,
		&email,
		&fullName,
		&role,
		&isActive,
		&lastLoginAt,
		&createdAt,
		&updatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get user data: %w", err)
	}

	user := map[string]interface{}{
		"id":         id,
		"email":      email,
		"full_name":  fullName,
		"role":       role,
		"is_active":  isActive,
		"created_at": createdAt,
		"updated_at": updatedAt,
	}

	if lastLoginAt != nil {
		user["last_login_at"] = *lastLoginAt
	}

	return user, nil
}

// GetUserProfileData retrieves user profile data for export
func (s *store) GetUserProfileData(ctx context.Context, userID string) (map[string]interface{}, error) {
	query := `
		SELECT user_id, phone_number, date_of_birth, address, emergency_contact,
			   preferences, created_at, updated_at
		FROM user_profiles
		WHERE user_id = $1
	`

	var profileUserID string
	var phoneNumber, address, emergencyContact, preferences *string
	var dateOfBirth *time.Time
	var createdAt, updatedAt time.Time

	err := s.db.QueryRow(ctx, query, userID).Scan(
		&profileUserID,
		&phoneNumber,
		&dateOfBirth,
		&address,
		&emergencyContact,
		&preferences,
		&createdAt,
		&updatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return map[string]interface{}{"user_id": userID}, nil
		}
		return nil, fmt.Errorf("failed to get user profile data: %w", err)
	}

	profile := map[string]interface{}{
		"user_id":    profileUserID,
		"created_at": createdAt,
		"updated_at": updatedAt,
	}

	if phoneNumber != nil {
		profile["phone_number"] = *phoneNumber
	}
	if dateOfBirth != nil {
		profile["date_of_birth"] = *dateOfBirth
	}
	if address != nil {
		profile["address"] = *address
	}
	if emergencyContact != nil {
		profile["emergency_contact"] = *emergencyContact
	}
	if preferences != nil {
		profile["preferences"] = *preferences
	}

	return profile, nil
}

// CreateDataRequest creates a new data request
func (s *store) CreateDataRequest(ctx context.Context, request *DataRequest) error {
	query := `
		INSERT INTO data_requests (id, user_id, request_type, status, reason, requested_at, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	_, err := s.db.Exec(ctx, query,
		request.ID,
		request.UserID,
		request.RequestType,
		request.Status,
		request.Reason,
		request.RequestedAt,
		request.CreatedAt,
		request.UpdatedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to create data request: %w", err)
	}

	return nil
}

// GetDataRequestsByUser retrieves all data requests for a user
func (s *store) GetDataRequestsByUser(ctx context.Context, userID string) ([]DataRequest, error) {
	query := `
		SELECT id, user_id, request_type, status, reason, requested_at, processed_at, 
			   processed_by, notes, created_at, updated_at
		FROM data_requests
		WHERE user_id = $1
		ORDER BY requested_at DESC
	`

	rows, err := s.db.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get data requests: %w", err)
	}
	defer rows.Close()

	var requests []DataRequest
	for rows.Next() {
		var request DataRequest
		err := rows.Scan(
			&request.ID,
			&request.UserID,
			&request.RequestType,
			&request.Status,
			&request.Reason,
			&request.RequestedAt,
			&request.ProcessedAt,
			&request.ProcessedBy,
			&request.Notes,
			&request.CreatedAt,
			&request.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan data request: %w", err)
		}
		requests = append(requests, request)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return requests, nil
}

// UpdateDataRequestStatus updates the status of a data request
func (s *store) UpdateDataRequestStatus(ctx context.Context, requestID, status string, notes *string) error {
	query := `
		UPDATE data_requests 
		SET status = $1, notes = $2, updated_at = $3
		WHERE id = $4
	`

	result, err := s.db.Exec(ctx, query, status, notes, time.Now(), requestID)
	if err != nil {
		return fmt.Errorf("failed to update data request status: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("data request not found")
	}

	return nil
}
