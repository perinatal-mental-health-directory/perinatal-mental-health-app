package main

import (
	db2 "github.com/perinatal-mental-health-app/backend/internal/db"
	"github.com/perinatal-mental-health-app/backend/internal/logger"
	"log"
	"os"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	config "github.com/perinatal-mental-health-app/backend/internal/configs"
	custommiddleware "github.com/perinatal-mental-health-app/backend/internal/middleware"
	"github.com/perinatal-mental-health-app/backend/internal/routes"
)

func main() {
	e := echo.New()
	
	logger.Init()
	// Load configuration
	cfg := config.Load()

	// Initialize database
	db := db2.Init(cfg)
	defer db.Close()

	// CORS middleware
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"*"}, // Configure properly for production
		AllowMethods: []string{echo.GET, echo.HEAD, echo.PUT, echo.PATCH, echo.POST, echo.DELETE},
		AllowHeaders: []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, echo.HeaderAuthorization},
	}))

	// Security middleware
	e.Use(middleware.Secure())
	e.Use(middleware.RequestID())

	// Custom middleware
	custommiddleware.Logger(e)

	// Request validation middleware
	e.Use(middleware.BodyLimit("10M"))

	// Register routes
	routes.Register(e, db, cfg)

	// Determine port
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Start server
	log.Printf("Starting server on port %s", port)
	log.Fatal(e.Start("0.0.0.0:" + port))
}
