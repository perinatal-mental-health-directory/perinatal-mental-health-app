// Create: backend/internal/privacy/interface.go
package privacy

import (
	"context"

	"github.com/labstack/echo/v4"
)

// service defines the interface for privacy business logic
type Service interface {
	GetPrivacyPreferences(ctx context.Context, userID string) (*PrivacyPreferences, error)
	UpdatePrivacyPreferences(ctx context.Context, userID string, req *UpdatePrivacyPreferencesRequest) error
	RequestDataDownload(ctx context.Context, userID string) error
	RequestAccountDeletion(ctx context.Context, userID, reason string) error
	GetDataRetentionInfo() *DataRetentionInfo
	ExportUserData(ctx context.Context, userID string) (*DataExportResponse, error)
}

// store defines the interface for privacy data persistence
type Store interface {
	GetPrivacyPreferences(ctx context.Context, userID string) (*PrivacyPreferences, error)
	CreatePrivacyPreferences(ctx context.Context, preferences *PrivacyPreferences) error
	UpdatePrivacyPreferences(ctx context.Context, userID string, req *UpdatePrivacyPreferencesRequest) error
	GetUserData(ctx context.Context, userID string) (map[string]interface{}, error)
	GetUserProfileData(ctx context.Context, userID string) (map[string]interface{}, error)
}

// handler defines the interface for privacy HTTP handlers
type Handler interface {
	GetPrivacyPreferences(c echo.Context) error
	UpdatePrivacyPreferences(c echo.Context) error
	RequestDataDownload(c echo.Context) error
	RequestAccountDeletion(c echo.Context) error
	GetDataRetentionInfo(c echo.Context) error
	ExportUserData(c echo.Context) error
}
