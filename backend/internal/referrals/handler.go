package referrals

import (
	"net/http"
	"strconv"

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

// CreateReferral creates a new referral
func (h *handler) CreateReferral(c echo.Context) error {
	// Get user ID from JWT context
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	var req CreateReferralRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	referral, err := h.service.CreateReferral(c.Request().Context(), userID, &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, referral)
}

// ListSentReferrals retrieves sent referrals for the current user
func (h *handler) ListSentReferrals(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

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

	var isUrgent *bool
	if u := c.QueryParam("is_urgent"); u != "" {
		if parsed, err := strconv.ParseBool(u); err == nil {
			isUrgent = &parsed
		}
	}

	req := &ListReferralsRequest{
		Page:         page,
		PageSize:     pageSize,
		Status:       c.QueryParam("status"),
		ReferralType: c.QueryParam("referral_type"),
		IsUrgent:     isUrgent,
	}

	referrals, err := h.service.ListReferralsSent(c.Request().Context(), userID, req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, referrals)
}

// ListReceivedReferrals retrieves received referrals for the current user
func (h *handler) ListReceivedReferrals(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

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

	var isUrgent *bool
	if u := c.QueryParam("is_urgent"); u != "" {
		if parsed, err := strconv.ParseBool(u); err == nil {
			isUrgent = &parsed
		}
	}

	req := &ListReferralsRequest{
		Page:         page,
		PageSize:     pageSize,
		Status:       c.QueryParam("status"),
		ReferralType: c.QueryParam("referral_type"),
		IsUrgent:     isUrgent,
	}

	referrals, err := h.service.ListReferralsReceived(c.Request().Context(), userID, req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, referrals)
}

// GetReferral retrieves a referral by ID
func (h *handler) GetReferral(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	referralID := c.Param("id")
	if referralID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Referral ID is required",
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

// UpdateReferral updates a referral
func (h *handler) UpdateReferral(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	referralID := c.Param("id")
	if referralID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Referral ID is required",
		})
	}

	var req UpdateReferralRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	referral, err := h.service.UpdateReferral(c.Request().Context(), referralID, userID, &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, referral)
}

// UpdateReferralStatus updates only the status of a referral
func (h *handler) UpdateReferralStatus(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	referralID := c.Param("id")
	if referralID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Referral ID is required",
		})
	}

	var req struct {
		Status string `json:"status" validate:"required,oneof=pending accepted declined viewed"`
	}

	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	err := h.service.UpdateReferralStatus(c.Request().Context(), referralID, userID, req.Status)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Referral status updated successfully",
	})
}

// DeleteReferral deletes a referral
func (h *handler) DeleteReferral(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	referralID := c.Param("id")
	if referralID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Referral ID is required",
		})
	}

	err := h.service.DeleteReferral(c.Request().Context(), referralID, userID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Referral deleted successfully",
	})
}

// SearchUsers searches for users to refer to
func (h *handler) SearchUsers(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	query := c.QueryParam("q")
	if query == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Search query is required",
		})
	}

	limit := 20
	if l := c.QueryParam("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 50 {
			limit = parsed
		}
	}

	req := &UserSearchRequest{
		Query: query,
		Role:  c.QueryParam("role"),
		Limit: limit,
	}

	users, err := h.service.SearchUsers(c.Request().Context(), req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, users)
}

// GetReferralStats retrieves referral statistics for the current user
func (h *handler) GetReferralStats(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	stats, err := h.service.GetReferralStats(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, stats)
}

// GetReferralsByItem gets referrals for a specific item
func (h *handler) GetReferralsByItem(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	itemID := c.QueryParam("item_id")
	if itemID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Item ID is required",
		})
	}

	itemType := c.QueryParam("item_type")
	if itemType == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Item type is required",
		})
	}

	referrals, err := h.service.GetReferralsByItem(c.Request().Context(), itemID, itemType, userID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"referrals": referrals,
		"total":     len(referrals),
	})
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
