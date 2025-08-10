// backend/internal/support_groups/store.go
package support_groups

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

// ListSupportGroups retrieves a paginated list of support groups with filtering
func (s *store) ListSupportGroups(ctx context.Context, page, pageSize int, category, platform string) (*ListSupportGroupsResponse, error) {
	offset := (page - 1) * pageSize

	var whereClause []string
	var args []interface{}
	argIndex := 1

	// Always filter for active groups
	whereClause = append(whereClause, "is_active = true")

	// Add category filter
	if category != "" {
		whereClause = append(whereClause, fmt.Sprintf("category = $%d", argIndex))
		args = append(args, category)
		argIndex++
	}

	// Add platform filter
	if platform != "" {
		whereClause = append(whereClause, fmt.Sprintf("platform = $%d", argIndex))
		args = append(args, platform)
		argIndex++
	}

	// Build WHERE clause
	whereSQL := ""
	if len(whereClause) > 0 {
		whereSQL = "WHERE " + strings.Join(whereClause, " AND ")
	}

	// Count total support groups
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*) 
		FROM support_groups 
		%s
	`, whereSQL)

	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count support groups: %w", err)
	}

	// Get support groups with pagination
	query := fmt.Sprintf(`
		SELECT id, name, description, category, platform, doctor_info, url, guidelines,
			   meeting_time, max_members, is_active, created_at, updated_at
		FROM support_groups
		%s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereSQL, argIndex, argIndex+1)

	args = append(args, pageSize, offset)

	rows, err := s.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query support groups: %w", err)
	}
	defer rows.Close()

	var supportGroups []SupportGroup
	for rows.Next() {
		var group SupportGroup

		err := rows.Scan(
			&group.ID,
			&group.Name,
			&group.Description,
			&group.Category,
			&group.Platform,
			&group.DoctorInfo,
			&group.URL,
			&group.Guidelines,
			&group.MeetingTime,
			&group.MaxMembers,
			&group.IsActive,
			&group.CreatedAt,
			&group.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan support group: %w", err)
		}

		supportGroups = append(supportGroups, group)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))

	return &ListSupportGroupsResponse{
		SupportGroups: supportGroups,
		Total:         total,
		Page:          page,
		PageSize:      pageSize,
		TotalPages:    totalPages,
	}, nil
}

// GetSupportGroupByID retrieves a support group by ID
func (s *store) GetSupportGroupByID(ctx context.Context, groupID int) (*SupportGroup, error) {
	query := `
		SELECT id, name, description, category, platform, doctor_info, url, guidelines,
			   meeting_time, max_members, is_active, created_at, updated_at
		FROM support_groups
		WHERE id = $1 AND is_active = true
	`

	var group SupportGroup

	err := s.db.QueryRow(ctx, query, groupID).Scan(
		&group.ID,
		&group.Name,
		&group.Description,
		&group.Category,
		&group.Platform,
		&group.DoctorInfo,
		&group.URL,
		&group.Guidelines,
		&group.MeetingTime,
		&group.MaxMembers,
		&group.IsActive,
		&group.CreatedAt,
		&group.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("support group not found")
		}
		return nil, fmt.Errorf("failed to get support group: %w", err)
	}

	return &group, nil
}

