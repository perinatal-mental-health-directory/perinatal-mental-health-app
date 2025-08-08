package auth

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type store struct {
	db *pgxpool.Pool
}

func NewStore(db *pgxpool.Pool) Store {
	return &store{
		db: db,
	}
}

// GetUserByEmail retrieves a user by email
func (s *store) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	query := `
		SELECT id, email, full_name, role, password_hash, is_active, last_login_at, created_at, updated_at
		FROM users 
		WHERE email = $1
	`

	var user User
	err := s.db.QueryRow(ctx, query, email).Scan(
		&user.ID,
		&user.Email,
		&user.FullName,
		&user.Role,
		&user.PasswordHash,
		&user.IsActive,
		&user.LastLoginAt,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &user, nil
}

// GetUserByID retrieves a user by ID
func (s *store) GetUserByID(ctx context.Context, userID string) (*User, error) {
	query := `
		SELECT id, email, full_name, role, password_hash, is_active, last_login_at, created_at, updated_at
		FROM users 
		WHERE id = $1
	`

	var user User
	err := s.db.QueryRow(ctx, query, userID).Scan(
		&user.ID,
		&user.Email,
		&user.FullName,
		&user.Role,
		&user.PasswordHash,
		&user.IsActive,
		&user.LastLoginAt,
		&user.CreatedAt,
		&user.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &user, nil
}

// CreateUser creates a new user
func (s *store) CreateUser(ctx context.Context, user *User) error {
	query := `
		INSERT INTO users (id, email, full_name, role, password_hash, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	_, err := s.db.Exec(ctx, query,
		user.ID,
		user.Email,
		user.FullName,
		user.Role,
		user.PasswordHash,
		user.IsActive,
		user.CreatedAt,
		user.UpdatedAt,
	)

	return err
}

// UpdateLastLogin updates the user's last login time
func (s *store) UpdateLastLogin(ctx context.Context, userID string) error {
	query := `
		UPDATE users 
		SET last_login_at = $1, updated_at = $2
		WHERE id = $3
	`

	now := time.Now()
	_, err := s.db.Exec(ctx, query, now, now, userID)
	return err
}

// UpdatePassword updates the user's password
func (s *store) UpdatePassword(ctx context.Context, userID, passwordHash string) error {
	query := `
		UPDATE users 
		SET password_hash = $1, updated_at = $2
		WHERE id = $3
	`

	_, err := s.db.Exec(ctx, query, passwordHash, time.Now(), userID)
	return err
}
