// backend/internal/privacy/service.go
package privacy

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

type service struct {
	store Store
}

func NewService(store Store) Service {
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
	// Check if preferences exist, if not create them first
	_, err := s.store.GetPrivacyPreferences(ctx, userID)
	if err != nil {
		// Create default preferences first
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
			return fmt.Errorf("failed to create default privacy preferences: %w", err)
		}
	}

	return s.store.UpdatePrivacyPreferences(ctx, userID, req)
}

// RequestDataDownload handles data download requests
func (s *service) RequestDataDownload(ctx context.Context, userID string) error {
	// TODO: Implement actual data download logic
	// This should:
	// 1. Create a data request record
	// 2. Queue a background job to compile user data
	// 3. Send email with download link when ready
	// 4. Schedule automatic deletion of the download after 30 days

	request := &DataRequest{
		ID:          uuid.New().String(),
		UserID:      userID,
		RequestType: RequestTypeDataDownload,
		Status:      StatusPending,
		RequestedAt: time.Now(),
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	err := s.store.CreateDataRequest(ctx, request)
	if err != nil {
		return fmt.Errorf("failed to create data download request: %w", err)
	}

	// TODO: Queue background job to process the request
	// TODO: Send confirmation email to user
	fmt.Printf("Data download requested for user: %s (Request ID: %s)\n", userID, request.ID)

	return nil
}

// RequestAccountDeletion handles account deletion requests
func (s *service) RequestAccountDeletion(ctx context.Context, userID, reason string) error {
	request := &DataRequest{
		ID:          uuid.New().String(),
		UserID:      userID,
		RequestType: RequestTypeAccountDeletion,
		Status:      StatusPending,
		Reason:      &reason,
		RequestedAt: time.Now(),
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	err := s.store.CreateDataRequest(ctx, request)
	if err != nil {
		return fmt.Errorf("failed to create account deletion request: %w", err)
	}

	// TODO: Send notification to admin team
	// TODO: Send confirmation email to user
	fmt.Printf("Account deletion requested for user: %s, reason: %s (Request ID: %s)\n", userID, reason, request.ID)

	return nil
}

// GetDataRetentionInfo returns data retention information
func (s *service) GetDataRetentionInfo() *DataRetentionInfo {
	return &DataRetentionInfo{
		RetentionPolicy: "Personal data is retained for as long as necessary to provide our services or as required by law. Healthcare data may be retained for up to 7 years in accordance with NHS guidelines. User account data is deleted within 30 days of account deletion request approval.",
		GDPRRights:      "Under GDPR, you have the right to access, rectify, erase, restrict processing, data portability, and object to processing of your personal data. You can exercise these rights by contacting our support team or using the privacy controls in your account settings.",
		LastUpdated:     "2024-01-15",
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

	// TODO: Add feedback data, referral data, and other user-related data
	// feedbackData, err := s.feedbackStore.GetUserFeedback(ctx, userID)
	// referralData, err := s.referralStore.GetUserReferrals(ctx, userID)

	return &DataExportResponse{
		UserData:    userData,
		ProfileData: profileData,
		Preferences: preferences,
		ExportDate:  time.Now(),
	}, nil
}

// GetDataRequests retrieves user's data requests
func (s *service) GetDataRequests(ctx context.Context, userID string) ([]DataRequest, error) {
	return s.store.GetDataRequestsByUser(ctx, userID)
}
