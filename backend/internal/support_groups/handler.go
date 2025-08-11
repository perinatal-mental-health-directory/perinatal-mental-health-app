// backend/internal/support_groups/handler.go
package support_groups

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

// ListSupportGroups retrieves a paginated list of support groups with optional filters
func (h *handler) ListSupportGroups(c echo.Context) error {
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

	category := c.QueryParam("category")
	platform := c.QueryParam("platform")
	search := c.QueryParam("search")

	// If search query is provided, use search functionality
	if search != "" {
		groups, err := h.service.SearchSupportGroups(c.Request().Context(), search, page, pageSize)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]string{
				"error": err.Error(),
			})
		}
		return c.JSON(http.StatusOK, groups)
	}

	// Regular list with filters
	groups, err := h.service.ListSupportGroups(c.Request().Context(), page, pageSize, category, platform)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, groups)
}

// GetSupportGroup retrieves a support group by ID
func (h *handler) GetSupportGroup(c echo.Context) error {
	groupID := c.Param("id") // Remove strconv.Atoi conversion
	if groupID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid group ID",
		})
	}

	group, err := h.service.GetSupportGroup(c.Request().Context(), groupID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, group)
}

// SearchSupportGroups handles search requests
func (h *handler) SearchSupportGroups(c echo.Context) error {
	query := c.QueryParam("q")
	if query == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Search query is required",
		})
	}

	// Parse pagination parameters
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

	groups, err := h.service.SearchSupportGroups(c.Request().Context(), query, page, pageSize)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, groups)
}

// GetSupportGroupsByCategory retrieves support groups by category
func (h *handler) GetSupportGroupsByCategory(c echo.Context) error {
	category := c.QueryParam("category")
	if category == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Category parameter is required",
		})
	}

	// Parse pagination parameters
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

	groups, err := h.service.GetSupportGroupsByCategory(c.Request().Context(), category, page, pageSize)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, groups)
}

// GetSupportGroupsByPlatform retrieves support groups by platform
func (h *handler) GetSupportGroupsByPlatform(c echo.Context) error {
	platform := c.QueryParam("platform")
	if platform == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Platform parameter is required",
		})
	}

	// Parse pagination parameters
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

	groups, err := h.service.GetSupportGroupsByPlatform(c.Request().Context(), platform, page, pageSize)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, groups)
}

// GetUserGroups retrieves all groups a user is a member of
func (h *handler) GetUserGroups(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	groups, err := h.service.GetUserGroups(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"groups": groups,
		"total":  len(groups),
	})
}

// JoinGroup adds a user to a support group
func (h *handler) JoinGroup(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	var req JoinGroupRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	err := h.service.JoinGroup(c.Request().Context(), userID, req.GroupID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Successfully joined the support group",
	})
}

// LeaveGroup removes a user from a support group
// LeaveGroup removes a user from a support group
func (h *handler) LeaveGroup(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	groupID := c.Param("id")
	if groupID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid group ID",
		})
	}

	err := h.service.LeaveGroup(c.Request().Context(), userID, groupID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Successfully left the support group",
	})
}

// GetGroupMembers retrieves all members of a support group
func (h *handler) GetGroupMembers(c echo.Context) error {
	groupID := c.Param("id")
	if groupID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid group ID",
		})
	}

	members, err := h.service.GetGroupMembers(c.Request().Context(), groupID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"members": members,
		"total":   len(members),
	})
}

// GetSupportGroupStats retrieves support group statistics (admin only)
func (h *handler) GetSupportGroupStats(c echo.Context) error {
	stats, err := h.service.GetSupportGroupStats(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, stats)
}

// CreateSupportGroup creates a new support group (admin only)
func (h *handler) CreateSupportGroup(c echo.Context) error {
	var req CreateSupportGroupRequest
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

	group, err := h.service.CreateSupportGroup(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, group)
}

// UpdateSupportGroup updates a support group (admin only)
func (h *handler) UpdateSupportGroup(c echo.Context) error {
	groupID := c.Param("id")
	if groupID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid group ID",
		})
	}

	var req UpdateSupportGroupRequest
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

	group, err := h.service.UpdateSupportGroup(c.Request().Context(), groupID, &req)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, group)
}

// DeleteSupportGroup deletes a support group (admin only)
func (h *handler) DeleteSupportGroup(c echo.Context) error {
	groupID := c.Param("id")
	if groupID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid group ID",
		})
	}

	err := h.service.DeleteSupportGroup(c.Request().Context(), groupID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Support group deleted successfully",
	})
}

// RemoveUserFromGroup removes a user from a group (admin only)
func (h *handler) RemoveUserFromGroup(c echo.Context) error {
	groupID := c.Param("id")
	if groupID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid group ID",
		})
	}

	userID := c.Param("user_id")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "User ID is required",
		})
	}

	err := h.service.RemoveUserFromGroup(c.Request().Context(), userID, groupID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "User removed from group successfully",
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
