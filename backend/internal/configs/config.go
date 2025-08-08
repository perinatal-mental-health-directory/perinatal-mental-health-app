package config

import (
	"fmt"
	"github.com/perinatal-mental-health-app/backend/internal/logger"
	"github.com/spf13/viper"
	"net"
	"strconv"
)

type Config struct {
	DBUser     string
	DBPassword string
	DBHost     string
	DBPort     int
	DBName     string
	DBSSLMode  string
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
