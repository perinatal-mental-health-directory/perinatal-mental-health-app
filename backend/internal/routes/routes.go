package routes

import (
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	config "github.com/perinatal-mental-health-app/backend/internal/configs"
	"github.com/perinatal-mental-health-app/backend/internal/health"
)

func Register(e *echo.Echo, db *pgxpool.Pool, _ *config.Config) {
	//v1 := e.Group("/v1")

	e.GET("/health", health.Health)

	// --- API Keys ---
	//apikeyStore := apikey.NewStore(db)
	//apikeyService := apikey.NewService(apikeyStore)
	//apikeyHandler := apikey.NewHandler(apikeyService)
	//
	//v1.GET("/apikeys", apikeyHandler.List)
	//v1.POST("/apikeys", apikeyHandler.POST)
	//v1.DELETE("/apikeys/:id", apikeyHandler.Delete)

	// Example placeholders for future modules:
	// --- Auth ---
	// authHandler := auth.NewHandler(...)
	// v1.POST("/auth/register", authHandler.Register)
	// v1.POST("/auth/login", authHandler.Login)

	// --- Rate Limits ---
	// rateLimitHandler := ratelimit.NewHandler(...)
	// v1.PUT("/apikeys/:id/limits", rateLimitHandler.UpdateLimits)

	// --- Proxy ---
	// proxyHandler := proxy.NewHandler(...)
	// v1.GET("/proxy/:apikey/*", proxyHandler.Forward)
}
