package services

import (
	"context"
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

	return s.store.ListServices(ctx, page, pageSize, serviceType, location, nhsReferral)
}

// GetService retrieves a service by ID
func (s *Service) GetService(ctx context.Context, serviceID int) (*ServiceModel, error) {
	return s.store.GetServiceByID(ctx, serviceID)
}

// CreateService creates a new service
func (s *Service) CreateService(ctx context.Context, req *CreateServiceRequest) (*ServiceModel, error) {
	return s.store.CreateService(ctx, req)
}

// UpdateService updates a service
func (s *Service) UpdateService(ctx context.Context, serviceID int, req *UpdateServiceRequest) (*ServiceModel, error) {
	return s.store.UpdateService(ctx, serviceID, req)
}

// DeleteService deactivates a service
func (s *Service) DeleteService(ctx context.Context, serviceID int) error {
	return s.store.DeactivateService(ctx, serviceID)
}
