package resources

import (
	"fmt"
	"time"
)

// Resource represents a mental health resource
type Resource struct {
	ID                string    `json:"id" db:"id"`
	Title             string    `json:"title" db:"title"`
	Description       string    `json:"description" db:"description"`
	Content           string    `json:"content" db:"content"`
	ResourceType      string    `json:"resource_type" db:"resource_type"`
	URL               *string   `json:"url,omitempty" db:"url"`
	Author            *string   `json:"author,omitempty" db:"author"`
	Tags              []string  `json:"tags" db:"tags"`
	TargetAudience    string    `json:"target_audience" db:"target_audience"`
	EstimatedReadTime *int      `json:"estimated_read_time,omitempty" db:"estimated_read_time"`
	IsFeatured        bool      `json:"is_featured" db:"is_featured"`
	IsActive          bool      `json:"is_active" db:"is_active"`
	ViewCount         int       `json:"view_count" db:"view_count"`
	CreatedAt         time.Time `json:"created_at" db:"created_at"`
	UpdatedAt         time.Time `json:"updated_at" db:"updated_at"`
}

// ResourceType represents valid resource types
type ResourceType string

const (
	ResourceTypeArticle      ResourceType = "article"
	ResourceTypeVideo        ResourceType = "video"
	ResourceTypePDF          ResourceType = "pdf"
	ResourceTypeExternalLink ResourceType = "external_link"
	ResourceTypeInfographic  ResourceType = "infographic"
)

// TargetAudience represents valid target audiences
type TargetAudience string

const (
	AudienceNewMothers    TargetAudience = "new_mothers"
	AudienceProfessionals TargetAudience = "professionals"
	AudienceGeneral       TargetAudience = "general"
	AudiencePartners      TargetAudience = "partners"
	AudienceFamilies      TargetAudience = "families"
)

// ListResourcesRequest represents the request for listing resources
type ListResourcesRequest struct {
	Page           int    `json:"page" validate:"min=1"`
	PageSize       int    `json:"page_size" validate:"min=1,max=100"`
	Search         string `json:"search,omitempty"`
	ResourceType   string `json:"resource_type,omitempty"`
	TargetAudience string `json:"target_audience,omitempty"`
	Tags           string `json:"tags,omitempty"`
	Featured       *bool  `json:"featured,omitempty"`
}

// CreateResourceRequest represents the request to create a new resource
type CreateResourceRequest struct {
	Title             string   `json:"title" validate:"required,min=2,max=255"`
	Description       string   `json:"description" validate:"required"`
	Content           string   `json:"content" validate:"required"`
	ResourceType      string   `json:"resource_type" validate:"required,oneof=article video pdf external_link infographic"`
	URL               *string  `json:"url,omitempty" validate:"omitempty,url"`
	Author            *string  `json:"author,omitempty" validate:"omitempty,max=255"`
	Tags              []string `json:"tags,omitempty"`
	TargetAudience    string   `json:"target_audience" validate:"required,oneof=new_mothers professionals general partners families"`
	EstimatedReadTime *int     `json:"estimated_read_time,omitempty" validate:"omitempty,min=1,max=180"`
	IsFeatured        bool     `json:"is_featured"`
}

// UpdateResourceRequest represents the request to update a resource
type UpdateResourceRequest struct {
	Title             *string  `json:"title,omitempty" validate:"omitempty,min=2,max=255"`
	Description       *string  `json:"description,omitempty"`
	Content           *string  `json:"content,omitempty"`
	ResourceType      *string  `json:"resource_type,omitempty" validate:"omitempty,oneof=article video pdf external_link infographic"`
	URL               *string  `json:"url,omitempty" validate:"omitempty,url"`
	Author            *string  `json:"author,omitempty" validate:"omitempty,max=255"`
	Tags              []string `json:"tags,omitempty"`
	TargetAudience    *string  `json:"target_audience,omitempty" validate:"omitempty,oneof=new_mothers professionals general partners families"`
	EstimatedReadTime *int     `json:"estimated_read_time,omitempty" validate:"omitempty,min=1,max=180"`
	IsFeatured        *bool    `json:"is_featured,omitempty"`
}

// ListResourcesResponse represents the response for listing resources
type ListResourcesResponse struct {
	Resources  []Resource `json:"resources"`
	Total      int64      `json:"total"`
	Page       int        `json:"page"`
	PageSize   int        `json:"page_size"`
	TotalPages int        `json:"total_pages"`
}

// ResourceStats represents resource statistics
type ResourceStats struct {
	TotalResources      int64            `json:"total_resources"`
	FeaturedResources   int64            `json:"featured_resources"`
	ResourcesByType     map[string]int64 `json:"resources_by_type"`
	ResourcesByAudience map[string]int64 `json:"resources_by_audience"`
	TotalViews          int64            `json:"total_views"`
	PopularTags         []TagCount       `json:"popular_tags"`
}

// TagCount represents tag usage statistics
type TagCount struct {
	Tag   string `json:"tag"`
	Count int64  `json:"count"`
}

// Helper methods for Resource model
func (r *Resource) GetDisplayAudience() string {
	switch TargetAudience(r.TargetAudience) {
	case AudienceNewMothers:
		return "New Mothers"
	case AudienceProfessionals:
		return "Professionals"
	case AudienceGeneral:
		return "General"
	case AudiencePartners:
		return "Partners"
	case AudienceFamilies:
		return "Families"
	default:
		return r.TargetAudience
	}
}

func (r *Resource) GetDisplayType() string {
	switch ResourceType(r.ResourceType) {
	case ResourceTypeArticle:
		return "Article"
	case ResourceTypeVideo:
		return "Video"
	case ResourceTypePDF:
		return "PDF"
	case ResourceTypeExternalLink:
		return "External Link"
	case ResourceTypeInfographic:
		return "Infographic"
	default:
		return r.ResourceType
	}
}

func (r *Resource) GetShortDescription() string {
	if len(r.Description) <= 150 {
		return r.Description
	}
	return r.Description[:147] + "..."
}

func (r *Resource) HasURL() bool {
	return r.URL != nil && *r.URL != ""
}

func (r *Resource) GetEstimatedReadTimeText() string {
	if r.EstimatedReadTime == nil {
		return ""
	}
	if *r.EstimatedReadTime == 1 {
		return "1 min read"
	}
	return fmt.Sprintf("%d mins read", *r.EstimatedReadTime)
}
