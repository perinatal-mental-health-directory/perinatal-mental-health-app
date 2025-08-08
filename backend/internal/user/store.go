package user

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type store struct {
	db *pgxpool.Pool
}

func NewStore(db *pgxpool.Pool) Store {
	return &store{db: db}
}

// CreateUser creates a new user in the database
func (s *store) CreateUser(ctx context.Context, req *CreateUserRequest) (*User, error) {
	userID := uuid.New().String()
	now := time.Now()

	query := `
		INSERT INTO users (id, email, full_name, role, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, email, full_name, role, is_active, last_login_at, created_at, updated_at
	`

	user := &User{}
	err := s.db.QueryRow(ctx, query, userID, req.Email, req.FullName, req.Role, true, now, now).
		Scan(&user.ID, &user.Email, &user.FullName, &user.Role, &user.IsActive,
			&user.LastLoginAt, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Create user profile
	profileQuery := `
		INSERT INTO user_profiles (user_id, created_at, updated_at)
		VALUES ($1, $2, $3)
	`
	_, err = s.db.Exec(ctx, profileQuery, userID, now, now)
	if err != nil {
		return nil, fmt.Errorf("failed to create user profile: %w", err)
	}

	return user, nil
}

// GetUserByID retrieves a user by their ID
func (s *store) GetUserByID(ctx context.Context, userID string) (*User, error) {
	query := `
		SELECT id, email, full_name, role, is_active, last_login_at, created_at, updated_at
		FROM users
		WHERE id = $1 AND is_active = true
	`

	user := &User{}
	err := s.db.QueryRow(ctx, query, userID).
		Scan(&user.ID, &user.Email, &user.FullName, &user.Role, &user.IsActive,
			&user.LastLoginAt, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return user, nil
}

// GetUserByEmail retrieves a user by their email
func (s *store) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	query := `
		SELECT id, email, full_name, role, is_active, last_login_at, created_at, updated_at
		FROM users
		WHERE email = $1 AND is_active = true
	`

	user := &User{}
	err := s.db.QueryRow(ctx, query, email).
		Scan(&user.ID, &user.Email, &user.FullName, &user.Role, &user.IsActive,
			&user.LastLoginAt, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return user, nil
}

// GetUserProfile retrieves a user's profile information
func (s *store) GetUserProfile(ctx context.Context, userID string) (*UserProfile, error) {
	query := `
		SELECT user_id, phone_number, date_of_birth, address, emergency_contact, 
			   preferences, created_at, updated_at
		FROM user_profiles
		WHERE user_id = $1
	`

	profile := &UserProfile{}
	var preferencesJSON *string

	err := s.db.QueryRow(ctx, query, userID).
		Scan(&profile.UserID, &profile.PhoneNumber, &profile.DateOfBirth, &profile.Address,
			&profile.EmergencyContact, &preferencesJSON, &profile.CreatedAt, &profile.UpdatedAt)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("user profile not found")
		}
		return nil, fmt.Errorf("failed to get user profile: %w", err)
	}

	if preferencesJSON != nil {
		profile.Preferences = preferencesJSON
	}

	return profile, nil
}

// UpdateUser updates user information
func (s *store) UpdateUser(ctx context.Context, userID string, req *UpdateUserRequest) (*User, error) {
	var setParts []string
	var args []interface{}
	argIndex := 1

	if req.FullName != nil {
		setParts = append(setParts, fmt.Sprintf("full_name = $%d", argIndex))
		args = append(args, *req.FullName)
		argIndex++
	}

	if len(setParts) == 0 {
		return s.GetUserByID(ctx, userID)
	}

	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	query := fmt.Sprintf(`
		UPDATE users 
		SET %s
		WHERE id = $%d AND is_active = true
		RETURNING id, email, full_name, role, is_active, last_login_at, created_at, updated_at
	`, strings.Join(setParts, ", "), argIndex)

	args = append(args, userID)

	user := &User{}
	err := s.db.QueryRow(ctx, query, args...).
		Scan(&user.ID, &user.Email, &user.FullName, &user.Role, &user.IsActive,
			&user.LastLoginAt, &user.CreatedAt, &user.UpdatedAt)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	return user, nil
}

