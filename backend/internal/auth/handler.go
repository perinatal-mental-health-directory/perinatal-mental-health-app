package auth

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

type handler struct {
	service Service
}

func NewHandler(service Service) Handler {
	return &handler{
		service: service,
	}
}

// Login authenticates a user and returns a JWT token
func (h *handler) Login(c echo.Context) error {
	var req LoginRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	authResp, err := h.service.Login(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, authResp)
}

// Register creates a new user account
func (h *handler) Register(c echo.Context) error {
	var req RegisterRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	authResp, err := h.service.Register(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusConflict, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, authResp)
}

// RefreshToken refreshes an authentication token
func (h *handler) RefreshToken(c echo.Context) error {
	var req RefreshTokenRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	authResp, err := h.service.RefreshToken(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, authResp)
}

// ForgotPassword sends a password reset email
func (h *handler) ForgotPassword(c echo.Context) error {
	var req ForgotPasswordRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	err := h.service.ForgotPassword(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": "Failed to process request",
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "If an account with that email exists, a password reset link has been sent",
	})
}

// ResetPassword resets a user's password using a reset token
func (h *handler) ResetPassword(c echo.Context) error {
	var req ResetPasswordRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	err := h.service.ResetPassword(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Password reset successfully",
	})
}

// ChangePassword changes a user's password
func (h *handler) ChangePassword(c echo.Context) error {
	var req ChangePasswordRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	// Get user ID from JWT context
	userID := c.Get("user_id")
	if userID == nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "Invalid user ID",
		})
	}

	err := h.service.ChangePassword(c.Request().Context(), userIDStr, &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Password changed successfully",
	})
}
