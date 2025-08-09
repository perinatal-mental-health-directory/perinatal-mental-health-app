package privacy

import (
	"context"
	"fmt"
	"time"
)

type service struct {
	store *store
}

func NewService(store *store) *service {
	return &service{
		store: store,
	}
}

// GetPrivacyPreferences retrieves user's privacy preferences
func (s *service) GetPrivacyPreferences(ctx context.Context, userID string) (*PrivacyPreferences, error) {
	preferences, err := s.store.GetPrivacyPreferences(ctx, userID)
	if err != nil {
		// If preferences don't exist, create default ones
		defaultPreferences := &PrivacyPreferences{
			UserID:                 userID,
			DataTrackingEnabled:    true,
			DataSharingEnabled:     false,
			CookiesEnabled:         true,
			MarketingEmailsEnabled: false,
			AnalyticsEnabled:       true,
			CreatedAt:              time.Now(),
			UpdatedAt:              time.Now(),
		}

		err = s.store.CreatePrivacyPreferences(ctx, defaultPreferences)
		if err != nil {
			return nil, fmt.Errorf("failed to create default privacy preferences: %w", err)
		}

		return defaultPreferences, nil
	}

	return preferences, nil
}

// UpdatePrivacyPreferences updates user's privacy preferences
func (s *service) UpdatePrivacyPreferences(ctx context.Context, userID string, req *UpdatePrivacyPreferencesRequest) error {
	return s.store.UpdatePrivacyPreferences(ctx, userID, req)
}

// RequestDataDownload handles data download requests
func (s *service) RequestDataDownload(ctx context.Context, userID string) error {
	// TODO: Implement actual data download logic (email to user, etc.)
	fmt.Printf("Data download requested for user: %s\n", userID)
	return nil
}

// RequestAccountDeletion handles account deletion requests
func (s *service) RequestAccountDeletion(ctx context.Context, userID, reason string) error {
	// TODO: Implement actual account deletion request logic
	fmt.Printf("Account deletion requested for user: %s, reason: %s\n", userID, reason)
	return nil
}

// GetDataRetentionInfo returns data retention information
func (s *service) GetDataRetentionInfo() *DataRetentionInfo {
	return &DataRetentionInfo{
		RetentionPolicy: "Personal data is retained for as long as necessary to provide our services or as required by law. Healthcare data may be retained for up to 7 years in accordance with NHS guidelines.",
		GDPRRights:      "Under GDPR, you have the right to access, rectify, erase, restrict processing, data portability, and object to processing of your personal data.",
		LastUpdated:     "2024-01-01",
	}
}

// ExportUserData exports user's data
func (s *service) ExportUserData(ctx context.Context, userID string) (*DataExportResponse, error) {
	userData, err := s.store.GetUserData(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user data: %w", err)
	}

	profileData, err := s.store.GetUserProfileData(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get profile data: %w", err)
	}

	preferences, err := s.store.GetPrivacyPreferences(ctx, userID)
	if err != nil {
		preferences = nil // It's okay if preferences don't exist
	}

	return &DataExportResponse{
		UserData:    userData,
		ProfileData: profileData,
		Preferences: preferences,
		ExportDate:  time.Now(),
	}, nil
}
