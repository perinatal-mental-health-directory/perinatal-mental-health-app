// backend/internal/privacy/model.go
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

// DataRequest represents a GDPR data request
type DataRequest struct {
	ID          string     `json:"id" db:"id"`
	UserID      string     `json:"user_id" db:"user_id"`
	RequestType string     `json:"request_type" db:"request_type"`
	Status      string     `json:"status" db:"status"`
	Reason      *string    `json:"reason,omitempty" db:"reason"`
	RequestedAt time.Time  `json:"requested_at" db:"requested_at"`
	ProcessedAt *time.Time `json:"processed_at,omitempty" db:"processed_at"`
	ProcessedBy *string    `json:"processed_by,omitempty" db:"processed_by"`
	Notes       *string    `json:"notes,omitempty" db:"notes"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
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

// RequestType constants
const (
	RequestTypeDataDownload    = "data_download"
	RequestTypeAccountDeletion = "account_deletion"
)

// RequestStatus constants
const (
	StatusPending    = "pending"
	StatusProcessing = "processing"
	StatusCompleted  = "completed"
	StatusRejected   = "rejected"
)