// UpdateUserProfile updates user profile information
func (s *store) UpdateUserProfile(ctx context.Context, userID string, req *UpdateUserRequest) (*UserProfile, error) {
	var setParts []string
	var args []interface{}
	argIndex := 1

	if req.PhoneNumber != nil {
		setParts = append(setParts, fmt.Sprintf("phone_number = $%d", argIndex))
		args = append(args, *req.PhoneNumber)
		argIndex++
	}

	if req.Address != nil {
		setParts = append(setParts, fmt.Sprintf("address = $%d", argIndex))
		args = append(args, *req.Address)
		argIndex++
	}

	if len(setParts) == 0 {
		return s.GetUserProfile(ctx, userID)
	}

	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	query := fmt.Sprintf(`
		UPDATE user_profiles 
		SET %s
		WHERE user_id = $%d
		RETURNING user_id, phone_number, date_of_birth, address, emergency_contact, 
				  preferences, created_at, updated_at
	`, strings.Join(setParts, ", "), argIndex)

	args = append(args, userID)

	profile := &UserProfile{}
	var preferencesJSON *string

	err := s.db.QueryRow(ctx, query, args...).
		Scan(&profile.UserID, &profile.PhoneNumber, &profile.DateOfBirth, &profile.Address,
			&profile.EmergencyContact, &preferencesJSON, &profile.CreatedAt, &profile.UpdatedAt)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("user profile not found")
		}
		return nil, fmt.Errorf("failed to update user profile: %w", err)
	}

	if preferencesJSON != nil {
		profile.Preferences = preferencesJSON
	}

	return profile, nil
}

// ListUsers retrieves a paginated list of users
func (s *store) ListUsers(ctx context.Context, page, pageSize int, role *UserRole) (*ListUsersResponse, error) {
	offset := (page - 1) * pageSize

	var whereClause string
	var args []interface{}
	argIndex := 1

	whereClause = "WHERE is_active = true"

	if role != nil {
		whereClause += fmt.Sprintf(" AND role = $%d", argIndex)
		args = append(args, *role)
		argIndex++
	}

	// Count total
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM users %s", whereClause)
	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count users: %w", err)
	}

	// Get users
	query := fmt.Sprintf(`
		SELECT id, email, full_name, role, is_active, last_login_at, created_at, updated_at
		FROM users
		%s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, argIndex, argIndex+1)

	args = append(args, pageSize, offset)

	rows, err := s.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list users: %w", err)
	}
	defer rows.Close()

	var users []UserResponse
	for rows.Next() {
		var user UserResponse
		err := rows.Scan(&user.ID, &user.Email, &user.FullName, &user.Role, &user.IsActive,
			&user.LastLoginAt, &user.CreatedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))

	return &ListUsersResponse{
		Users:      users,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
	}, nil
}

// UpdateLastLogin updates the user's last login time
func (s *store) UpdateLastLogin(ctx context.Context, userID string) error {
	query := `
		UPDATE users 
		SET last_login_at = $1, updated_at = $2
		WHERE id = $3 AND is_active = true
	`

	now := time.Now()
	_, err := s.db.Exec(ctx, query, now, now, userID)
	if err != nil {
		return fmt.Errorf("failed to update last login: %w", err)
	}

	return nil
}

// DeactivateUser soft deletes a user by setting is_active to false
func (s *store) DeactivateUser(ctx context.Context, userID string) error {
	query := `
		UPDATE users 
		SET is_active = false, updated_at = $1
		WHERE id = $2
	`

	_, err := s.db.Exec(ctx, query, time.Now(), userID)
	if err != nil {
		return fmt.Errorf("failed to deactivate user: %w", err)
	}

	return nil
}
