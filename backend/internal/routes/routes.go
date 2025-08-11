package routes

import (
	"github.com/perinatal-mental-health-app/backend/internal/feedback"
	"github.com/perinatal-mental-health-app/backend/internal/user"
	"net/http"
	"strconv"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/labstack/echo/v4"
	"github.com/perinatal-mental-health-app/backend/internal/auth"
	config "github.com/perinatal-mental-health-app/backend/internal/configs"
	"github.com/perinatal-mental-health-app/backend/internal/health"
	"github.com/perinatal-mental-health-app/backend/internal/journey"
	custommiddleware "github.com/perinatal-mental-health-app/backend/internal/middleware"
	"github.com/perinatal-mental-health-app/backend/internal/privacy"
	"github.com/perinatal-mental-health-app/backend/internal/referrals"
	"github.com/perinatal-mental-health-app/backend/internal/resources"
	"github.com/perinatal-mental-health-app/backend/internal/services"
	"github.com/perinatal-mental-health-app/backend/internal/support_groups"
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
	users.GET("/search", userHandler.SearchUsers) // Added missing search endpoint
	users.GET("/:id", userHandler.GetUser)
	users.GET("/:id/profile", userHandler.GetUserProfile)
	users.PUT("/:id", userHandler.UpdateUser, custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	users.DELETE("/:id", userHandler.DeactivateUser, custommiddleware.RoleMiddleware("nhs_staff", "professional"))

	// Auth routes that need to be with users context
	v1.POST("/auth/change-password", authHandler.ChangePassword, custommiddleware.JWTMiddleware(jwtService))

	// Current user routes (require authentication)
	me := v1.Group("/me")
	me.Use(custommiddleware.JWTMiddleware(jwtService))
	me.GET("", userHandler.GetCurrentUserProfile)
	me.PUT("", userHandler.UpdateCurrentUser)
	me.POST("/last-login", userHandler.UpdateLastLogin)
	me.GET("/preferences", userHandler.GetUserPreferences)    // Added missing preferences endpoint
	me.PUT("/preferences", userHandler.UpdateUserPreferences) // Added missing preferences endpoint

	// --- Privacy & GDPR ---
	privacyStore := privacy.NewStore(db)
	privacyService := privacy.NewService(privacyStore)
	privacyHandler := privacy.NewHandler(privacyService)

	// Privacy routes (require authentication)
	privacyGroup := v1.Group("/privacy")
	privacyGroup.Use(custommiddleware.JWTMiddleware(jwtService))
	privacyGroup.GET("/preferences", privacyHandler.GetPrivacyPreferences)
	privacyGroup.PUT("/preferences", privacyHandler.UpdatePrivacyPreferences)
	privacyGroup.POST("/request-data-download", privacyHandler.RequestDataDownload)
	privacyGroup.POST("/request-account-deletion", privacyHandler.RequestAccountDeletion)
	privacyGroup.GET("/data-retention-info", privacyHandler.GetDataRetentionInfo)
	privacyGroup.GET("/export-data", privacyHandler.ExportUserData)
	privacyGroup.GET("/data-requests", privacyHandler.GetDataRequests)

	// --- Services ---
	servicesStore := services.NewStore(db)
	servicesService := services.NewService(servicesStore)
	servicesHandler := services.NewHandler(servicesService)

	// Public service routes
	v1.GET("/services", servicesHandler.ListServices)
	v1.GET("/services/search", servicesHandler.SearchServices)
	v1.GET("/services/:id", servicesHandler.GetService)

	// Featured services endpoint
	v1.GET("/services/featured", func(c echo.Context) error {
		limit := 2
		if l := c.QueryParam("limit"); l != "" {
			if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 20 {
				limit = parsed
			}
		}

		servicesList, err := servicesService.GetFeaturedServices(c.Request().Context(), limit)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{
				"error": err.Error(),
			})
		}

		return c.JSON(http.StatusOK, servicesList)
	})

	// Admin routes for services (require staff/professional role)
	adminServices := v1.Group("/admin/services")
	adminServices.Use(custommiddleware.JWTMiddleware(jwtService))
	adminServices.Use(custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	adminServices.POST("", servicesHandler.CreateService)
	adminServices.PUT("/:id", servicesHandler.UpdateService)
	adminServices.DELETE("/:id", servicesHandler.DeleteService)
	adminServices.GET("/stats", servicesHandler.GetServiceStats)

	// --- Resources ---
	resourcesStore := resources.NewStore(db)
	resourcesService := resources.NewService(resourcesStore)
	resourcesHandler := resources.NewHandler(resourcesService)

	// Public resource routes
	v1.GET("/resources", resourcesHandler.ListResources)
	v1.GET("/resources/search", resourcesHandler.SearchResources)
	v1.GET("/resources/:id", resourcesHandler.GetResource)
	v1.GET("/resources/featured", resourcesHandler.GetFeaturedResources)
	v1.GET("/resources/popular", resourcesHandler.GetPopularResources)
	v1.GET("/resources/by-tag", resourcesHandler.GetResourcesByTag)
	v1.GET("/resources/by-audience", resourcesHandler.GetResourcesByAudience)

	// Resource interaction routes (require authentication for tracking)
	resourcesAuth := v1.Group("/resources")
	resourcesAuth.Use(custommiddleware.OptionalJWTMiddleware(jwtService))
	resourcesAuth.POST("/:id/view", resourcesHandler.IncrementViewCount)

	// Admin routes for resources (require staff/professional role)
	adminResources := v1.Group("/admin/resources")
	adminResources.Use(custommiddleware.JWTMiddleware(jwtService))
	adminResources.Use(custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	adminResources.POST("", resourcesHandler.CreateResource)
	adminResources.PUT("/:id", resourcesHandler.UpdateResource)
	adminResources.DELETE("/:id", resourcesHandler.DeleteResource)
	adminResources.POST("/:id/toggle-featured", resourcesHandler.ToggleResourceFeatured)
	adminResources.GET("/stats", resourcesHandler.GetResourceStats)

	// --- Support Groups ---
	supportGroupsStore := support_groups.NewStore(db)
	supportGroupsService := support_groups.NewService(supportGroupsStore)
	supportGroupsHandler := support_groups.NewHandler(supportGroupsService)

	// Public support group routes
	v1.GET("/support-groups", supportGroupsHandler.ListSupportGroups)
	v1.GET("/support-groups/search", supportGroupsHandler.SearchSupportGroups)
	v1.GET("/support-groups/:id", supportGroupsHandler.GetSupportGroup)
	v1.GET("/support-groups/by-category", supportGroupsHandler.GetSupportGroupsByCategory)
	v1.GET("/support-groups/by-platform", supportGroupsHandler.GetSupportGroupsByPlatform)

	// Protected support group routes (require authentication)
	supportGroupsAuth := v1.Group("/support-groups")
	supportGroupsAuth.Use(custommiddleware.JWTMiddleware(jwtService))
	supportGroupsAuth.POST("/join", supportGroupsHandler.JoinGroup)
	supportGroupsAuth.DELETE("/:id/leave", supportGroupsHandler.LeaveGroup)
	supportGroupsAuth.GET("/:id/members", supportGroupsHandler.GetGroupMembers)

	// User's support groups
	v1.GET("/my-groups", supportGroupsHandler.GetUserGroups, custommiddleware.JWTMiddleware(jwtService))

	// Admin routes for support groups (require staff/professional role)
	adminSupportGroups := v1.Group("/admin/support-groups")
	adminSupportGroups.Use(custommiddleware.JWTMiddleware(jwtService))
	adminSupportGroups.Use(custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	adminSupportGroups.POST("", supportGroupsHandler.CreateSupportGroup)
	adminSupportGroups.PUT("/:id", supportGroupsHandler.UpdateSupportGroup)
	adminSupportGroups.DELETE("/:id", supportGroupsHandler.DeleteSupportGroup)
	adminSupportGroups.DELETE("/:id/members/:user_id", supportGroupsHandler.RemoveUserFromGroup)
	adminSupportGroups.GET("/stats", supportGroupsHandler.GetSupportGroupStats)

	// --- Referrals ---
	referralsStore := referrals.NewStore(db)
	referralsService := referrals.NewService(referralsStore)
	referralsHandler := referrals.NewHandler(referralsService)

	// Protected referral routes (require authentication)
	referralsGroup := v1.Group("/referrals")
	referralsGroup.Use(custommiddleware.JWTMiddleware(jwtService))

	// Create referral (professionals/NHS staff only)
	referralsGroup.POST("", referralsHandler.CreateReferral, custommiddleware.RoleMiddleware("nhs_staff", "professional"))

	// List referrals
	referralsGroup.GET("/sent", referralsHandler.ListSentReferrals, custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	referralsGroup.GET("/received", referralsHandler.ListReceivedReferrals)

	// Individual referral operations
	referralsGroup.GET("/:id", referralsHandler.GetReferral)
	referralsGroup.PUT("/:id", referralsHandler.UpdateReferral)
	referralsGroup.PUT("/:id/status", referralsHandler.UpdateReferralStatus)
	referralsGroup.DELETE("/:id", referralsHandler.DeleteReferral, custommiddleware.RoleMiddleware("nhs_staff", "professional"))

	// Search users for referrals (professionals/NHS staff only)
	referralsGroup.GET("/users/search", referralsHandler.SearchUsers, custommiddleware.RoleMiddleware("nhs_staff", "professional"))

	// Get referrals by item
	referralsGroup.GET("/by-item", referralsHandler.GetReferralsByItem)

	// Referral statistics
	referralsGroup.GET("/stats", referralsHandler.GetReferralStats, custommiddleware.RoleMiddleware("nhs_staff", "professional"))

	// Legacy compatibility - Default referrals endpoint maps to received for parents, sent for professionals
	v1.GET("/referrals", func(c echo.Context) error {
		userRole := c.Get("user_role")
		if userRole == nil {
			return c.JSON(http.StatusUnauthorized, map[string]string{
				"error": "User role not found",
			})
		}

		role, ok := userRole.(string)
		if !ok {
			return c.JSON(http.StatusUnauthorized, map[string]string{
				"error": "Invalid user role format",
			})
		}

		// Route to appropriate handler based on role
		if role == "professional" || role == "nhs_staff" {
			return referralsHandler.ListSentReferrals(c)
		} else {
			return referralsHandler.ListReceivedReferrals(c)
		}
	}, custommiddleware.JWTMiddleware(jwtService))

	// Admin/Staff routes for referrals (require staff/professional role)
	adminReferrals := v1.Group("/admin/referrals")
	adminReferrals.Use(custommiddleware.JWTMiddleware(jwtService))
	adminReferrals.Use(custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	adminReferrals.GET("/stats", referralsHandler.GetReferralStats)

	// --- Enhanced Feedback Routes ---
	feedbackStore := feedback.NewStore(db)
	feedbackService := feedback.NewService(feedbackStore)
	feedbackHandler := feedback.NewHandler(feedbackService)

	// Public feedback submission (anonymous allowed)
	v1.POST("/feedback", feedbackHandler.CreateFeedback, custommiddleware.OptionalJWTMiddleware(jwtService))

	// User's own feedback (require authentication)
	userFeedback := v1.Group("/my-feedback")
	userFeedback.Use(custommiddleware.JWTMiddleware(jwtService))
	userFeedback.GET("", feedbackHandler.GetUserFeedback)

	// Admin routes for feedback (require staff/professional role)
	adminFeedback := v1.Group("/admin/feedback")
	adminFeedback.Use(custommiddleware.JWTMiddleware(jwtService))
	adminFeedback.Use(custommiddleware.RoleMiddleware("nhs_staff", "professional"))
	adminFeedback.GET("", feedbackHandler.ListFeedback)                    // List all feedback
	adminFeedback.GET("/stats", feedbackHandler.GetFeedbackStats)          // Get feedback statistics
	adminFeedback.GET("/:id", feedbackHandler.GetFeedback)                 // Get single feedback
	adminFeedback.PUT("/:id/status", feedbackHandler.UpdateFeedbackStatus) // Update feedback status

	// --- Journey ---
	journeyStore := journey.NewStore(db)
	journeyService := journey.NewService(journeyStore)
	journeyHandler := journey.NewHandler(journeyService)

	// Protected journey routes (require authentication)
	journeyGroup := v1.Group("/journey")
	journeyGroup.Use(custommiddleware.JWTMiddleware(jwtService))

	// Journey Entries
	journeyGroup.POST("/entries", journeyHandler.CreateJourneyEntry)
	journeyGroup.GET("/entries", journeyHandler.ListJourneyEntries)
	journeyGroup.GET("/entries/today", journeyHandler.GetTodaysEntry)
	journeyGroup.GET("/entries/:id", journeyHandler.GetJourneyEntry)
	journeyGroup.PUT("/entries/:id", journeyHandler.UpdateJourneyEntry)
	journeyGroup.DELETE("/entries/:id", journeyHandler.DeleteJourneyEntry)

	// Journey Goals
	journeyGroup.POST("/goals", journeyHandler.CreateJourneyGoal)
	journeyGroup.GET("/goals", journeyHandler.ListJourneyGoals)
	journeyGroup.PUT("/goals/:id", journeyHandler.UpdateJourneyGoal)
	journeyGroup.DELETE("/goals/:id", journeyHandler.DeleteJourneyGoal)

	// Journey Analytics
	journeyGroup.GET("/stats", journeyHandler.GetJourneyStats)
	journeyGroup.GET("/insights", journeyHandler.GetJourneyInsights)
	journeyGroup.GET("/milestones", journeyHandler.ListJourneyMilestones)
}
