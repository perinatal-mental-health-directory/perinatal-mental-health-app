package services

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

// ListServices retrieves a paginated list of services
func (h *Handler) ListServices(c echo.Context) error {
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

	serviceType := c.QueryParam("service_type")
	location := c.QueryParam("location")
	nhsReferral := c.QueryParam("nhs_referral") == "true"

	services, err := h.service.ListServices(c.Request().Context(), page, pageSize, serviceType, location, nhsReferral)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, services)
}

// GetService retrieves a service by ID
func (h *Handler) GetService(c echo.Context) error {
	serviceIDStr := c.Param("id")
	serviceID, err := strconv.Atoi(serviceIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid service ID",
		})
	}

	service, err := h.service.GetService(c.Request().Context(), serviceID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, service)
}

// CreateService creates a new service (admin only)
func (h *Handler) CreateService(c echo.Context) error {
	var req CreateServiceRequest
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

	service, err := h.service.CreateService(c.Request().Context(), &req)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusCreated, service)
}

// UpdateService updates a service (admin only)
func (h *Handler) UpdateService(c echo.Context) error {
	serviceIDStr := c.Param("id")
	serviceID, err := strconv.Atoi(serviceIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid service ID",
		})
	}

	var req UpdateServiceRequest
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

	service, err := h.service.UpdateService(c.Request().Context(), serviceID, &req)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, service)
}

// DeleteService deactivates a service (admin only)
func (h *Handler) DeleteService(c echo.Context) error {
	serviceIDStr := c.Param("id")
	serviceID, err := strconv.Atoi(serviceIDStr)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"error": "Invalid service ID",
		})
	}

	err = h.service.DeleteService(c.Request().Context(), serviceID)
	if err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{
			"error": err.Error(),
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message": "ServicesModel deactivated successfully",
	})
}
