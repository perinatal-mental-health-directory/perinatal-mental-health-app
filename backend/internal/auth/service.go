package auth

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type service struct {
	store      Store
	jwtService JWTService
}

func NewService(store Store, jwtService JWTService) Service {
	return &service{
		store:      store,
		jwtService: jwtService,
	}
}

// Login authenticates a user and returns a JWT token
func (s *service) Login(ctx context.Context, req *LoginRequest) (*AuthResponse, error) {
	// Get user from database
	fetchedUser, err := s.store.GetUserByEmail(ctx, req.Email)
	if err != nil {
		return nil, fmt.Errorf("Invalid Email Address or Password")
	}

	// Check if user is active
	if !fetchedUser.IsActive {
		return nil, fmt.Errorf("account is deactivated")
	}

	// Verify password
	err = bcrypt.CompareHashAndPassword([]byte(fetchedUser.PasswordHash), []byte(req.Password))
	if err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	// Generate JWT token
	token, expiresAt, err := s.jwtService.GenerateToken(fetchedUser.ID, fetchedUser.Email, string(fetchedUser.Role))
	if err != nil {
		return nil, fmt.Errorf("failed to generate token")
	}

	// Generate refresh token
	refreshToken, _, err := s.jwtService.GenerateRefreshToken(fetchedUser.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token")
	}

	// Update last login time
	err = s.store.UpdateLastLogin(ctx, fetchedUser.ID)
	if err != nil {
		// Log error but don't fail the login
		fmt.Printf("Failed to update last login: %v\n", err)
	}

	return &AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		ExpiresAt:    expiresAt,
		User: UserInfo{
			ID:       fetchedUser.ID,
			Email:    fetchedUser.Email,
			FullName: fetchedUser.FullName,
			Role:     string(fetchedUser.Role),
		},
	}, nil
}

// Register creates a new user account
func (s *service) Register(ctx context.Context, req *RegisterRequest) (*AuthResponse, error) {
	// Check if user already exists
	existingUser, _ := s.store.GetUserByEmail(ctx, req.Email)
	if existingUser != nil {
		return nil, fmt.Errorf("user with email %s already exists", req.Email)
	}

	// Hash the password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password")
	}

	// Create user
	userID := uuid.New().String()
	user := &User{
		ID:           userID,
		Email:        req.Email,
		FullName:     req.FullName,
		Role:         UserRole(req.Role),
		PasswordHash: string(hashedPassword),
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	err = s.store.CreateUser(ctx, user)
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Generate JWT token
	token, expiresAt, err := s.jwtService.GenerateToken(user.ID, user.Email, string(user.Role))
	if err != nil {
		return nil, fmt.Errorf("failed to generate token")
	}

	// Generate refresh token
	refreshToken, _, err := s.jwtService.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token")
	}

	return &AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		ExpiresAt:    expiresAt,
		User: UserInfo{
			ID:       user.ID,
			Email:    user.Email,
			FullName: user.FullName,
			Role:     string(user.Role),
		},
	}, nil
}

// RefreshToken refreshes an authentication token
func (s *service) RefreshToken(ctx context.Context, req *RefreshTokenRequest) (*AuthResponse, error) {
	// Validate the refresh token
	claims, err := s.jwtService.ValidateToken(req.RefreshToken)
	if err != nil {
		return nil, fmt.Errorf("invalid refresh token")
	}

	// Get user from database to ensure they still exist and are active
	user, err := s.store.GetUserByID(ctx, claims.UserID)
	if err != nil {
		return nil, fmt.Errorf("user not found")
	}

	if !user.IsActive {
		return nil, fmt.Errorf("account is deactivated")
	}

	// Generate new tokens
	token, expiresAt, err := s.jwtService.GenerateToken(user.ID, user.Email, string(user.Role))
	if err != nil {
		return nil, fmt.Errorf("failed to generate token")
	}

	newRefreshToken, _, err := s.jwtService.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token")
	}

	return &AuthResponse{
		Token:        token,
		RefreshToken: newRefreshToken,
		ExpiresAt:    expiresAt,
		User: UserInfo{
			ID:       user.ID,
			Email:    user.Email,
			FullName: user.FullName,
			Role:     string(user.Role),
		},
	}, nil
}

// ForgotPassword sends a password reset email
func (s *service) ForgotPassword(ctx context.Context, req *ForgotPasswordRequest) error {
	user, err := s.store.GetUserByEmail(ctx, req.Email)
	if err != nil {
		return nil
	}

	// Generate password reset token (valid for 1 hour)
	resetToken, _, err := s.jwtService.GenerateToken(user.ID, user.Email, "password_reset")
	if err != nil {
		return fmt.Errorf("failed to generate reset token")
	}

	// TODO: Send email with reset token
	// For now, just log the token (remove this in production)
	fmt.Printf("Password reset token for %s: %s\n", req.Email, resetToken)

	return nil
}

// ResetPassword resets a user's password using a reset token
func (s *service) ResetPassword(ctx context.Context, req *ResetPasswordRequest) error {
	// Validate the reset token
	claims, err := s.jwtService.ValidateToken(req.Token)
	if err != nil {
		return fmt.Errorf("invalid or expired reset token")
	}

	// Hash the new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash password")
	}

	// Update user's password
	err = s.store.UpdatePassword(ctx, claims.UserID, string(hashedPassword))
	if err != nil {
		return fmt.Errorf("failed to update password: %w", err)
	}

	return nil
}
