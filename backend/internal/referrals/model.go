package referrals

import (
	"time"
)

// Referral represents a referral in the system
type Referral struct {
	ID           string    `json:"id" db:"id"`
	ReferredBy   string    `json:"referred_by" db:"referred_by"`     // Professional/NHS staff user ID
	ReferredTo   string    `json:"referred_to" db:"referred_to"`     // Parent user ID
	ReferralType string    `json:"referral_type" db:"referral_type"` // 'service', 'resource', 'support_group'
	ItemID       string    `json:"item_id" db:"item_id"`             // ID of the service/resource/support group
	Reason       string    `json:"reason" db:"reason"`
	Status       string    `json:"status" db:"status"` // 'pending', 'accepted', 'declined', 'viewed'
	IsUrgent     bool      `json:"is_urgent" db:"is_urgent"`
	Metadata     *string   `json:"metadata,omitempty" db:"metadata"` // JSON string for additional data
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
	UpdatedAt    time.Time `json:"updated_at" db:"updated_at"`

	// Additional fields for API responses (populated via JOINs)
	ReferrerName    *string `json:"referrer_name,omitempty" db:"referrer_name"`
	RecipientName   *string `json:"recipient_name,omitempty" db:"recipient_name"`
	ItemTitle       *string `json:"item_title,omitempty" db:"item_title"`
	ItemDescription *string `json:"item_description,omitempty" db:"item_description"`
}

// ReferralStatus represents valid referral statuses
type ReferralStatus string

const (
	StatusPending  ReferralStatus = "pending"
	StatusAccepted ReferralStatus = "accepted"
	StatusDeclined ReferralStatus = "declined"
	StatusViewed   ReferralStatus = "viewed"
)

// ReferralType represents valid referral types
type ReferralType string

const (
	TypeService      ReferralType = "service"
	TypeResource     ReferralType = "resource"
	TypeSupportGroup ReferralType = "support_group"
)

// CreateReferralRequest represents the request to create a new referral
type CreateReferralRequest struct {
	ReferredTo   string                 `json:"referred_to" validate:"required"`
	ReferralType string                 `json:"referral_type" validate:"required,oneof=service resource support_group"`
	ItemID       string                 `json:"item_id" validate:"required"`
	Reason       string                 `json:"reason" validate:"required,min=10,max=1000"`
	IsUrgent     bool                   `json:"is_urgent"`
	Metadata     map[string]interface{} `json:"metadata,omitempty"`
}

// UpdateReferralRequest represents the request to update a referral
type UpdateReferralRequest struct {
	Status   *string                `json:"status,omitempty" validate:"omitempty,oneof=pending accepted declined viewed"`
	Reason   *string                `json:"reason,omitempty" validate:"omitempty,min=10,max=1000"`
	IsUrgent *bool                  `json:"is_urgent,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// ListReferralsRequest represents the request for listing referrals
type ListReferralsRequest struct {
	Page         int    `json:"page" validate:"min=1"`
	PageSize     int    `json:"page_size" validate:"min=1,max=100"`
	Status       string `json:"status,omitempty"`
	ReferralType string `json:"referral_type,omitempty"`
	IsUrgent     *bool  `json:"is_urgent,omitempty"`
}

// ListReferralsResponse represents the response for listing referrals
type ListReferralsResponse struct {
	Referrals  []Referral `json:"referrals"`
	Total      int64      `json:"total"`
	Page       int        `json:"page"`
	PageSize   int        `json:"page_size"`
	TotalPages int        `json:"total_pages"`
}

// UserSearchRequest represents the request for searching users
type UserSearchRequest struct {
	Query string `json:"query" validate:"required,min=3"`
	Role  string `json:"role,omitempty"`
	Limit int    `json:"limit" validate:"min=1,max=50"`
}

// UserSearchResult represents a user in search results
type UserSearchResult struct {
	ID          string    `json:"id" db:"id"`
	FullName    string    `json:"full_name" db:"full_name"`
	Email       string    `json:"email" db:"email"`
	Role        string    `json:"role" db:"role"`
	PhoneNumber *string   `json:"phone_number,omitempty" db:"phone_number"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// UserSearchResponse represents the response for user search
type UserSearchResponse struct {
	Users []UserSearchResult `json:"users"`
	Total int64              `json:"total"`
	Query string             `json:"query"`
}

// ReferralStats represents referral statistics
type ReferralStats struct {
	TotalReferrals      int64            `json:"total_referrals"`
	PendingReferrals    int64            `json:"pending_referrals"`
	AcceptedReferrals   int64            `json:"accepted_referrals"`
	DeclinedReferrals   int64            `json:"declined_referrals"`
	UrgentReferrals     int64            `json:"urgent_referrals"`
	ReferralsByType     map[string]int64 `json:"referrals_by_type"`
	ReferralsByStatus   map[string]int64 `json:"referrals_by_status"`
	RecentReferrals     []Referral       `json:"recent_referrals"`
	TopReferrers        []ReferrerStats  `json:"top_referrers"`
	AcceptanceRate      float64          `json:"acceptance_rate"`
	AverageResponseTime float64          `json:"average_response_time_hours"`
}

// ReferrerStats represents statistics for individual referrers
type ReferrerStats struct {
	ReferrerID   string `json:"referrer_id" db:"referrer_id"`
	ReferrerName string `json:"referrer_name" db:"referrer_name"`
	TotalSent    int64  `json:"total_sent" db:"total_sent"`
	Accepted     int64  `json:"accepted" db:"accepted"`
	Declined     int64  `json:"declined" db:"declined"`
	Pending      int64  `json:"pending" db:"pending"`
}

// Helper methods for Referral model
func (r *Referral) GetDisplayStatus() string {
	switch ReferralStatus(r.Status) {
	case StatusPending:
		return "Pending"
	case StatusAccepted:
		return "Accepted"
	case StatusDeclined:
		return "Declined"
	case StatusViewed:
		return "Viewed"
	default:
		return r.Status
	}
}

func (r *Referral) GetDisplayType() string {
	switch ReferralType(r.ReferralType) {
	case TypeService:
		return "Service"
	case TypeResource:
		return "Resource"
	case TypeSupportGroup:
		return "Support Group"
	default:
		return r.ReferralType
	}
}

func (r *Referral) IsPending() bool {
	return r.Status == string(StatusPending)
}

func (r *Referral) IsAccepted() bool {
	return r.Status == string(StatusAccepted)
}

func (r *Referral) IsDeclined() bool {
	return r.Status == string(StatusDeclined)
}

func (r *Referral) IsViewed() bool {
	return r.Status == string(StatusViewed)
}

func (r *Referral) CanBeUpdatedBy(userID string) bool {
	// Only the recipient can update status, and only the referrer can update other fields
	return r.ReferredTo == userID || r.ReferredBy == userID
}

func (r *Referral) CanViewDetails(userID string) bool {
	// Both referrer and recipient can view details
	return r.ReferredTo == userID || r.ReferredBy == userID
}
