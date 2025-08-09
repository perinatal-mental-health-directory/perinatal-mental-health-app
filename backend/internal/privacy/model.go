package privacy

import (
	"time"
)

// PrivacyPreferences represents user privacy preferences
type PrivacyPreferences struct {
	UserID                 string    `json:"user_id" db:"user_id"`
	DataTrackingEnabled    bool      `json:"data_tracking_enabled" db:"data_tracking_enabled"`
	DataSharingEnabled     bool      `json:"data_sharing_enabled" db:"data_sharing_enabled"`
	CookiesEnabled         bool      `json:"cookies_enabled" db:"cookies_enabled"`
	MarketingEmailsEnabled bool      `json:"marketing_emails_enabled" db:"marketing_emails_enabled"`
	AnalyticsEnabled       bool      `json:"analytics_enabled" db:"analytics_enabled"`
	CreatedAt              time.Time `json:"created_at" db:"created_at"`
	UpdatedAt              time.Time `json:"updated_at" db:"updated_at"`
}

// UpdatePrivacyPreferencesRequest represents the request to update privacy preferences
type UpdatePrivacyPreferencesRequest struct {
	DataTrackingEnabled    *bool `json:"data_tracking_enabled,omitempty"`
	DataSharingEnabled     *bool `json:"data_sharing_enabled,omitempty"`
	CookiesEnabled         *bool `json:"cookies_enabled,omitempty"`
	MarketingEmailsEnabled *bool `json:"marketing_emails_enabled,omitempty"`
	AnalyticsEnabled       *bool `json:"analytics_enabled,omitempty"`
}

// DataRetentionInfo represents data retention information
type DataRetentionInfo struct {
	RetentionPolicy string `json:"retention_policy"`
	GDPRRights      string `json:"gdpr_rights"`
	LastUpdated     string `json:"last_updated"`
}

// AccountDeletionRequest represents an account deletion request
type AccountDeletionRequest struct {
	Reason string `json:"reason,omitempty"`
}

// DataExportResponse represents exported user data
type DataExportResponse struct {
	UserData    interface{} `json:"user_data"`
	ProfileData interface{} `json:"profile_data"`
	Preferences interface{} `json:"preferences"`
	ExportDate  time.Time   `json:"export_date"`
}
