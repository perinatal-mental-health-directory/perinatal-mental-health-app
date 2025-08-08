package user

import (
	"context"
	"fmt"
)

type service struct {
	store Store
}

func NewService(store Store) Service {
	return &service{
		store: store,
	}
}

// CreateUser creates a new user
func (s *service) CreateUser(ctx context.Context, req *CreateUserRequest) (*UserResponse, error) {
	// Check if user with email already exists
	existingUser, _ := s.store.GetUserByEmail(ctx, req.Email)
	if existingUser != nil {
		return nil, fmt.Errorf("user with email %s already exists", req.Email)
	}

	// Validate role
	if !isValidRole(req.Role) {
		return nil, fmt.Errorf("invalid role: %s", req.Role)
	}

	user, err := s.store.CreateUser(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &UserResponse{
		ID:          user.ID,
		Email:       user.Email,
		FullName:    user.FullName,
		Role:        user.Role,
		IsActive:    user.IsActive,
		LastLoginAt: user.LastLoginAt,
		CreatedAt:   user.CreatedAt,
	}, nil
}

// GetUser retrieves a user by ID
func (s *service) GetUser(ctx context.Context, userID string) (*UserResponse, error) {
	user, err := s.store.GetUserByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	return &UserResponse{
		ID:          user.ID,
		Email:       user.Email,
		FullName:    user.FullName,
		Role:        user.Role,
		IsActive:    user.IsActive,
		LastLoginAt: user.LastLoginAt,
		CreatedAt:   user.CreatedAt,
	}, nil
}

// GetUserProfile retrieves a user's complete profile
func (s *service) GetUserProfile(ctx context.Context, userID string) (*UserProfileResponse, error) {
	user, err := s.store.GetUserByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	profile, err := s.store.GetUserProfile(ctx, userID)
	if err != nil {
		return nil, err
	}

	var preferences interface{}
	if profile.Preferences != nil {
		preferences = *profile.Preferences
	}

	return &UserProfileResponse{
		User: UserResponse{
			ID:          user.ID,
			Email:       user.Email,
			FullName:    user.FullName,
			Role:        user.Role,
			IsActive:    user.IsActive,
			LastLoginAt: user.LastLoginAt,
			CreatedAt:   user.CreatedAt,
		},
		PhoneNumber:      profile.PhoneNumber,
		DateOfBirth:      profile.DateOfBirth,
		Address:          profile.Address,
		EmergencyContact: profile.EmergencyContact,
		Preferences:      preferences,
	}, nil
}

// UpdateUser updates user information
func (s *service) UpdateUser(ctx context.Context, userID string, req *UpdateUserRequest) (*UserResponse, error) {
	user, err := s.store.UpdateUser(ctx, userID, req)
	if err != nil {
		return nil, err
	}

	// Also update profile if there are profile-specific fields
	if req.PhoneNumber != nil || req.Address != nil {
		_, err = s.store.UpdateUserProfile(ctx, userID, req)
		if err != nil {
			return nil, fmt.Errorf("failed to update user profile: %w", err)
		}
	}

	return &UserResponse{
		ID:          user.ID,
		Email:       user.Email,
		FullName:    user.FullName,
		Role:        user.Role,
		IsActive:    user.IsActive,
		LastLoginAt: user.LastLoginAt,
		CreatedAt:   user.CreatedAt,
	}, nil
}

// ListUsers retrieves a paginated list of users
func (s *service) ListUsers(ctx context.Context, page, pageSize int, role *UserRole) (*ListUsersResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	if role != nil && !isValidRole(*role) {
		return nil, fmt.Errorf("invalid role filter: %s", *role)
	}

	return s.store.ListUsers(ctx, page, pageSize, role)
}

// GetUserByEmail retrieves a user by email
func (s *service) GetUserByEmail(ctx context.Context, email string) (*UserResponse, error) {
	user, err := s.store.GetUserByEmail(ctx, email)
	if err != nil {
		return nil, err
	}

	return &UserResponse{
		ID:          user.ID,
		Email:       user.Email,
		FullName:    user.FullName,
		Role:        user.Role,
		IsActive:    user.IsActive,
		LastLoginAt: user.LastLoginAt,
		CreatedAt:   user.CreatedAt,
	}, nil
}

// UpdateLastLogin updates the user's last login time
func (s *service) UpdateLastLogin(ctx context.Context, userID string) error {
	return s.store.UpdateLastLogin(ctx, userID)
}

// DeactivateUser deactivates a user account
func (s *service) DeactivateUser(ctx context.Context, userID string) error {
	return s.store.DeactivateUser(ctx, userID)
}

// Helper function to validate user roles
func isValidRole(role UserRole) bool {
	switch role {
	case RoleServiceUser, RoleNHSStaff, RoleCharity, RoleProfessional:
		return true
	default:
		return false
	}
}
