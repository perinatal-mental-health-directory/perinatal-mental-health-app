// backend/internal/support_groups/interface.go
package support_groups

import (
	"context"
	"github.com/labstack/echo/v4"
)

// Service defines the interface for support groups business logic
type Service interface {
	ListSupportGroups(ctx context.Context, page, pageSize int, category, platform string) (*ListSupportGroupsResponse, error)
	GetSupportGroup(ctx context.Context, groupID int) (*SupportGroup, error)
	SearchSupportGroups(ctx context.Context, query string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetSupportGroupsByCategory(ctx context.Context, category string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetSupportGroupsByPlatform(ctx context.Context, platform string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetUserGroups(ctx context.Context, userID string) ([]SupportGroup, error)
	JoinGroup(ctx context.Context, userID string, groupID int) error
	LeaveGroup(ctx context.Context, userID string, groupID int) error
	GetGroupMembers(ctx context.Context, groupID int) ([]GroupMembership, error)
	IsUserMember(ctx context.Context, userID string, groupID int) (bool, error)
	GetSupportGroupStats(ctx context.Context) (*SupportGroupStats, error)

	// Admin/Staff only methods
	CreateSupportGroup(ctx context.Context, req *CreateSupportGroupRequest) (*SupportGroup, error)
	UpdateSupportGroup(ctx context.Context, groupID int, req *UpdateSupportGroupRequest) (*SupportGroup, error)
	DeleteSupportGroup(ctx context.Context, groupID int) error
	RemoveUserFromGroup(ctx context.Context, userID string, groupID int) error
}

// Store defines the interface for support groups data persistence
type Store interface {
	ListSupportGroups(ctx context.Context, page, pageSize int, category, platform string) (*ListSupportGroupsResponse, error)
	GetSupportGroupByID(ctx context.Context, groupID int) (*SupportGroup, error)
	SearchSupportGroups(ctx context.Context, query string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetSupportGroupsByCategory(ctx context.Context, category string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetSupportGroupsByPlatform(ctx context.Context, platform string, page, pageSize int) (*ListSupportGroupsResponse, error)
	GetUserGroups(ctx context.Context, userID string) ([]SupportGroup, error)
	GetGroupMembers(ctx context.Context, groupID int) ([]GroupMembership, error)
	IsUserMember(ctx context.Context, userID string, groupID int) (bool, error)
	JoinGroup(ctx context.Context, userID string, groupID int) error
	LeaveGroup(ctx context.Context, userID string, groupID int) error
	RemoveUserFromGroup(ctx context.Context, userID string, groupID int) error
	GetSupportGroupStats(ctx context.Context) (*SupportGroupStats, error)

	// Admin/Staff only methods
	CreateSupportGroup(ctx context.Context, req *CreateSupportGroupRequest) (*SupportGroup, error)
	UpdateSupportGroup(ctx context.Context, groupID int, req *UpdateSupportGroupRequest) (*SupportGroup, error)
	DeleteSupportGroup(ctx context.Context, groupID int) error
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