// SearchSupportGroups searches support groups by name and description
func (s *store) SearchSupportGroups(ctx context.Context, query string, page, pageSize int) (*ListSupportGroupsResponse, error) {
	offset := (page - 1) * pageSize

	searchQuery := "%" + strings.ToLower(query) + "%"

	// Count total matching support groups
	countSQL := `
		SELECT COUNT(*) 
		FROM support_groups 
		WHERE is_active = true 
		AND (LOWER(name) LIKE $1 
		     OR LOWER(description) LIKE $1 
		     OR LOWER(category) LIKE $1)
	`

	var total int64
	err := s.db.QueryRow(ctx, countSQL, searchQuery).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count search results: %w", err)
	}

	// Get matching support groups
	searchSQL := `
		SELECT id, name, description, category, platform, doctor_info, url, guidelines,
			   meeting_time, max_members, is_active, created_at, updated_at
		FROM support_groups
		WHERE is_active = true 
		AND (LOWER(name) LIKE $1 
		     OR LOWER(description) LIKE $1 
		     OR LOWER(category) LIKE $1)
		ORDER BY 
			CASE 
				WHEN LOWER(name) LIKE $1 THEN 1 
				WHEN LOWER(category) LIKE $1 THEN 2 
				ELSE 3 
			END,
			created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := s.db.Query(ctx, searchSQL, searchQuery, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to search support groups: %w", err)
	}
	defer rows.Close()

	var supportGroups []SupportGroup
	for rows.Next() {
		var group SupportGroup

		err := rows.Scan(
			&group.ID,
			&group.Name,
			&group.Description,
			&group.Category,
			&group.Platform,
			&group.DoctorInfo,
			&group.URL,
			&group.Guidelines,
			&group.MeetingTime,
			&group.MaxMembers,
			&group.IsActive,
			&group.CreatedAt,
			&group.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan support group: %w", err)
		}

		supportGroups = append(supportGroups, group)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))

	return &ListSupportGroupsResponse{
		SupportGroups: supportGroups,
		Total:         total,
		Page:          page,
		PageSize:      pageSize,
		TotalPages:    totalPages,
	}, nil
}

// GetSupportGroupsByCategory retrieves support groups by category
func (s *store) GetSupportGroupsByCategory(ctx context.Context, category string, page, pageSize int) (*ListSupportGroupsResponse, error) {
	return s.ListSupportGroups(ctx, page, pageSize, category, "")
}

// GetSupportGroupsByPlatform retrieves support groups by platform
func (s *store) GetSupportGroupsByPlatform(ctx context.Context, platform string, page, pageSize int) (*ListSupportGroupsResponse, error) {
	return s.ListSupportGroups(ctx, page, pageSize, "", platform)
}

// GetUserGroups retrieves all groups a user is a member of
func (s *store) GetUserGroups(ctx context.Context, userID string) ([]SupportGroup, error) {
	query := `
		SELECT sg.id, sg.name, sg.description, sg.category, sg.platform, sg.doctor_info, 
			   sg.url, sg.guidelines, sg.meeting_time, sg.max_members, sg.is_active, 
			   sg.created_at, sg.updated_at
		FROM support_groups sg
		INNER JOIN group_memberships gm ON sg.id = gm.group_id
		WHERE gm.user_id = $1 AND gm.is_active = true AND sg.is_active = true
		ORDER BY gm.joined_at DESC
	`

	rows, err := s.db.Query(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user groups: %w", err)
	}
	defer rows.Close()

	var groups []SupportGroup
	for rows.Next() {
		var group SupportGroup

		err := rows.Scan(
			&group.ID,
			&group.Name,
			&group.Description,
			&group.Category,
			&group.Platform,
			&group.DoctorInfo,
			&group.URL,
			&group.Guidelines,
			&group.MeetingTime,
			&group.MaxMembers,
			&group.IsActive,
			&group.CreatedAt,
			&group.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan group: %w", err)
		}

		groups = append(groups, group)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return groups, nil
}

// GetGroupMembers retrieves all members of a support group
func (s *store) GetGroupMembers(ctx context.Context, groupID int) ([]GroupMembership, error) {
	query := `
		SELECT id, user_id, group_id, joined_at, is_active, role, created_at, updated_at
		FROM group_memberships
		WHERE group_id = $1 AND is_active = true
		ORDER BY joined_at ASC
	`

	rows, err := s.db.Query(ctx, query, groupID)
	if err != nil {
		return nil, fmt.Errorf("failed to get group members: %w", err)
	}
	defer rows.Close()

	var members []GroupMembership
	for rows.Next() {
		var member GroupMembership

		err := rows.Scan(
			&member.ID,
			&member.UserID,
			&member.GroupID,
			&member.JoinedAt,
			&member.IsActive,
			&member.Role,
			&member.CreatedAt,
			&member.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan member: %w", err)
		}

		members = append(members, member)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return members, nil
}

// IsUserMember checks if a user is a member of a support group
func (s *store) IsUserMember(ctx context.Context, userID string, groupID int) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM group_memberships 
			WHERE user_id = $1 AND group_id = $2 AND is_active = true
		)
	`

	var exists bool
	err := s.db.QueryRow(ctx, query, userID, groupID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check membership: %w", err)
	}

	return exists, nil
}

