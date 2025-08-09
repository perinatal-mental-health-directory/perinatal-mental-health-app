package services

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Store struct {
	db *pgxpool.Pool
}

func NewStore(db *pgxpool.Pool) *Store {
	return &Store{
		db: db,
	}
}

// ListServices retrieves a paginated list of services with filtering
func (s *Store) ListServices(ctx context.Context, page, pageSize int, serviceType, location string, nhsReferral bool) (*ListServicesResponse, error) {
	offset := (page - 1) * pageSize

	var whereClause []string
	var args []interface{}
	argIndex := 1

	// Always filter for active services
	whereClause = append(whereClause, "is_active = true")

	// Add service type filter
	if serviceType != "" {
		whereClause = append(whereClause, fmt.Sprintf("service_type = $%d", argIndex))
		args = append(args, serviceType)
		argIndex++
	}

	// Add location filter (search in address field)
	if location != "" {
		whereClause = append(whereClause, fmt.Sprintf("address ILIKE $%d", argIndex))
		args = append(args, "%"+location+"%")
		argIndex++
	}

	// Build WHERE clause
	whereSQL := ""
	if len(whereClause) > 0 {
		whereSQL = "WHERE " + strings.Join(whereClause, " AND ")
	}

	// Count total services
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*) 
		FROM services 
		%s
	`, whereSQL)

	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count services: %w", err)
	}

	// Get services with pagination
	query := fmt.Sprintf(`
		SELECT id, name, description, provider_name, contact_email, contact_phone, 
			   website_url, address, service_type, availability_hours, eligibility_criteria,
			   is_active, created_at, updated_at
		FROM services
		%s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereSQL, argIndex, argIndex+1)

	args = append(args, pageSize, offset)

	rows, err := s.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query services: %w", err)
	}
	defer rows.Close()

	var services []ServicesModel
	for rows.Next() {
		var service ServicesModel
		var availabilityHours *string

		err := rows.Scan(
			&service.ID,
			&service.Name,
			&service.Description,
			&service.ProviderName,
			&service.ContactEmail,
			&service.ContactPhone,
			&service.WebsiteURL,
			&service.Address,
			&service.ServiceType,
			&availabilityHours,
			&service.EligibilityCriteria,
			&service.IsActive,
			&service.CreatedAt,
			&service.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan service: %w", err)
		}

		// Handle availability hours
		if availabilityHours != nil {
			service.AvailabilityHours = *availabilityHours
		}

		services = append(services, service)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))

	return &ListServicesResponse{
		Services:   services,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
	}, nil
}

// GetServiceByID retrieves a service by ID - Fixed to handle UUID properly
func (s *Store) GetServiceByID(ctx context.Context, serviceID int) (*ServicesModel, error) {
	// Note: This method signature expects int but our ID is UUID string
	// This might be causing issues. Let's create a proper UUID version
	return nil, fmt.Errorf("GetServiceByID with int ID is deprecated, use GetServiceByUUID instead")
}

// GetServiceByUUID retrieves a service by UUID string
func (s *Store) GetServiceByUUID(ctx context.Context, serviceID string) (*ServicesModel, error) {
	query := `
		SELECT id, name, description, provider_name, contact_email, contact_phone, 
			   website_url, address, service_type, availability_hours, eligibility_criteria,
			   is_active, created_at, updated_at
		FROM services
		WHERE id = $1 AND is_active = true
	`

	var service ServicesModel
	var availabilityHours *string

	err := s.db.QueryRow(ctx, query, serviceID).Scan(
		&service.ID,
		&service.Name,
		&service.Description,
		&service.ProviderName,
		&service.ContactEmail,
		&service.ContactPhone,
		&service.WebsiteURL,
		&service.Address,
		&service.ServiceType,
		&availabilityHours,
		&service.EligibilityCriteria,
		&service.IsActive,
		&service.CreatedAt,
		&service.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("service not found")
		}
		return nil, fmt.Errorf("failed to get service: %w", err)
	}

	// Handle availability hours
	if availabilityHours != nil {
		service.AvailabilityHours = *availabilityHours
	}

	return &service, nil
}

