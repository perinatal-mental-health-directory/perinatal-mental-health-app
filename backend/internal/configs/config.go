package config

import (
	"fmt"
	"github.com/perinatal-mental-health-app/backend/internal/logger"
	"github.com/spf13/viper"
	"net"
	"os"
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
	// Get environment from ENV variable, default to "local"
	env := os.Getenv("APP_ENV")
	if env == "" {
		env = "local"
	}

	// Set config file based on environment
	configFile := fmt.Sprintf(".%s", env)

	viper.SetConfigName(configFile) // .local, .dev, .prod, etc.
	viper.SetConfigType("env")
	viper.AddConfigPath("./cfg")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		logger.Error(fmt.Sprintf("No config file found: ./cfg/%s.env. Using environment variables...", configFile))
	} else {
		logger.Info(fmt.Sprintf("Loaded config from: ./cfg/%s.env", configFile))
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

func (c *Config) PostgresURL() string {
	hostPort := net.JoinHostPort(c.DBHost, strconv.Itoa(c.DBPort))
	return fmt.Sprintf(
		"postgres://%s:%s@%s/%s?sslmode=%s",
		c.DBUser, c.DBPassword, hostPort, c.DBName, c.DBSSLMode,
	)
}