// JoinGroup adds a user to a support group
func (s *store) JoinGroup(ctx context.Context, userID string, groupID int) error {
	now := time.Now()

	query := `
		INSERT INTO group_memberships (user_id, group_id, joined_at, is_active, role, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	_, err := s.db.Exec(ctx, query, userID, groupID, now, true, "member", now, now)
	if err != nil {
		return fmt.Errorf("failed to join group: %w", err)
	}

	return nil
}

// LeaveGroup removes a user from a support group (soft delete)
func (s *store) LeaveGroup(ctx context.Context, userID string, groupID int) error {
	query := `
		UPDATE group_memberships 
		SET is_active = false, updated_at = $1
		WHERE user_id = $2 AND group_id = $3
	`

	result, err := s.db.Exec(ctx, query, time.Now(), userID, groupID)
	if err != nil {
		return fmt.Errorf("failed to leave group: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("membership not found")
	}

	return nil
}

// RemoveUserFromGroup removes a user from a group (admin action)
func (s *store) RemoveUserFromGroup(ctx context.Context, userID string, groupID int) error {
	return s.LeaveGroup(ctx, userID, groupID) // Same implementation for now
}

// GetSupportGroupStats retrieves support group statistics
func (s *store) GetSupportGroupStats(ctx context.Context) (*SupportGroupStats, error) {
	// Get basic counts
	var totalGroups, activeGroups, totalMembers int64

	// Count total groups
	err := s.db.QueryRow(ctx, "SELECT COUNT(*) FROM support_groups").Scan(&totalGroups)
	if err != nil {
		return nil, fmt.Errorf("failed to count total groups: %w", err)
	}

	// Count active groups
	err = s.db.QueryRow(ctx, "SELECT COUNT(*) FROM support_groups WHERE is_active = true").Scan(&activeGroups)
	if err != nil {
		return nil, fmt.Errorf("failed to count active groups: %w", err)
	}

	// Count total active members
	err = s.db.QueryRow(ctx, "SELECT COUNT(*) FROM group_memberships WHERE is_active = true").Scan(&totalMembers)
	if err != nil {
		return nil, fmt.Errorf("failed to count total members: %w", err)
	}

	// Get groups by category
	groupsByCategory := make(map[string]int64)
	rows, err := s.db.Query(ctx, `
		SELECT category, COUNT(*) 
		FROM support_groups 
		WHERE is_active = true 
		GROUP BY category
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to get groups by category: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var category string
		var count int64
		err := rows.Scan(&category, &count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan category stats: %w", err)
		}
		groupsByCategory[category] = count
	}

	// Get groups by platform
	groupsByPlatform := make(map[string]int64)
	rows, err = s.db.Query(ctx, `
		SELECT platform, COUNT(*) 
		FROM support_groups 
		WHERE is_active = true 
		GROUP BY platform
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to get groups by platform: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var platform string
		var count int64
		err := rows.Scan(&platform, &count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan platform stats: %w", err)
		}
		groupsByPlatform[platform] = count
	}

	// Get popular groups (most members)
	popularGroupsQuery := `
		SELECT sg.id, sg.name, sg.description, sg.category, sg.platform, sg.doctor_info, 
			   sg.url, sg.guidelines, sg.meeting_time, sg.max_members, sg.is_active, 
			   sg.created_at, sg.updated_at
		FROM support_groups sg
		LEFT JOIN group_memberships gm ON sg.id = gm.group_id AND gm.is_active = true
		WHERE sg.is_active = true
		GROUP BY sg.id, sg.name, sg.description, sg.category, sg.platform, sg.doctor_info, 
				 sg.url, sg.guidelines, sg.meeting_time, sg.max_members, sg.is_active, 
				 sg.created_at, sg.updated_at
		ORDER BY COUNT(gm.id) DESC
		LIMIT 5
	`

	rows, err = s.db.Query(ctx, popularGroupsQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to get popular groups: %w", err)
	}
	defer rows.Close()

	var popularGroups []SupportGroup
	for rows.Next() {
		var group SupportGroup

		err := rows.Scan(
			&group.ID,
			&group.Name,
			&group.Description,
			&group.Category,
			&group.Platform,
			&group.DoctorInfo,
			&group.URL,
			&group.Guidelines,
			&group.MeetingTime,
			&group.MaxMembers,
			&group.IsActive,
			&group.CreatedAt,
			&group.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan popular group: %w", err)
		}

		popularGroups = append(popularGroups, group)
	}

	return &SupportGroupStats{
		TotalGroups:      totalGroups,
		ActiveGroups:     activeGroups,
		TotalMembers:     totalMembers,
		GroupsByCategory: groupsByCategory,
		GroupsByPlatform: groupsByPlatform,
		PopularGroups:    popularGroups,
	}, nil
}

// CreateSupportGroup creates a new support group (admin only)
func (s *store) CreateSupportGroup(ctx context.Context, req *CreateSupportGroupRequest) (*SupportGroup, error) {
	now := time.Now()

	query := `
		INSERT INTO support_groups (name, description, category, platform, doctor_info, url, 
									guidelines, meeting_time, max_members, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		RETURNING id, name, description, category, platform, doctor_info, url, guidelines,
				  meeting_time, max_members, is_active, created_at, updated_at
	`

	var group SupportGroup

	err := s.db.QueryRow(ctx, query,
		req.Name,
		req.Description,
		req.Category,
		req.Platform,
		req.DoctorInfo,
		req.URL,
		req.Guidelines,
		req.MeetingTime,
		req.MaxMembers,
		true, // is_active
		now,  // created_at
		now,  // updated_at
	).Scan(
		&group.ID,
		&group.Name,
		&group.Description,
		&group.Category,
		&group.Platform,
		&group.DoctorInfo,
		&group.URL,
		&group.Guidelines,
		&group.MeetingTime,
		&group.MaxMembers,
		&group.IsActive,
		&group.CreatedAt,
		&group.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create support group: %w", err)
	}

	return &group, nil
}

// UpdateSupportGroup updates a support group (admin only)
func (s *store) UpdateSupportGroup(ctx context.Context, groupID int, req *UpdateSupportGroupRequest) (*SupportGroup, error) {
	var setParts []string
	var args []interface{}
	argIndex := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argIndex))
		args = append(args, *req.Name)
		argIndex++
	}

	if req.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *req.Description)
		argIndex++
	}

	if req.Category != nil {
		setParts = append(setParts, fmt.Sprintf("category = $%d", argIndex))
		args = append(args, *req.Category)
		argIndex++
	}

	if req.Platform != nil {
		setParts = append(setParts, fmt.Sprintf("platform = $%d", argIndex))
		args = append(args, *req.Platform)
		argIndex++
	}

	if req.DoctorInfo != nil {
		setParts = append(setParts, fmt.Sprintf("doctor_info = $%d", argIndex))
		args = append(args, *req.DoctorInfo)
		argIndex++
	}

	if req.URL != nil {
		setParts = append(setParts, fmt.Sprintf("url = $%d", argIndex))
		args = append(args, *req.URL)
		argIndex++
	}

	if req.Guidelines != nil {
		setParts = append(setParts, fmt.Sprintf("guidelines = $%d", argIndex))
		args = append(args, *req.Guidelines)
		argIndex++
	}

	if req.MeetingTime != nil {
		setParts = append(setParts, fmt.Sprintf("meeting_time = $%d", argIndex))
		args = append(args, *req.MeetingTime)
		argIndex++
	}

	if req.MaxMembers != nil {
		setParts = append(setParts, fmt.Sprintf("max_members = $%d", argIndex))
		args = append(args, *req.MaxMembers)
		argIndex++
	}

	// If no fields to update, just return the existing group
	if len(setParts) == 0 {
		return s.GetSupportGroupByID(ctx, groupID)
	}

	// Always update the updated_at timestamp
	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	query := fmt.Sprintf(`
		UPDATE support_groups 
		SET %s
		WHERE id = $%d AND is_active = true
		RETURNING id, name, description, category, platform, doctor_info, url, guidelines,
				  meeting_time, max_members, is_active, created_at, updated_at
	`, strings.Join(setParts, ", "), argIndex)

	args = append(args, groupID)

	var group SupportGroup

	err := s.db.QueryRow(ctx, query, args...).Scan(
		&group.ID,
		&group.Name,
		&group.Description,
		&group.Category,
		&group.Platform,
		&group.DoctorInfo,
		&group.URL,
		&group.Guidelines,
		&group.MeetingTime,
		&group.MaxMembers,
		&group.IsActive,
		&group.CreatedAt,
		&group.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("support group not found")
		}
		return nil, fmt.Errorf("failed to update support group: %w", err)
	}

	return &group, nil
}

// DeleteSupportGroup soft deletes a support group (admin only)
func (s *store) DeleteSupportGroup(ctx context.Context, groupID int) error {
	query := `
		UPDATE support_groups 
		SET is_active = false, updated_at = $1
		WHERE id = $2
	`

	result, err := s.db.Exec(ctx, query, time.Now(), groupID)
	if err != nil {
		return fmt.Errorf("failed to delete support group: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("support group not found")
	}

	return nil
}
