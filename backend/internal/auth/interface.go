package auth

import (
	"context"
	"github.com/labstack/echo/v4"
	"time"
)

// Service defines the interface for user business logic
type Service interface {
	Login(ctx context.Context, req *LoginRequest) (*AuthResponse, error)
	Register(ctx context.Context, req *RegisterRequest) (*AuthResponse, error)
	RefreshToken(ctx context.Context, req *RefreshTokenRequest) (*AuthResponse, error)
	ForgotPassword(ctx context.Context, req *ForgotPasswordRequest) error
	ResetPassword(ctx context.Context, req *ResetPasswordRequest) error
	ChangePassword(ctx context.Context, userID string, req *ChangePasswordRequest) error
}

// Store defines the interface for user data persistence
type Store interface {
	GetUserByEmail(ctx context.Context, email string) (*User, error)
	GetUserByID(ctx context.Context, userID string) (*User, error)
	CreateUser(ctx context.Context, user *User) error
	UpdateLastLogin(ctx context.Context, userID string) error
	UpdatePassword(ctx context.Context, userID, passwordHash string) error
	GetUserPasswordHash(ctx context.Context, userID string) (string, error)
	UpdateUserPassword(ctx context.Context, userID, passwordHash string) error
	CreateUserWithProfile(ctx context.Context, user *User, phoneNumber, address *string, dateOfBirth *time.Time) error
}

// Handler defines the interface for user HTTP handlers
type Handler interface {
	Login(c echo.Context) error
	Register(c echo.Context) error
	RefreshToken(c echo.Context) error
	ForgotPassword(c echo.Context) error
	ResetPassword(c echo.Context) error
	ChangePassword(c echo.Context) error
}