// CreateService creates a new service
func (s *Store) CreateService(ctx context.Context, req *CreateServiceRequest) (*ServicesModel, error) {
	serviceID := uuid.New()
	now := time.Now()

	query := `
		INSERT INTO services (id, name, description, provider_name, contact_email, contact_phone, 
							  website_url, address, service_type, availability_hours, eligibility_criteria,
							  is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		RETURNING id, name, description, provider_name, contact_email, contact_phone, 
				  website_url, address, service_type, availability_hours, eligibility_criteria,
				  is_active, created_at, updated_at
	`

	var service ServicesModel
	var availabilityHours *string

	err := s.db.QueryRow(ctx, query,
		serviceID,
		req.Name,
		req.Description,
		req.ProviderName,
		req.ContactEmail,
		req.ContactPhone,
		req.WebsiteURL,
		req.Address,
		req.ServiceType,
		nil, // availability_hours (JSON)
		req.EligibilityCriteria,
		true, // is_active
		now,  // created_at
		now,  // updated_at
	).Scan(
		&service.ID,
		&service.Name,
		&service.Description,
		&service.ProviderName,
		&service.ContactEmail,
		&service.ContactPhone,
		&service.WebsiteURL,
		&service.Address,
		&service.ServiceType,
		&availabilityHours,
		&service.EligibilityCriteria,
		&service.IsActive,
		&service.CreatedAt,
		&service.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create service: %w", err)
	}

	// Handle availability hours
	if availabilityHours != nil {
		service.AvailabilityHours = *availabilityHours
	}

	return &service, nil
}

// UpdateService updates a service - Fixed to handle UUID properly
func (s *Store) UpdateService(ctx context.Context, serviceID int, req *UpdateServiceRequest) (*ServicesModel, error) {
	// Note: This method signature expects int but our ID is UUID string
	return nil, fmt.Errorf("UpdateService with int ID is deprecated, use UpdateServiceByUUID instead")
}

// UpdateServiceByUUID updates a service by UUID
func (s *Store) UpdateServiceByUUID(ctx context.Context, serviceID string, req *UpdateServiceRequest) (*ServicesModel, error) {
	var setParts []string
	var args []interface{}
	argIndex := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argIndex))
		args = append(args, *req.Name)
		argIndex++
	}

	if req.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *req.Description)
		argIndex++
	}

	if req.ProviderName != nil {
		setParts = append(setParts, fmt.Sprintf("provider_name = $%d", argIndex))
		args = append(args, *req.ProviderName)
		argIndex++
	}

	if req.ContactEmail != nil {
		setParts = append(setParts, fmt.Sprintf("contact_email = $%d", argIndex))
		args = append(args, *req.ContactEmail)
		argIndex++
	}

	if req.ContactPhone != nil {
		setParts = append(setParts, fmt.Sprintf("contact_phone = $%d", argIndex))
		args = append(args, *req.ContactPhone)
		argIndex++
	}

	if req.WebsiteURL != nil {
		setParts = append(setParts, fmt.Sprintf("website_url = $%d", argIndex))
		args = append(args, *req.WebsiteURL)
		argIndex++
	}

	if req.Address != nil {
		setParts = append(setParts, fmt.Sprintf("address = $%d", argIndex))
		args = append(args, *req.Address)
		argIndex++
	}

	if req.ServiceType != nil {
		setParts = append(setParts, fmt.Sprintf("service_type = $%d", argIndex))
		args = append(args, *req.ServiceType)
		argIndex++
	}

	if req.EligibilityCriteria != nil {
		setParts = append(setParts, fmt.Sprintf("eligibility_criteria = $%d", argIndex))
		args = append(args, *req.EligibilityCriteria)
		argIndex++
	}

	if len(setParts) == 0 {
		return s.GetServiceByUUID(ctx, serviceID)
	}

	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	query := fmt.Sprintf(`
		UPDATE services 
		SET %s
		WHERE id = $%d AND is_active = true
		RETURNING id, name, description, provider_name, contact_email, contact_phone, 
				  website_url, address, service_type, availability_hours, eligibility_criteria,
				  is_active, created_at, updated_at
	`, strings.Join(setParts, ", "), argIndex)

	args = append(args, serviceID)

	var service ServicesModel
	var availabilityHours *string

	err := s.db.QueryRow(ctx, query, args...).Scan(
		&service.ID,
		&service.Name,
		&service.Description,
		&service.ProviderName,
		&service.ContactEmail,
		&service.ContactPhone,
		&service.WebsiteURL,
		&service.Address,
		&service.ServiceType,
		&availabilityHours,
		&service.EligibilityCriteria,
		&service.IsActive,
		&service.CreatedAt,
		&service.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("service not found")
		}
		return nil, fmt.Errorf("failed to update service: %w", err)
	}

	// Handle availability hours
	if availabilityHours != nil {
		service.AvailabilityHours = *availabilityHours
	}

	return &service, nil
}

// DeactivateService soft deletes a service - Fixed to handle UUID properly
func (s *Store) DeactivateService(ctx context.Context, serviceID int) error {
	// Note: This method signature expects int but our ID is UUID string
	return fmt.Errorf("DeactivateService with int ID is deprecated, use DeactivateServiceByUUID instead")
}

