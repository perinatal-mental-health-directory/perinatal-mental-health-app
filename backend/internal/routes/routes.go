package routes

import (
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	"github.com/perinatal-mental-health-app/backend/internal/auth"
	config "github.com/perinatal-mental-health-app/backend/internal/configs"
	"github.com/perinatal-mental-health-app/backend/internal/feedback"
	"github.com/perinatal-mental-health-app/backend/internal/health"
	custommiddleware "github.com/perinatal-mental-health-app/backend/internal/middleware"
	"github.com/perinatal-mental-health-app/backend/internal/referrals"
	"github.com/perinatal-mental-health-app/backend/internal/services"
	"github.com/perinatal-mental-health-app/backend/internal/user"
)

func Register(e *echo.Echo, db *pgxpool.Pool, cfg *config.Config) {
	v1 := e.Group("/api/v1")

	e.GET("/health", health.Health)

	// Initialize JWT service
	jwtService := auth.NewJWTService(cfg.JWTSecret)

	// --- Auth ---
	authStore := auth.NewStore(db)
	authService := auth.NewService(authStore, *jwtService)
	authHandler := auth.NewHandler(authService)

	// Public auth routes
	v1.POST("/auth/register", authHandler.Register)
	v1.POST("/auth/login", authHandler.Login)
	v1.POST("/auth/refresh", authHandler.RefreshToken)
	v1.POST("/auth/forgot-password", authHandler.ForgotPassword)
	v1.POST("/auth/reset-password", authHandler.ResetPassword)

	// --- Users ---
	userStore := user.NewStore(db)
	userService := user.NewService(userStore)
	userHandler := user.NewHandler(userService)

	// Public user routes
	v1.POST("/users", userHandler.CreateUser)

	// Protected user routes (require JWT authentication)
	users := v1.Group("/users")
	users.Use(custommiddleware.JWTMiddleware(jwtService))
	users.GET("", userHandler.ListUsers, custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	users.GET("/:id", userHandler.GetUser)
	users.GET("/:id/profile", userHandler.GetUserProfile)
	users.PUT("/:id", userHandler.UpdateUser, custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	users.DELETE("/:id", userHandler.DeactivateUser, custommiddleware.RoleMiddleware("nhs_staff", "professional"))

	// Current user routes (require authentication)
	me := v1.Group("/me")
	me.Use(custommiddleware.JWTMiddleware(jwtService))
	me.GET("", userHandler.GetCurrentUserProfile)
	me.PUT("", userHandler.UpdateCurrentUser)
	me.POST("/last-login", userHandler.UpdateLastLogin)

	// --- Services ---
	servicesStore := services.NewStore(db)
	servicesService := services.NewService(servicesStore)
	servicesHandler := services.NewHandler(servicesService)

	// Public service routes
	v1.GET("/services", servicesHandler.ListServices)
	v1.GET("/services/:id", servicesHandler.GetService)

	// Admin routes for services (require staff/professional role)
	adminServices := v1.Group("/admin/services")
	adminServices.Use(custommiddleware.JWTMiddleware(jwtService))
	adminServices.Use(custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	adminServices.POST("", servicesHandler.CreateService)
	adminServices.PUT("/:id", servicesHandler.UpdateService)
	adminServices.DELETE("/:id", servicesHandler.DeleteService)

	// --- Referrals ---
	referralsStore := referrals.NewStore(db)
	referralsService := referrals.NewService(referralsStore)
	referralsHandler := referrals.NewHandler(referralsService)

	// Protected referral routes (require authentication)
	referralsGroup := v1.Group("/referrals")
	referralsGroup.Use(custommiddleware.JWTMiddleware(jwtService))
	referralsGroup.GET("", referralsHandler.ListReferrals)
	referralsGroup.POST("", referralsHandler.CreateReferral)
	referralsGroup.GET("/:id", referralsHandler.GetReferral)

	// Admin/Staff routes for referrals (require staff/professional role)
	adminReferrals := v1.Group("/admin/referrals")
	adminReferrals.Use(custommiddleware.JWTMiddleware(jwtService))
	adminReferrals.Use(custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	adminReferrals.PUT("/:id", referralsHandler.UpdateReferral)
	adminReferrals.GET("/stats", referralsHandler.GetReferralStats)

	// --- Feedback ---
	feedbackStore := feedback.NewStore(db)
	feedbackService := feedback.NewService(feedbackStore)
	feedbackHandler := feedback.NewHandler(feedbackService)

	// Protected feedback routes (require authentication)
	feedbackGroup := v1.Group("/feedback")
	feedbackGroup.Use(custommiddleware.JWTMiddleware(jwtService))
	feedbackGroup.POST("", feedbackHandler.CreateFeedback)

	// Admin routes for feedback (require staff/professional role)
	adminFeedback := v1.Group("/admin/feedback")
	adminFeedback.Use(custommiddleware.JWTMiddleware(jwtService))
	adminFeedback.Use(custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	adminFeedback.GET("", feedbackHandler.ListFeedback)
	adminFeedback.GET("/stats", feedbackHandler.GetFeedbackStats)

	// Future modules to be implemented:
	// --- Support Groups ---
	// groupHandler := group.NewHandler(...)
	// groupsGroup := v1.Group("/groups")
	// groupsGroup.Use(custommiddleware.JWTMiddleware(jwtService))
	// groupsGroup.GET("", groupHandler.List)
	// groupsGroup.POST("/:id/join", groupHandler.Join)

	// --- Resources ---
	// resourceHandler := resource.NewHandler(...)
	// resourcesGroup := v1.Group("/resources")
	// resourcesGroup.Use(custommiddleware.OptionalJWTMiddleware(jwtService))
	// resourcesGroup.GET("", resourceHandler.List)
	// resourcesGroup.GET("/:id", resourceHandler.GetByID)

	// --- Notifications ---
	// notificationHandler := notification.NewHandler(...)
	// notificationsGroup := v1.Group("/notifications")
	// notificationsGroup.Use(custommiddleware.JWTMiddleware(jwtService))
	// notificationsGroup.GET("", notificationHandler.List)
	// notificationsGroup.PUT("/:id/read", notificationHandler.MarkAsRead)
}
