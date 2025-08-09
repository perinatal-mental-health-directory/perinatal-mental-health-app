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

func NewStore(db *pgxpool.Pool) *store {
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

	var user map[string]interface{}
	var lastLoginAt *time.Time

	err := s.db.QueryRow(ctx, query, userID).Scan(
		&user["id"],
		&user["email"],
		&user["full_name"],
		&user["role"],
		&user["is_active"],
		&lastLoginAt,
		&user["created_at"],
		&user["updated_at"],
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get user data: %w", err)
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

	profile := make(map[string]interface{})
	var phoneNumber, address, emergencyContact, preferences *string
	var dateOfBirth *time.Time

	err := s.db.QueryRow(ctx, query, userID).Scan(
		&profile["user_id"],
		&phoneNumber,
		&dateOfBirth,
		&address,
		&emergencyContact,
		&preferences,
		&profile["created_at"],
		&profile["updated_at"],
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return map[string]interface{}{"user_id": userID}, nil
		}
		return nil, fmt.Errorf("failed to get user profile data: %w", err)
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
