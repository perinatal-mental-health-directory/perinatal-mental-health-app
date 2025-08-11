// backend/internal/support_groups/model.go
package support_groups

import (
	"time"
)

// SupportGroup represents a support group
type SupportGroup struct {
	ID          string    `json:"id" db:"id"`
	Name        string    `json:"name" db:"name"`
	Description string    `json:"description" db:"description"`
	Category    string    `json:"category" db:"category"`
	Platform    string    `json:"platform" db:"platform"`
	DoctorInfo  *string   `json:"doctor_info,omitempty" db:"doctor_info"`
	URL         *string   `json:"url,omitempty" db:"url"`
	Guidelines  *string   `json:"guidelines,omitempty" db:"guidelines"`
	MeetingTime *string   `json:"meeting_time,omitempty" db:"meeting_time"`
	MaxMembers  *int      `json:"max_members,omitempty" db:"max_members"`
	IsActive    bool      `json:"is_active" db:"is_active"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time `json:"updated_at" db:"updated_at"`
}

// GroupCategory represents valid group categories
type GroupCategory string

const (
	CategoryPostnatal      GroupCategory = "postnatal"
	CategoryPrenatal       GroupCategory = "prenatal"
	CategoryAnxiety        GroupCategory = "anxiety"
	CategoryDepression     GroupCategory = "depression"
	CategoryPartnerSupport GroupCategory = "partner_support"
	CategoryGeneral        GroupCategory = "general"
)

// Platform represents valid platforms
type Platform string

const (
	PlatformOnline   Platform = "online"
	PlatformInPerson Platform = "in_person"
	PlatformHybrid   Platform = "hybrid"
)

// CreateSupportGroupRequest represents the request to create a support group
type CreateSupportGroupRequest struct {
	Name        string  `json:"name" validate:"required,min=2,max=255"`
	Description string  `json:"description" validate:"required"`
	Category    string  `json:"category" validate:"required,oneof=postnatal prenatal anxiety depression partner_support general"`
	Platform    string  `json:"platform" validate:"required,oneof=online in_person hybrid"`
	DoctorInfo  *string `json:"doctor_info,omitempty"`
	URL         *string `json:"url,omitempty" validate:"omitempty,url"`
	Guidelines  *string `json:"guidelines,omitempty"`
	MeetingTime *string `json:"meeting_time,omitempty"`
	MaxMembers  *int    `json:"max_members,omitempty" validate:"omitempty,min=2,max=100"`
}

// UpdateSupportGroupRequest represents the request to update a support group
type UpdateSupportGroupRequest struct {
	Name        *string `json:"name,omitempty" validate:"omitempty,min=2,max=255"`
	Description *string `json:"description,omitempty"`
	Category    *string `json:"category,omitempty" validate:"omitempty,oneof=postnatal prenatal anxiety depression partner_support general"`
	Platform    *string `json:"platform,omitempty" validate:"omitempty,oneof=online in_person hybrid"`
	DoctorInfo  *string `json:"doctor_info,omitempty"`
	URL         *string `json:"url,omitempty" validate:"omitempty,url"`
	Guidelines  *string `json:"guidelines,omitempty"`
	MeetingTime *string `json:"meeting_time,omitempty"`
	MaxMembers  *int    `json:"max_members,omitempty" validate:"omitempty,min=2,max=100"`
}

// ListSupportGroupsResponse represents the response for listing support groups
type ListSupportGroupsResponse struct {
	SupportGroups []SupportGroup `json:"support_groups"`
	Total         int64          `json:"total"`
	Page          int            `json:"page"`
	PageSize      int            `json:"page_size"`
	TotalPages    int            `json:"total_pages"`
}

// GroupMembership represents user membership in support groups
type GroupMembership struct {
	ID        string    `json:"id" db:"id"`
	UserID    string    `json:"user_id" db:"user_id"`
	GroupID   int       `json:"group_id" db:"group_id"`
	JoinedAt  time.Time `json:"joined_at" db:"joined_at"`
	IsActive  bool      `json:"is_active" db:"is_active"`
	Role      string    `json:"role" db:"role"` // "member", "moderator", "admin"
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// JoinGroupRequest represents the request to join a group
type JoinGroupRequest struct {
	GroupID string `json:"group_id" validate:"required"`
}

// SupportGroupStats represents support group statistics
type SupportGroupStats struct {
	TotalGroups      int64            `json:"total_groups"`
	ActiveGroups     int64            `json:"active_groups"`
	TotalMembers     int64            `json:"total_members"`
	GroupsByCategory map[string]int64 `json:"groups_by_category"`
	GroupsByPlatform map[string]int64 `json:"groups_by_platform"`
	PopularGroups    []SupportGroup   `json:"popular_groups"`
}

// Helper methods for SupportGroup model
func (sg *SupportGroup) GetDisplayCategory() string {
	switch GroupCategory(sg.Category) {
	case CategoryPostnatal:
		return "Postnatal Support"
	case CategoryPrenatal:
		return "Prenatal Support"
	case CategoryAnxiety:
		return "Anxiety Support"
	case CategoryDepression:
		return "Depression Support"
	case CategoryPartnerSupport:
		return "Partner Support"
	case CategoryGeneral:
		return "General Support"
	default:
		return sg.Category
	}
}

func (sg *SupportGroup) GetDisplayPlatform() string {
	switch Platform(sg.Platform) {
	case PlatformOnline:
		return "Online"
	case PlatformInPerson:
		return "In-Person"
	case PlatformHybrid:
		return "Hybrid"
	default:
		return sg.Platform
	}
}

func (sg *SupportGroup) GetShortDescription() string {
	if len(sg.Description) <= 100 {
		return sg.Description
	}
	return sg.Description[:97] + "..."
}

func (sg *SupportGroup) HasURL() bool {
	return sg.URL != nil && *sg.URL != ""
}

func (sg *SupportGroup) HasDoctorInfo() bool {
	return sg.DoctorInfo != nil && *sg.DoctorInfo != ""
}

func (sg *SupportGroup) HasGuidelines() bool {
	return sg.Guidelines != nil && *sg.Guidelines != ""
}

func (sg *SupportGroup) HasMeetingTime() bool {
	return sg.MeetingTime != nil && *sg.MeetingTime != ""
}

func (sg *SupportGroup) HasMaxMembers() bool {
	return sg.MaxMembers != nil && *sg.MaxMembers > 0
}
