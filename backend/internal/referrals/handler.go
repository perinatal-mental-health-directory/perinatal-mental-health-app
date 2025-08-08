package referrals

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{
		service: service,
	}
}

// CreateReferral creates a new referral
func (h *Handler) CreateReferral(c echo.Context) error {
	var req CreateReferralRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	if err := c.Validate(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	referral, err := h.service.CreateReferral(c.Request().Context(), &req, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, referral)
}

// ListReferrals retrieves a paginated list of referrals
func (h *Handler) ListReferrals(c echo.Context) error {
	// Parse query parameters
	page := 1
	if p := c.QueryParam("page"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil && parsed > 0 {
			page = parsed
		}
	}

	pageSize := 20
	if ps := c.QueryParam("page_size"); ps != "" {
		if parsed, err := strconv.Atoi(ps); err == nil && parsed > 0 && parsed <= 100 {
			pageSize = parsed
		}
	}

	status := c.QueryParam("status")
	urgent := c.QueryParam("urgent") == "true"

	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	referrals, err := h.service.ListReferrals(c.Request().Context(), page, pageSize, userID, status, urgent)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, referrals)
}

// GetReferral retrieves a referral by ID
func (h *Handler) GetReferral(c echo.Context) error {
	referralIDStr := c.Param("id")
	referralID, err := strconv.Atoi(referralIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid referral ID",
		})
	}

	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	referral, err := h.service.GetReferral(c.Request().Context(), referralID, userID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, referral)
}

// UpdateReferral updates a referral (admin/staff only)
func (h *Handler) UpdateReferral(c echo.Context) error {
	referralIDStr := c.Param("id")
	referralID, err := strconv.Atoi(referralIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid referral ID",
		})
	}

	var req UpdateReferralRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	if err := c.Validate(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	referral, err := h.service.UpdateReferral(c.Request().Context(), referralID, &req)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, referral)
}

// GetReferralStats retrieves referral statistics (admin/staff only)
func (h *Handler) GetReferralStats(c echo.Context) error {
	stats, err := h.service.GetReferralStats(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, stats)
}

// Helper function to extract user ID from JWT context
func getUserIDFromContext(c echo.Context) string {
	if userID := c.Get("user_id"); userID != nil {
		if id, ok := userID.(string); ok {
			return id
		}
	}
	return ""
}
