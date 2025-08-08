package services

import (
	"time"
)

// ServicesModel represents a mental health service
type ServicesModel struct {
	ID               int       `json:"id" db:"id"`
	Name             string    `json:"name" db:"name"`
	ContactEmail     string    `json:"contact_email" db:"contact_email"`
	ContactPhone     string    `json:"contact_phone" db:"contact_phone"`
	Location         string    `json:"location" db:"location"`
	Hours            string    `json:"hours" db:"hours"`
	Overview         string    `json:"overview" db:"overview"`
	NHSReferral      bool      `json:"nhs_referral" db:"nhs_referral"`
	AcceptsReferrals bool      `json:"accepts_referrals" db:"accepts_referrals"`
	ServiceType      string    `json:"service_type" db:"service_type"`
	IsActive         bool      `json:"is_active" db:"is_active"`
	CreatedAt        time.Time `json:"created_at" db:"created_at"`
	UpdatedAt        time.Time `json:"updated_at" db:"updated_at"`
}

// ServiceCategory represents service categories
type ServiceCategory struct {
	ID          int       `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	Description string    `json:"description" db:"description"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// CreateServiceRequest represents the request to create a new service
type CreateServiceRequest struct {
	Name             string `json:"name" validate:"required,min=2,max=200"`
	ContactEmail     string `json:"contact_email" validate:"required,email"`
	ContactPhone     string `json:"contact_phone" validate:"required"`
	Location         string `json:"location" validate:"required"`
	Hours            string `json:"hours" validate:"required"`
	Overview         string `json:"overview" validate:"required"`
	NHSReferral      bool   `json:"nhs_referral"`
	AcceptsReferrals bool   `json:"accepts_referrals"`
	ServiceType      string `json:"service_type" validate:"required"`
}

// UpdateServiceRequest represents the request to update a service
type UpdateServiceRequest struct {
	Name             *string `json:"name,omitempty" validate:"omitempty,min=2,max=200"`
	ContactEmail     *string `json:"contact_email,omitempty" validate:"omitempty,email"`
	ContactPhone     *string `json:"contact_phone,omitempty"`
	Location         *string `json:"location,omitempty"`
	Hours            *string `json:"hours,omitempty"`
	Overview         *string `json:"overview,omitempty"`
	NHSReferral      *bool   `json:"nhs_referral,omitempty"`
	AcceptsReferrals *bool   `json:"accepts_referrals,omitempty"`
	ServiceType      *string `json:"service_type,omitempty"`
}

// ListServicesResponse represents the response for listing services
type ListServicesResponse struct {
	Services   []ServicesModel `json:"services"`
	Total      int64           `json:"total"`
	Page       int             `json:"page"`
	PageSize   int             `json:"page_size"`
	TotalPages int             `json:"total_pages"`
}
