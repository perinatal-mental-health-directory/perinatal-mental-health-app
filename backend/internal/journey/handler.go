package journey

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

// Journey Entries Handlers

// CreateJourneyEntry creates a new journey entry
func (h *handler) CreateJourneyEntry(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	var req CreateJourneyEntryRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	entry, err := h.service.CreateJourneyEntry(c.Request().Context(), userID, &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, entry)
}

// GetJourneyEntry retrieves a specific journey entry
func (h *handler) GetJourneyEntry(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	entryID := c.Param("id")
	if entryID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Entry ID is required",
		})
	}

	entry, err := h.service.GetJourneyEntry(c.Request().Context(), userID, entryID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, entry)
}

// GetTodaysEntry retrieves today's journey entry
func (h *handler) GetTodaysEntry(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	entry, err := h.service.GetTodaysEntry(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, entry)
}

// UpdateJourneyEntry updates an existing journey entry
func (h *handler) UpdateJourneyEntry(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	entryID := c.Param("id")
	if entryID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Entry ID is required",
		})
	}

	var req UpdateJourneyEntryRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	entry, err := h.service.UpdateJourneyEntry(c.Request().Context(), userID, entryID, &req)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, entry)
}

// DeleteJourneyEntry deletes a journey entry
func (h *handler) DeleteJourneyEntry(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	entryID := c.Param("id")
	if entryID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Entry ID is required",
		})
	}

	err := h.service.DeleteJourneyEntry(c.Request().Context(), userID, entryID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Journey entry deleted successfully",
	})
}

// ListJourneyEntries retrieves a paginated list of journey entries
func (h *handler) ListJourneyEntries(c echo.Context) error {
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

	pageSize := 30
	if ps := c.QueryParam("page_size"); ps != "" {
		if parsed, err := strconv.Atoi(ps); err == nil && parsed > 0 && parsed <= 100 {
			pageSize = parsed
		}
	}

	var startDate, endDate *string
	if sd := c.QueryParam("start_date"); sd != "" {
		startDate = &sd
	}
	if ed := c.QueryParam("end_date"); ed != "" {
		endDate = &ed
	}

	entries, err := h.service.ListJourneyEntries(c.Request().Context(), userID, page, pageSize, startDate, endDate)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, entries)
}

// Journey Goals Handlers

// CreateJourneyGoal creates a new journey goal
func (h *handler) CreateJourneyGoal(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	var req CreateJourneyGoalRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	goal, err := h.service.CreateJourneyGoal(c.Request().Context(), userID, &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, goal)
}

// UpdateJourneyGoal updates an existing journey goal
func (h *handler) UpdateJourneyGoal(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	goalID := c.Param("id")
	if goalID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Goal ID is required",
		})
	}

	var req UpdateJourneyGoalRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid request format",
		})
	}

	goal, err := h.service.UpdateJourneyGoal(c.Request().Context(), userID, goalID, &req)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, goal)
}

// DeleteJourneyGoal deletes a journey goal
func (h *handler) DeleteJourneyGoal(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	goalID := c.Param("id")
	if goalID == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Goal ID is required",
		})
	}

	err := h.service.DeleteJourneyGoal(c.Request().Context(), userID, goalID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Journey goal deleted successfully",
	})
}

// ListJourneyGoals retrieves all journey goals for a user
func (h *handler) ListJourneyGoals(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	var status *string
	if s := c.QueryParam("status"); s != "" {
		status = &s
	}

	goals, err := h.service.ListJourneyGoals(c.Request().Context(), userID, status)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"goals": goals,
		"total": len(goals),
	})
}

// Journey Analytics Handlers

// GetJourneyStats retrieves journey statistics for a user
func (h *handler) GetJourneyStats(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	stats, err := h.service.GetJourneyStats(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, stats)
}

// GetJourneyInsights retrieves journey insights for a user
func (h *handler) GetJourneyInsights(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	insights, err := h.service.GetJourneyInsights(c.Request().Context(), userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, insights)
}

// ListJourneyMilestones retrieves milestones for a user
func (h *handler) ListJourneyMilestones(c echo.Context) error {
	userID := getUserIDFromContext(c)
	if userID == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{
			"error": "User not authenticated",
		})
	}

	limit := 10
	if l := c.QueryParam("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 50 {
			limit = parsed
		}
	}

	milestones, err := h.service.ListJourneyMilestones(c.Request().Context(), userID, limit)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"milestones": milestones,
		"total":      len(milestones),
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
