package services

import (
	"context"
	"fmt"
	"strings"
)

type Service struct {
	store *Store
}

func NewService(store *Store) *Service {
	return &Service{
		store: store,
	}
}

// ListServices retrieves a paginated list of services
func (s *Service) ListServices(ctx context.Context, page, pageSize int, serviceType, location string, nhsReferral bool) (*ListServicesResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	// Validate service type if provided
	if serviceType != "" && !isValidServiceType(serviceType) {
		return nil, fmt.Errorf("invalid service type: %s", serviceType)
	}

	return s.store.ListServices(ctx, page, pageSize, serviceType, location, nhsReferral)
}

// GetService retrieves a service by ID
func (s *Service) GetService(ctx context.Context, serviceID int) (*ServicesModel, error) {
	return s.store.GetServiceByID(ctx, serviceID)
}

// CreateService creates a new service
func (s *Service) CreateService(ctx context.Context, req *CreateServiceRequest) (*ServicesModel, error) {
	// Validate service type
	if !isValidServiceType(req.ServiceType) {
		return nil, fmt.Errorf("invalid service type: %s", req.ServiceType)
	}

	// Additional validation
	if err := validateServiceRequest(req); err != nil {
		return nil, err
	}

	return s.store.CreateService(ctx, req)
}

// UpdateService updates a service
func (s *Service) UpdateService(ctx context.Context, serviceID int, req *UpdateServiceRequest) (*ServicesModel, error) {
	// Validate service type if provided
	if req.ServiceType != nil && !isValidServiceType(*req.ServiceType) {
		return nil, fmt.Errorf("invalid service type: %s", *req.ServiceType)
	}

	return s.store.UpdateService(ctx, serviceID, req)
}

// DeleteService deactivates a service
func (s *Service) DeleteService(ctx context.Context, serviceID int) error {
	return s.store.DeactivateService(ctx, serviceID)
}

// SearchServices searches for services by query
func (s *Service) SearchServices(ctx context.Context, query string, page, pageSize int) (*ListServicesResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	// Clean and validate search query
	query = strings.TrimSpace(query)
	if query == "" {
		return nil, fmt.Errorf("search query cannot be empty")
	}

	if len(query) < 2 {
		return nil, fmt.Errorf("search query must be at least 2 characters long")
	}

	return s.store.SearchServices(ctx, query, page, pageSize)
}

// GetServiceStats retrieves service statistics
func (s *Service) GetServiceStats(ctx context.Context) (*ServiceStats, error) {
	return s.store.GetServiceStats(ctx)
}

// GetFeaturedServices retrieves a limited number of featured services
func (s *Service) GetFeaturedServices(ctx context.Context, limit int) (*ListServicesResponse, error) {
	if limit < 1 {
		limit = 5
	}
	if limit > 20 {
		limit = 20
	}

	// For now, just return the most recent services as "featured"
	// In the future, you might want to add a "is_featured" field to the database
	return s.store.ListServices(ctx, 1, limit, "", "", false)
}

// Helper functions

// isValidServiceType validates service type
func isValidServiceType(serviceType string) bool {
	validTypes := []string{"online", "in_person", "hybrid"}
	for _, validType := range validTypes {
		if serviceType == validType {
			return true
		}
	}
	return false
}

// validateServiceRequest performs additional validation on service requests
func validateServiceRequest(req *CreateServiceRequest) error {
	// Validate required fields
	if strings.TrimSpace(req.Name) == "" {
		return fmt.Errorf("service name is required")
	}

	if strings.TrimSpace(req.Description) == "" {
		return fmt.Errorf("service description is required")
	}

	if strings.TrimSpace(req.ProviderName) == "" {
		return fmt.Errorf("provider name is required")
	}

	// Validate name length
	if len(req.Name) > 255 {
		return fmt.Errorf("service name cannot exceed 255 characters")
	}

	if len(req.ProviderName) > 255 {
		return fmt.Errorf("provider name cannot exceed 255 characters")
	}

	// Validate contact information - at least one contact method should be provided
	hasContact := false
	if req.ContactEmail != nil && strings.TrimSpace(*req.ContactEmail) != "" {
		hasContact = true
	}
	if req.ContactPhone != nil && strings.TrimSpace(*req.ContactPhone) != "" {
		hasContact = true
	}
	if req.WebsiteURL != nil && strings.TrimSpace(*req.WebsiteURL) != "" {
		hasContact = true
	}

	if !hasContact {
		return fmt.Errorf("at least one contact method (email, phone, or website) is required")
	}

	return nil
}

// GetServicesByType retrieves services filtered by type
func (s *Service) GetServicesByType(ctx context.Context, serviceType string, page, pageSize int) (*ListServicesResponse, error) {
	if !isValidServiceType(serviceType) {
		return nil, fmt.Errorf("invalid service type: %s", serviceType)
	}

	return s.store.ListServices(ctx, page, pageSize, serviceType, "", false)
}
