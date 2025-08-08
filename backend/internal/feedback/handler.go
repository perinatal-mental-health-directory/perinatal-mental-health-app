package feedback

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

// CreateFeedback creates new feedback
func (h *Handler) CreateFeedback(c echo.Context) error {
	var req CreateFeedbackRequest
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

	// Get user ID from context if not anonymous
	var userID *string
	if !req.Anonymous {
		if uid := getUserIDFromContext(c); uid != "" {
			userID = &uid
		}
	}

	feedback, err := h.service.CreateFeedback(c.Request().Context(), &req, userID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, feedback)
}

// ListFeedback retrieves a paginated list of feedback (admin only)
func (h *Handler) ListFeedback(c echo.Context) error {
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
	rating := c.QueryParam("rating")

	feedback, err := h.service.ListFeedback(c.Request().Context(), page, pageSize, category, rating)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, feedback)
}

// GetFeedbackStats retrieves feedback statistics (admin only)
func (h *Handler) GetFeedbackStats(c echo.Context) error {
	stats, err := h.service.GetFeedbackStats(c.Request().Context())
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
