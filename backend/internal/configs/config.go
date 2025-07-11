package config

import (
	"context"
	"fmt"
	"net"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/spf13/viper"
	"go.uber.org/zap"
)

type Config struct {
	DBUser     string
	DBPassword string
	DBHost     string
	DBPort     int
	DBName     string
	DBSSLMode  string
	RedisAddr  string
	RedisPass  string
	RedisDB    int
	JWTSecret  string
}

func Load() *Config {
	viper.SetConfigName("config")
	viper.SetConfigType("env")
	viper.AddConfigPath("./cfg")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		logger.Error("No config file found in ./cfg. Using environment variables...")
	}

	return &Config{
		DBUser:     viper.GetString("DB_USER"),
		DBPassword: viper.GetString("DB_PASSWORD"),
		DBHost:     viper.GetString("DB_HOST"),
		DBPort:     viper.GetInt("DB_PORT"),
		DBName:     viper.GetString("DB_NAME"),
		DBSSLMode:  viper.GetString("DB_SSLMODE"),
		RedisAddr:  viper.GetString("REDIS_ADDR"),
		RedisPass:  viper.GetString("REDIS_PASS"),
		RedisDB:    viper.GetInt("REDIS_DB"),
		JWTSecret:  viper.GetString("JWT_SECRET"),
	}
}

// PostgresURL builds the full connection string from the individual parts.
func (c *Config) PostgresURL() string {
	hostPort := net.JoinHostPort(c.DBHost, strconv.Itoa(c.DBPort))
	return fmt.Sprintf(
		"postgres://%s:%s@%s/%s?sslmode=%s",
		c.DBUser, c.DBPassword, hostPort, c.DBName, c.DBSSLMode,
	)
}

func InitPostgres(cfg *Config) *pgxpool.Pool {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	pgURL := cfg.PostgresURL()
	pool, err := pgxpool.New(ctx, pgURL)
	if err != nil {
		logger.Error("Could not connect to postgres", zap.Error(err))
	}

	if err = pool.Ping(ctx); err != nil {
		logger.Error("Could not ping postgres", zap.Error(err))
	}

	return pool
}
