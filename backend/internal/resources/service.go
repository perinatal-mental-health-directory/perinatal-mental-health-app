package resources

import (
	"context"
	"fmt"
	"strings"
)

type service struct {
	store Store
}

func NewService(store Store) Service {
	return &service{
		store: store,
	}
}

// ListResources retrieves a paginated list of resources
func (s *service) ListResources(ctx context.Context, req *ListResourcesRequest) (*ListResourcesResponse, error) {
	if req.Page < 1 {
		req.Page = 1
	}
	if req.PageSize < 1 || req.PageSize > 100 {
		req.PageSize = 20
	}

	// Validate resource type if provided
	if req.ResourceType != "" && !isValidResourceType(req.ResourceType) {
		return nil, fmt.Errorf("invalid resource type: %s", req.ResourceType)
	}

	// Validate target audience if provided
	if req.TargetAudience != "" && !isValidTargetAudience(req.TargetAudience) {
		return nil, fmt.Errorf("invalid target audience: %s", req.TargetAudience)
	}

	return s.store.ListResources(ctx, req)
}

// GetResource retrieves a resource by ID (string UUID)
func (s *service) GetResource(ctx context.Context, resourceID string) (*Resource, error) {
	if resourceID == "" {
		return nil, fmt.Errorf("invalid resource ID")
	}

	return s.store.GetResourceByID(ctx, resourceID)
}

// GetFeaturedResources retrieves featured resources
func (s *service) GetFeaturedResources(ctx context.Context, limit int) ([]Resource, error) {
	if limit <= 0 {
		limit = 6
	}
	if limit > 20 {
		limit = 20
	}

	return s.store.GetFeaturedResources(ctx, limit)
}

// SearchResources searches for resources by query
func (s *service) SearchResources(ctx context.Context, query string, page, pageSize int) (*ListResourcesResponse, error) {
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

	return s.store.SearchResources(ctx, query, page, pageSize)
}

// IncrementViewCount increments the view count for a resource
func (s *service) IncrementViewCount(ctx context.Context, resourceID string) error {
	if resourceID == "" {
		return fmt.Errorf("invalid resource ID")
	}

	return s.store.IncrementViewCount(ctx, resourceID)
}

// GetResourcesByTag retrieves resources by tag
func (s *service) GetResourcesByTag(ctx context.Context, tag string, page, pageSize int) (*ListResourcesResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	tag = strings.TrimSpace(tag)
	if tag == "" {
		return nil, fmt.Errorf("tag cannot be empty")
	}

	return s.store.GetResourcesByTag(ctx, tag, page, pageSize)
}

// GetResourcesByAudience retrieves resources by target audience
func (s *service) GetResourcesByAudience(ctx context.Context, audience string, page, pageSize int) (*ListResourcesResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	if !isValidTargetAudience(audience) {
		return nil, fmt.Errorf("invalid target audience: %s", audience)
	}

	return s.store.GetResourcesByAudience(ctx, audience, page, pageSize)
}

// GetResourceStats retrieves resource statistics
func (s *service) GetResourceStats(ctx context.Context) (*ResourceStats, error) {
	return s.store.GetResourceStats(ctx)
}

// GetPopularResources retrieves popular resources by view count
func (s *service) GetPopularResources(ctx context.Context, limit int) ([]Resource, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	return s.store.GetPopularResources(ctx, limit)
}

// CreateResource creates a new resource (admin only)
func (s *service) CreateResource(ctx context.Context, req *CreateResourceRequest) (*Resource, error) {
	// Validate resource type
	if !isValidResourceType(req.ResourceType) {
		return nil, fmt.Errorf("invalid resource type: %s", req.ResourceType)
	}

	// Validate target audience
	if !isValidTargetAudience(req.TargetAudience) {
		return nil, fmt.Errorf("invalid target audience: %s", req.TargetAudience)
	}

	// Additional validation
	if err := validateResourceRequest(req); err != nil {
		return nil, err
	}

	return s.store.CreateResource(ctx, req)
}

// UpdateResource updates a resource (admin only)
func (s *service) UpdateResource(ctx context.Context, resourceID string, req *UpdateResourceRequest) (*Resource, error) {
	if resourceID == "" {
		return nil, fmt.Errorf("invalid resource ID")
	}

	// Validate resource type if provided
	if req.ResourceType != nil && !isValidResourceType(*req.ResourceType) {
		return nil, fmt.Errorf("invalid resource type: %s", *req.ResourceType)
	}

	// Validate target audience if provided
	if req.TargetAudience != nil && !isValidTargetAudience(*req.TargetAudience) {
		return nil, fmt.Errorf("invalid target audience: %s", *req.TargetAudience)
	}

	return s.store.UpdateResource(ctx, resourceID, req)
}

// DeleteResource soft deletes a resource (admin only)
func (s *service) DeleteResource(ctx context.Context, resourceID string) error {
	if resourceID == "" {
		return fmt.Errorf("invalid resource ID")
	}

	return s.store.DeleteResource(ctx, resourceID)
}

// ToggleResourceFeatured toggles the featured status of a resource (admin only)
func (s *service) ToggleResourceFeatured(ctx context.Context, resourceID string) error {
	if resourceID == "" {
		return fmt.Errorf("invalid resource ID")
	}

	return s.store.ToggleResourceFeatured(ctx, resourceID)
}

// Helper functions

// isValidResourceType validates resource type
func isValidResourceType(resourceType string) bool {
	validTypes := []string{"article", "video", "pdf", "external_link", "infographic"}
	for _, validType := range validTypes {
		if resourceType == validType {
			return true
		}
	}
	return false
}

// isValidTargetAudience validates target audience
func isValidTargetAudience(audience string) bool {
	validAudiences := []string{"new_mothers", "professionals", "general", "partners", "families"}
	for _, validAudience := range validAudiences {
		if audience == validAudience {
			return true
		}
	}
	return false
}

// validateResourceRequest performs additional validation on resource requests
func validateResourceRequest(req *CreateResourceRequest) error {
	// Validate required fields
	if strings.TrimSpace(req.Title) == "" {
		return fmt.Errorf("resource title is required")
	}

	if strings.TrimSpace(req.Description) == "" {
		return fmt.Errorf("resource description is required")
	}

	if strings.TrimSpace(req.Content) == "" {
		return fmt.Errorf("resource content is required")
	}

	// Validate title length
	if len(req.Title) > 255 {
		return fmt.Errorf("resource title cannot exceed 255 characters")
	}

	// Validate URL if provided
	if req.URL != nil && strings.TrimSpace(*req.URL) != "" {
		// Basic URL validation (the struct tag validation should handle this too)
		if !strings.HasPrefix(*req.URL, "http://") && !strings.HasPrefix(*req.URL, "https://") {
			return fmt.Errorf("URL must be a valid HTTP or HTTPS URL")
		}
	}

	// For external_link type, URL is required
	if req.ResourceType == "external_link" && (req.URL == nil || strings.TrimSpace(*req.URL) == "") {
		return fmt.Errorf("URL is required for external_link resource type")
	}

	// Validate estimated read time
	if req.EstimatedReadTime != nil && *req.EstimatedReadTime <= 0 {
		return fmt.Errorf("estimated read time must be greater than 0")
	}

	// Validate tags
	if len(req.Tags) > 10 {
		return fmt.Errorf("cannot have more than 10 tags")
	}

	for _, tag := range req.Tags {
		if strings.TrimSpace(tag) == "" {
			return fmt.Errorf("tags cannot be empty")
		}
		if len(tag) > 50 {
			return fmt.Errorf("tag '%s' is too long (max 50 characters)", tag)
		}
	}

	return nil
}