// DeactivateServiceByUUID soft deletes a service by UUID
func (s *Store) DeactivateServiceByUUID(ctx context.Context, serviceID string) error {
	query := `
		UPDATE services 
		SET is_active = false, updated_at = $1
		WHERE id = $2
	`

	result, err := s.db.Exec(ctx, query, time.Now(), serviceID)
	if err != nil {
		return fmt.Errorf("failed to deactivate service: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("service not found")
	}

	return nil
}

// SearchServices searches services by name or description
// SearchServices searches services by name, description, provider_name, or service_type
func (s *Store) SearchServices(ctx context.Context, query string, page, pageSize int) (*ListServicesResponse, error) {
	offset := (page - 1) * pageSize

	searchQuery := "%" + strings.ToLower(query) + "%"

	// Count total matching services - Updated to include service_type
	countSQL := `
		SELECT COUNT(*) 
		FROM services 
		WHERE is_active = true 
		AND (LOWER(name) LIKE $1 
		     OR LOWER(description) LIKE $1 
		     OR LOWER(provider_name) LIKE $1 
		     OR LOWER(service_type) LIKE $1)
	`

	var total int64
	err := s.db.QueryRow(ctx, countSQL, searchQuery).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count search results: %w", err)
	}

	// Get matching services - Updated to include service_type in search and ordering
	searchSQL := `
		SELECT id, name, description, provider_name, contact_email, contact_phone, 
			   website_url, address, service_type, availability_hours, eligibility_criteria,
			   is_active, created_at, updated_at
		FROM services
		WHERE is_active = true 
		AND (LOWER(name) LIKE $1 
		     OR LOWER(description) LIKE $1 
		     OR LOWER(provider_name) LIKE $1 
		     OR LOWER(service_type) LIKE $1)
		ORDER BY 
			CASE 
				WHEN LOWER(name) LIKE $1 THEN 1 
				WHEN LOWER(service_type) LIKE $1 THEN 2 
				WHEN LOWER(provider_name) LIKE $1 THEN 3 
				ELSE 4 
			END,
			created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := s.db.Query(ctx, searchSQL, searchQuery, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to search services: %w", err)
	}
	defer rows.Close()

	var services []ServicesModel
	for rows.Next() {
		var service ServicesModel
		var availabilityHours *string

		err := rows.Scan(
			&service.ID,
			&service.Name,
			&service.Description,
			&service.ProviderName,
			&service.ContactEmail,
			&service.ContactPhone,
			&service.WebsiteURL,
			&service.Address,
			&service.ServiceType,
			&availabilityHours,
			&service.EligibilityCriteria,
			&service.IsActive,
			&service.CreatedAt,
			&service.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan service: %w", err)
		}

		// Handle availability hours
		if availabilityHours != nil {
			service.AvailabilityHours = *availabilityHours
		}

		services = append(services, service)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))

	return &ListServicesResponse{
		Services:   services,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
	}, nil
}

// GetServiceStats retrieves service statistics
func (s *Store) GetServiceStats(ctx context.Context) (*ServiceStats, error) {
	// Get total services count
	var totalServices, activeServices, inactiveServices int64

	// Count all services
	err := s.db.QueryRow(ctx, "SELECT COUNT(*) FROM services").Scan(&totalServices)
	if err != nil {
		return nil, fmt.Errorf("failed to count total services: %w", err)
	}

	// Count active services
	err = s.db.QueryRow(ctx, "SELECT COUNT(*) FROM services WHERE is_active = true").Scan(&activeServices)
	if err != nil {
		return nil, fmt.Errorf("failed to count active services: %w", err)
	}

	// Count inactive services
	err = s.db.QueryRow(ctx, "SELECT COUNT(*) FROM services WHERE is_active = false").Scan(&inactiveServices)
	if err != nil {
		return nil, fmt.Errorf("failed to count inactive services: %w", err)
	}

	// Get services by type
	servicesByType := make(map[string]int64)
	rows, err := s.db.Query(ctx, `
		SELECT service_type, COUNT(*) 
		FROM services 
		WHERE is_active = true 
		GROUP BY service_type
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to get services by type: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var serviceType string
		var count int64

		err := rows.Scan(&serviceType, &count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan service type stats: %w", err)
		}

		servicesByType[serviceType] = count
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return &ServiceStats{
		TotalServices:    totalServices,
		ActiveServices:   activeServices,
		InactiveServices: inactiveServices,
		ServicesByType:   servicesByType,
	}, nil
}
