package user

import (
	"time"
)

// UserRole represents the different roles in the system
type UserRole string

const (
	RoleServiceUser  UserRole = "service_user"
	RoleNHSStaff     UserRole = "nhs_staff"
	RoleCharity      UserRole = "charity"
	RoleProfessional UserRole = "professional"
)

// User represents a user in the system
type User struct {
	ID          string     `json:"id" db:"id"`
	Email       string     `json:"email" db:"email"`
	FullName    string     `json:"full_name" db:"full_name"`
	Role        UserRole   `json:"role" db:"role"`
	IsActive    bool       `json:"is_active" db:"is_active"`
	LastLoginAt *time.Time `json:"last_login_at,omitempty" db:"last_login_at"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
}

// UserProfile represents extended user profile information
type UserProfile struct {
	UserID           string     `json:"user_id" db:"user_id"`
	PhoneNumber      *string    `json:"phone_number,omitempty" db:"phone_number"`
	DateOfBirth      *time.Time `json:"date_of_birth,omitempty" db:"date_of_birth"`
	Address          *string    `json:"address,omitempty" db:"address"`
	EmergencyContact *string    `json:"emergency_contact,omitempty" db:"emergency_contact"`
	Preferences      *string    `json:"preferences,omitempty" db:"preferences"` // JSON string
	CreatedAt        time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at" db:"updated_at"`
}

// CreateUserRequest represents the request to create a new user
type CreateUserRequest struct {
	Email    string   `json:"email" validate:"required,email"`
	FullName string   `json:"full_name" validate:"required,min=2,max=100"`
	Role     UserRole `json:"role" validate:"required"`
}

// UpdateUserRequest represents the request to update user information
type UpdateUserRequest struct {
	FullName    *string `json:"full_name,omitempty" validate:"omitempty,min=2,max=100"`
	PhoneNumber *string `json:"phone_number,omitempty"`
	Address     *string `json:"address,omitempty"`
}

// ChangePasswordRequest represents the request to change password
type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required"`
	NewPassword     string `json:"new_password" validate:"required,min=8"`
}

// UserResponse represents the user data returned in API responses
type UserResponse struct {
	ID          string     `json:"id"`
	Email       string     `json:"email"`
	FullName    string     `json:"full_name"`
	Role        UserRole   `json:"role"`
	IsActive    bool       `json:"is_active"`
	LastLoginAt *time.Time `json:"last_login_at,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
}

// UserProfileResponse represents the user profile data returned in API responses
type UserProfileResponse struct {
	User             UserResponse `json:"user"`
	PhoneNumber      *string      `json:"phone_number,omitempty"`
	DateOfBirth      *time.Time   `json:"date_of_birth,omitempty"`
	Address          *string      `json:"address,omitempty"`
	EmergencyContact *string      `json:"emergency_contact,omitempty"`
	Preferences      interface{}  `json:"preferences,omitempty"`
}

// ListUsersResponse represents the response for listing users
type ListUsersResponse struct {
	Users      []UserResponse `json:"users"`
	Total      int64          `json:"total"`
	Page       int            `json:"page"`
	PageSize   int            `json:"page_size"`
	TotalPages int            `json:"total_pages"`
}
