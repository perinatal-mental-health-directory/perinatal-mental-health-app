// backend/internal/support_groups/interface.go
package support_groups

import (
	"context"
	"github.com/labstack/echo/v4"
)

// Service defines the interface for support groups business logic
// Change all int groupID parameters to string
type Service interface {
	ListSupportGroups(ctx context.Context, page, pageSize int, category, platform string) (*ListSupportGroupsResponse, error)
	GetSupportGroup(ctx context.Context, groupID string) (*SupportGroup, error) // Changed
	SearchSupportGroups(ctx context.Context, query string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetSupportGroupsByCategory(ctx context.Context, category string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetSupportGroupsByPlatform(ctx context.Context, platform string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetUserGroups(ctx context.Context, userID string) ([]SupportGroup, error)
	JoinGroup(ctx context.Context, userID string, groupID string) error             // Changed
	LeaveGroup(ctx context.Context, userID string, groupID string) error            // Changed
	GetGroupMembers(ctx context.Context, groupID string) ([]GroupMembership, error) // Changed
	IsUserMember(ctx context.Context, userID string, groupID string) (bool, error)  // Changed
	GetSupportGroupStats(ctx context.Context) (*SupportGroupStats, error)

	// Admin/Staff only methods
	CreateSupportGroup(ctx context.Context, req *CreateSupportGroupRequest) (*SupportGroup, error)
	UpdateSupportGroup(ctx context.Context, groupID string, req *UpdateSupportGroupRequest) (*SupportGroup, error) // Changed
	DeleteSupportGroup(ctx context.Context, groupID string) error                                                  // Changed
	RemoveUserFromGroup(ctx context.Context, userID string, groupID string) error                                  // Changed
}

// Store defines the interface for support groups data persistence
type Store interface {
	ListSupportGroups(ctx context.Context, page, pageSize int, category, platform string) (*ListSupportGroupsResponse, error)
	GetSupportGroupByID(ctx context.Context, groupID string) (*SupportGroup, error) // Changed
	SearchSupportGroups(ctx context.Context, query string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetSupportGroupsByCategory(ctx context.Context, category string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetSupportGroupsByPlatform(ctx context.Context, platform string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetUserGroups(ctx context.Context, userID string) ([]SupportGroup, error)
	GetGroupMembers(ctx context.Context, groupID string) ([]GroupMembership, error) // Changed
	IsUserMember(ctx context.Context, userID string, groupID string) (bool, error)  // Changed
	JoinGroup(ctx context.Context, userID string, groupID string) error             // Changed
	LeaveGroup(ctx context.Context, userID string, groupID string) error            // Changed
	RemoveUserFromGroup(ctx context.Context, userID string, groupID string) error   // Changed
	GetSupportGroupStats(ctx context.Context) (*SupportGroupStats, error)

	// Admin/Staff only methods
	CreateSupportGroup(ctx context.Context, req *CreateSupportGroupRequest) (*SupportGroup, error)
	UpdateSupportGroup(ctx context.Context, groupID string, req *UpdateSupportGroupRequest) (*SupportGroup, error) // Changed
	DeleteSupportGroup(ctx context.Context, groupID string) error                                                  // Changed
}

// Handler defines the interface for support groups HTTP handlers
type Handler interface {
	ListSupportGroups(c echo.Context) error
	GetSupportGroup(c echo.Context) error
	SearchSupportGroups(c echo.Context) error
	GetSupportGroupsByCategory(c echo.Context) error
	GetSupportGroupsByPlatform(c echo.Context) error
	GetUserGroups(c echo.Context) error
	JoinGroup(c echo.Context) error
	LeaveGroup(c echo.Context) error
	GetGroupMembers(c echo.Context) error
	GetSupportGroupStats(c echo.Context) error

	// Admin/Staff only methods
	CreateSupportGroup(c echo.Context) error
	UpdateSupportGroup(c echo.Context) error
	DeleteSupportGroup(c echo.Context) error
	RemoveUserFromGroup(c echo.Context) error
}
