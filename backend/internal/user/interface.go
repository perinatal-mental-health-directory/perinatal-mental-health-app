package user

import (
	"context"
	"github.com/labstack/echo/v4"
)

// Service defines the interface for user business logic
type Service interface {
	CreateUser(ctx context.Context, req *CreateUserRequest) (*UserResponse, error)
	GetUser(ctx context.Context, userID string) (*UserResponse, error)
	GetUserProfile(ctx context.Context, userID string) (*UserProfileResponse, error)
	UpdateUser(ctx context.Context, userID string, req *UpdateUserRequest) (*UserResponse, error)
	ListUsers(ctx context.Context, page, pageSize int, role *UserRole) (*ListUsersResponse, error)
	SearchUsers(ctx context.Context, query string, limit int, role *UserRole) ([]UserResponse, error)
	GetUserByEmail(ctx context.Context, email string) (*UserResponse, error)
	UpdateLastLogin(ctx context.Context, userID string) error
	DeactivateUser(ctx context.Context, userID string) error
	GetUserPreferences(ctx context.Context, userID string) (map[string]interface{}, error)
	UpdateUserPreferences(ctx context.Context, userID string, preferences map[string]interface{}) error
}

// Store defines the interface for user data persistence
type Store interface {
	CreateUser(ctx context.Context, req *CreateUserRequest) (*User, error)
	GetUserByID(ctx context.Context, userID string) (*User, error)
	GetUserByEmail(ctx context.Context, email string) (*User, error)
	GetUserProfile(ctx context.Context, userID string) (*UserProfile, error)
	UpdateUser(ctx context.Context, userID string, req *UpdateUserRequest) (*User, error)
	UpdateUserProfile(ctx context.Context, userID string, req *UpdateUserRequest) (*UserProfile, error)
	ListUsers(ctx context.Context, page, pageSize int, role *UserRole) (*ListUsersResponse, error)
	SearchUsers(ctx context.Context, query string, limit int, role *UserRole) ([]User, error)
	UpdateLastLogin(ctx context.Context, userID string) error
	DeactivateUser(ctx context.Context, userID string) error
	GetUserPreferences(ctx context.Context, userID string) (map[string]interface{}, error)
	UpdateUserPreferences(ctx context.Context, userID string, preferences map[string]interface{}) error
}

// Handler defines the interface for user HTTP handlers
type Handler interface {
	CreateUser(c echo.Context) error
	GetUser(c echo.Context) error
	GetUserProfile(c echo.Context) error
	GetCurrentUserProfile(c echo.Context) error
	UpdateUser(c echo.Context) error
	UpdateCurrentUser(c echo.Context) error
	ListUsers(c echo.Context) error
	SearchUsers(c echo.Context) error
	DeactivateUser(c echo.Context) error
	UpdateLastLogin(c echo.Context) error
	GetUserPreferences(c echo.Context) error
	UpdateUserPreferences(c echo.Context) error
}
