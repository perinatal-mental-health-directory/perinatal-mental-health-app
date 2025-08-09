package auth

import (
	"time"
)

// LoginRequest represents the login request payload
type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

// RegisterRequest represents the registration request payload
type RegisterRequest struct {
	Email       string  `json:"email" validate:"required,email"`
	Password    string  `json:"password" validate:"required,min=8"`
	FullName    string  `json:"full_name" validate:"required,min=2,max=100"`
	Role        string  `json:"role" validate:"required"`
	PhoneNumber *string `json:"phone_number,omitempty"`
	Address     *string `json:"address,omitempty"`
	DateOfBirth *string `json:"date_of_birth,omitempty"` // Expected format: YYYY-MM-DD
}

// AuthResponse represents the authentication response
type AuthResponse struct {
	Token        string    `json:"token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	User         UserInfo  `json:"user"`
}

// UserInfo represents basic user information in auth responses
type UserInfo struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	FullName string `json:"full_name"`
	Role     string `json:"role"`
}

// RefreshTokenRequest represents the refresh token request
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// ForgotPasswordRequest represents the forgot password request
type ForgotPasswordRequest struct {
	Email string `json:"email" validate:"required,email"`
}

// ResetPasswordRequest represents the reset password request
type ResetPasswordRequest struct {
	Token       string `json:"token" validate:"required"`
	NewPassword string `json:"new_password" validate:"required,min=8"`
}

// User represents a user in the auth system
type User struct {
	ID           string     `json:"id" db:"id"`
	Email        string     `json:"email" db:"email"`
	FullName     string     `json:"full_name" db:"full_name"`
	Role         UserRole   `json:"role" db:"role"`
	PasswordHash string     `json:"-" db:"password_hash"`
	IsActive     bool       `json:"is_active" db:"is_active"`
	LastLoginAt  *time.Time `json:"last_login_at,omitempty" db:"last_login_at"`
	CreatedAt    time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at" db:"updated_at"`
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required"`
	NewPassword     string `json:"new_password" validate:"required,min=8"`
}

// UserRole represents user roles
type UserRole string

const (
	RoleServiceUser  UserRole = "service_user"
	RoleNHSStaff     UserRole = "nhs_staff"
	RoleCharity      UserRole = "charity"
	RoleProfessional UserRole = "professional"
)
