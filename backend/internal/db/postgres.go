package db

import (
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/perinatal-mental-health-app/backend/internal/configs"
	"github.com/perinatal-mental-health-app/backend/internal/logger"
	"go.uber.org/zap"
	"time"
)

var pool *pgxpool.Pool

// Init sets up the global Postgres connection pool.
func Init(cfg *config.Config) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	connStr := cfg.PostgresURL()
	var err error
	pool, err = pgxpool.New(ctx, connStr)
	if err != nil {
		logger.Error("Failed to connect to PostgreSQL", zap.Error(err))
		panic(err)
	}

	if err = pool.Ping(ctx); err != nil {
		logger.Error("PostgreSQL ping failed", zap.Error(err))
		panic(err)
	}

	logger.Info("Connected to PostgreSQL")
}

// GetPool returns the initialized pgxpool.Pool
func GetPool() *pgxpool.Pool {
	if pool == nil {
		logger.Error("PostgreSQL pool accessed before initialization")
		panic("PostgreSQL not initialized")
	}
	return pool
}
