package resources

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

// ListResources retrieves a paginated list of resources with optional filters
func (h *handler) ListResources(c echo.Context) error {
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

	featured := c.QueryParam("featured")
	var featuredPtr *bool
	if featured != "" {
		if f, err := strconv.ParseBool(featured); err == nil {
			featuredPtr = &f
		}
	}

	req := &ListResourcesRequest{
		Page:           page,
		PageSize:       pageSize,
		Search:         c.QueryParam("search"),
		ResourceType:   c.QueryParam("resource_type"),
		TargetAudience: c.QueryParam("target_audience"),
		Tags:           c.QueryParam("tags"),
		Featured:       featuredPtr,
	}

	resources, err := h.service.ListResources(c.Request().Context(), req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, resources)
}

// GetResource retrieves a resource by ID
func (h *handler) GetResource(c echo.Context) error {
	resourceIDStr := c.Param("id")
	resourceID, err := strconv.Atoi(resourceIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid resource ID",
		})
	}

	resource, err := h.service.GetResource(c.Request().Context(), resourceID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, resource)
}

// GetFeaturedResources retrieves featured resources
func (h *handler) GetFeaturedResources(c echo.Context) error {
	limit := 6
	if l := c.QueryParam("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 20 {
			limit = parsed
		}
	}

	resources, err := h.service.GetFeaturedResources(c.Request().Context(), limit)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"resources": resources,
		"total":     len(resources),
	})
}

// SearchResources handles search requests
func (h *handler) SearchResources(c echo.Context) error {
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

	resources, err := h.service.SearchResources(c.Request().Context(), query, page, pageSize)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, resources)
}

// GetResourcesByTag retrieves resources by tag
func (h *handler) GetResourcesByTag(c echo.Context) error {
	tag := c.QueryParam("tag")
	if tag == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Tag parameter is required",
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

	resources, err := h.service.GetResourcesByTag(c.Request().Context(), tag, page, pageSize)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, resources)
}

// GetResourcesByAudience retrieves resources by target audience
func (h *handler) GetResourcesByAudience(c echo.Context) error {
	audience := c.QueryParam("audience")
	if audience == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Audience parameter is required",
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

	resources, err := h.service.GetResourcesByAudience(c.Request().Context(), audience, page, pageSize)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, resources)
}

// IncrementViewCount increments the view count for a resource
func (h *handler) IncrementViewCount(c echo.Context) error {
	resourceIDStr := c.Param("id")
	resourceID, err := strconv.Atoi(resourceIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid resource ID",
		})
	}

	err = h.service.IncrementViewCount(c.Request().Context(), resourceID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "View count updated successfully",
	})
}

// GetResourceStats retrieves resource statistics (admin only)
func (h *handler) GetResourceStats(c echo.Context) error {
	stats, err := h.service.GetResourceStats(c.Request().Context())
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, stats)
}

// GetPopularResources retrieves popular resources by view count
func (h *handler) GetPopularResources(c echo.Context) error {
	limit := 10
	if l := c.QueryParam("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 50 {
			limit = parsed
		}
	}

	resources, err := h.service.GetPopularResources(c.Request().Context(), limit)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"resources": resources,
		"total":     len(resources),
	})
}

// CreateResource creates a new resource (admin only)
func (h *handler) CreateResource(c echo.Context) error {
	var req CreateResourceRequest
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

	resource, err := h.service.CreateResource(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, resource)
}

// UpdateResource updates a resource (admin only)
func (h *handler) UpdateResource(c echo.Context) error {
	resourceIDStr := c.Param("id")
	resourceID, err := strconv.Atoi(resourceIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid resource ID",
		})
	}

	var req UpdateResourceRequest
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

	resource, err := h.service.UpdateResource(c.Request().Context(), resourceID, &req)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, resource)
}

// DeleteResource deletes a resource (admin only)
func (h *handler) DeleteResource(c echo.Context) error {
	resourceIDStr := c.Param("id")
	resourceID, err := strconv.Atoi(resourceIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid resource ID",
		})
	}

	err = h.service.DeleteResource(c.Request().Context(), resourceID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Resource deleted successfully",
	})
}

// ToggleResourceFeatured toggles the featured status of a resource (admin only)
func (h *handler) ToggleResourceFeatured(c echo.Context) error {
	resourceIDStr := c.Param("id")
	resourceID, err := strconv.Atoi(resourceIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid resource ID",
		})
	}

	err = h.service.ToggleResourceFeatured(c.Request().Context(), resourceID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "Resource featured status updated successfully",
	})
}
