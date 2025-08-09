package services

import (
	"time"
)

// ServicesModel represents a mental health service
type ServicesModel struct {
	ID                  string    `json:"id" db:"id"`
	Name                string    `json:"name" db:"name"`
	Description         string    `json:"description" db:"description"`
	ProviderName        string    `json:"provider_name" db:"provider_name"`
	ContactEmail        *string   `json:"contact_email,omitempty" db:"contact_email"`
	ContactPhone        *string   `json:"contact_phone,omitempty" db:"contact_phone"`
	WebsiteURL          *string   `json:"website_url,omitempty" db:"website_url"`
	Address             *string   `json:"address,omitempty" db:"address"`
	ServiceType         string    `json:"service_type" db:"service_type"`
	AvailabilityHours   string    `json:"availability_hours,omitempty" db:"availability_hours"`
	EligibilityCriteria *string   `json:"eligibility_criteria,omitempty" db:"eligibility_criteria"`
	IsActive            bool      `json:"is_active" db:"is_active"`
	CreatedAt           time.Time `json:"created_at" db:"created_at"`
	UpdatedAt           time.Time `json:"updated_at" db:"updated_at"`
}

// CreateServiceRequest represents the request to create a new service
type CreateServiceRequest struct {
	Name                string  `json:"name" validate:"required,min=2,max=255"`
	Description         string  `json:"description" validate:"required"`
	ProviderName        string  `json:"provider_name" validate:"required,min=2,max=255"`
	ContactEmail        *string `json:"contact_email,omitempty" validate:"omitempty,email"`
	ContactPhone        *string `json:"contact_phone,omitempty"`
	WebsiteURL          *string `json:"website_url,omitempty" validate:"omitempty,url"`
	Address             *string `json:"address,omitempty"`
	ServiceType         string  `json:"service_type" validate:"required,oneof=online in_person hybrid"`
	EligibilityCriteria *string `json:"eligibility_criteria,omitempty"`
}

// UpdateServiceRequest represents the request to update a service
type UpdateServiceRequest struct {
	Name                *string `json:"name,omitempty" validate:"omitempty,min=2,max=255"`
	Description         *string `json:"description,omitempty"`
	ProviderName        *string `json:"provider_name,omitempty" validate:"omitempty,min=2,max=255"`
	ContactEmail        *string `json:"contact_email,omitempty" validate:"omitempty,email"`
	ContactPhone        *string `json:"contact_phone,omitempty"`
	WebsiteURL          *string `json:"website_url,omitempty" validate:"omitempty,url"`
	Address             *string `json:"address,omitempty"`
	ServiceType         *string `json:"service_type,omitempty" validate:"omitempty,oneof=online in_person hybrid"`
	EligibilityCriteria *string `json:"eligibility_criteria,omitempty"`
}

// ListServicesResponse represents the response for listing services
type ListServicesResponse struct {
	Services   []ServicesModel `json:"services"`
	Total      int64           `json:"total"`
	Page       int             `json:"page"`
	PageSize   int             `json:"page_size"`
	TotalPages int             `json:"total_pages"`
}

// SearchServicesRequest represents the request for searching services
type SearchServicesRequest struct {
	Query       string `json:"query" validate:"required,min=1"`
	Page        int    `json:"page" validate:"min=1"`
	PageSize    int    `json:"page_size" validate:"min=1,max=100"`
	ServiceType string `json:"service_type,omitempty" validate:"omitempty,oneof=online in_person hybrid"`
	Location    string `json:"location,omitempty"`
}

// ServiceStats represents service statistics
type ServiceStats struct {
	TotalServices    int64            `json:"total_services"`
	ActiveServices   int64            `json:"active_services"`
	InactiveServices int64            `json:"inactive_services"`
	ServicesByType   map[string]int64 `json:"services_by_type"`
}
