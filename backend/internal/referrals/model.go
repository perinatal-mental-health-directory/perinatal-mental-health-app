package referrals

import (
	"time"
)

// Referral represents a patient referral
type Referral struct {
	ID          int       `json:"id" db:"id"`
	UserID      string    `json:"user_id" db:"user_id"`
	PatientName string    `json:"patient_name" db:"patient_name"`
	Contact     string    `json:"contact" db:"contact"`
	Reason      string    `json:"reason" db:"reason"`
	ServiceType string    `json:"service_type" db:"service_type"`
	IsUrgent    bool      `json:"is_urgent" db:"is_urgent"`
	Status      string    `json:"status" db:"status"`
	ServiceID   *int      `json:"service_id,omitempty" db:"service_id"`
	Notes       *string   `json:"notes,omitempty" db:"notes"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// ReferralStatus represents valid referral statuses
type ReferralStatus string

const (
	StatusPending   ReferralStatus = "pending"
	StatusAccepted  ReferralStatus = "accepted"
	StatusRejected  ReferralStatus = "rejected"
	StatusCompleted ReferralStatus = "completed"
	StatusCancelled ReferralStatus = "cancelled"
)

// CreateReferralRequest represents the request to create a referral
type CreateReferralRequest struct {
	PatientName string `json:"patient_name" validate:"required,min=2,max=100"`
	Contact     string `json:"contact" validate:"required"`
	Reason      string `json:"reason" validate:"required,min=10,max=500"`
	ServiceType string `json:"service_type" validate:"required"`
	IsUrgent    bool   `json:"is_urgent"`
	ServiceID   *int   `json:"service_id,omitempty"`
}

// UpdateReferralRequest represents the request to update a referral
type UpdateReferralRequest struct {
	Status *string `json:"status,omitempty"`
	Notes  *string `json:"notes,omitempty"`
}

// ListReferralsResponse represents the response for listing referrals
type ListReferralsResponse struct {
	Referrals  []Referral `json:"referrals"`
	Total      int64      `json:"total"`
	Page       int        `json:"page"`
	PageSize   int        `json:"page_size"`
	TotalPages int        `json:"total_pages"`
}

// ReferralStats represents referral statistics
type ReferralStats struct {
	TotalReferrals   int64            `json:"total_referrals"`
	UrgentReferrals  int64            `json:"urgent_referrals"`
	StatusBreakdown  map[string]int64 `json:"status_breakdown"`
	ServiceBreakdown map[string]int64 `json:"service_breakdown"`
}
