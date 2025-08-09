package resources

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/lib/pq"
)

type store struct {
	db *pgxpool.Pool
}

func NewStore(db *pgxpool.Pool) Store {
	return &store{
		db: db,
	}
}

// ListResources retrieves a paginated list of resources with filtering
func (s *store) ListResources(ctx context.Context, req *ListResourcesRequest) (*ListResourcesResponse, error) {
	offset := (req.Page - 1) * req.PageSize

	var whereClause []string
	var args []interface{}
	argIndex := 1

	// Always filter for active resources
	whereClause = append(whereClause, "is_active = true")

	// Add search filter
	if req.Search != "" {
		whereClause = append(whereClause, fmt.Sprintf("(LOWER(title) LIKE $%d OR LOWER(description) LIKE $%d OR LOWER(content) LIKE $%d)", argIndex, argIndex, argIndex))
		args = append(args, "%"+strings.ToLower(req.Search)+"%")
		argIndex++
	}

	// Add resource type filter
	if req.ResourceType != "" {
		whereClause = append(whereClause, fmt.Sprintf("resource_type = $%d", argIndex))
		args = append(args, req.ResourceType)
		argIndex++
	}

	// Add target audience filter
	if req.TargetAudience != "" {
		whereClause = append(whereClause, fmt.Sprintf("target_audience = $%d", argIndex))
		args = append(args, req.TargetAudience)
		argIndex++
	}

	// Add tags filter
	if req.Tags != "" {
		whereClause = append(whereClause, fmt.Sprintf("tags @> ARRAY[$%d]", argIndex))
		args = append(args, req.Tags)
		argIndex++
	}

	// Add featured filter
	if req.Featured != nil {
		whereClause = append(whereClause, fmt.Sprintf("is_featured = $%d", argIndex))
		args = append(args, *req.Featured)
		argIndex++
	}

	// Build WHERE clause
	whereSQL := ""
	if len(whereClause) > 0 {
		whereSQL = "WHERE " + strings.Join(whereClause, " AND ")
	}

	// Count total resources
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*) 
		FROM resources 
		%s
	`, whereSQL)

	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count resources: %w", err)
	}

	// Get resources with pagination
	query := fmt.Sprintf(`
		SELECT id, title, description, content, resource_type, url, author, tags, 
			   target_audience, estimated_read_time, is_featured, is_active, view_count,
			   created_at, updated_at
		FROM resources
		%s
		ORDER BY 
			CASE WHEN is_featured THEN 0 ELSE 1 END,
			created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereSQL, argIndex, argIndex+1)

	args = append(args, req.PageSize, offset)

	rows, err := s.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query resources: %w", err)
	}
	defer rows.Close()

	var resources []Resource
	for rows.Next() {
		var resource Resource
		err := rows.Scan(
			&resource.ID,
			&resource.Title,
			&resource.Description,
			&resource.Content,
			&resource.ResourceType,
			&resource.URL,
			&resource.Author,
			pq.Array(&resource.Tags),
			&resource.TargetAudience,
			&resource.EstimatedReadTime,
			&resource.IsFeatured,
			&resource.IsActive,
			&resource.ViewCount,
			&resource.CreatedAt,
			&resource.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan resource: %w", err)
		}

		resources = append(resources, resource)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	totalPages := int((total + int64(req.PageSize) - 1) / int64(req.PageSize))

	return &ListResourcesResponse{
		Resources:  resources,
		Total:      total,
		Page:       req.Page,
		PageSize:   req.PageSize,
		TotalPages: totalPages,
	}, nil
}

// GetResourceByID retrieves a resource by ID
func (s *store) GetResourceByID(ctx context.Context, resourceID int) (*Resource, error) {
	query := `
		SELECT id, title, description, content, resource_type, url, author, tags, 
			   target_audience, estimated_read_time, is_featured, is_active, view_count,
			   created_at, updated_at
		FROM resources
		WHERE id = $1 AND is_active = true
	`

	var resource Resource
	err := s.db.QueryRow(ctx, query, resourceID).Scan(
		&resource.ID,
		&resource.Title,
		&resource.Description,
		&resource.Content,
		&resource.ResourceType,
		&resource.URL,
		&resource.Author,
		pq.Array(&resource.Tags),
		&resource.TargetAudience,
		&resource.EstimatedReadTime,
		&resource.IsFeatured,
		&resource.IsActive,
		&resource.ViewCount,
		&resource.CreatedAt,
		&resource.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("resource not found")
		}
		return nil, fmt.Errorf("failed to get resource: %w", err)
	}

	return &resource, nil
}

// GetFeaturedResources retrieves featured resources
func (s *store) GetFeaturedResources(ctx context.Context, limit int) ([]Resource, error) {
	query := `
		SELECT id, title, description, content, resource_type, url, author, tags, 
			   target_audience, estimated_read_time, is_featured, is_active, view_count,
			   created_at, updated_at
		FROM resources
		WHERE is_active = true AND is_featured = true
		ORDER BY created_at DESC
		LIMIT $1
	`

	rows, err := s.db.Query(ctx, query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query featured resources: %w", err)
	}
	defer rows.Close()

	var resources []Resource
	for rows.Next() {
		var resource Resource
		err := rows.Scan(
			&resource.ID,
			&resource.Title,
			&resource.Description,
			&resource.Content,
			&resource.ResourceType,
			&resource.URL,
			&resource.Author,
			pq.Array(&resource.Tags),
			&resource.TargetAudience,
			&resource.EstimatedReadTime,
			&resource.IsFeatured,
			&resource.IsActive,
			&resource.ViewCount,
			&resource.CreatedAt,
			&resource.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan resource: %w", err)
		}

		resources = append(resources, resource)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return resources, nil
}

// SearchResources searches resources by query
func (s *store) SearchResources(ctx context.Context, query string, page, pageSize int) (*ListResourcesResponse, error) {
	req := &ListResourcesRequest{
		Page:     page,
		PageSize: pageSize,
		Search:   query,
	}
	return s.ListResources(ctx, req)
}

// GetResourcesByTag retrieves resources by tag
func (s *store) GetResourcesByTag(ctx context.Context, tag string, page, pageSize int) (*ListResourcesResponse, error) {
	req := &ListResourcesRequest{
		Page:     page,
		PageSize: pageSize,
		Tags:     tag,
	}
	return s.ListResources(ctx, req)
}

// GetResourcesByAudience retrieves resources by target audience
func (s *store) GetResourcesByAudience(ctx context.Context, audience string, page, pageSize int) (*ListResourcesResponse, error) {
	req := &ListResourcesRequest{
		Page:           page,
		PageSize:       pageSize,
		TargetAudience: audience,
	}
	return s.ListResources(ctx, req)
}

// IncrementViewCount increments the view count for a resource
func (s *store) IncrementViewCount(ctx context.Context, resourceID int) error {
	query := `
		UPDATE resources 
		SET view_count = view_count + 1, updated_at = $1
		WHERE id = $2 AND is_active = true
	`

	result, err := s.db.Exec(ctx, query, time.Now(), resourceID)
	if err != nil {
		return fmt.Errorf("failed to increment view count: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("resource not found")
	}

	return nil
}

// GetResourceStats retrieves resource statistics
func (s *store) GetResourceStats(ctx context.Context) (*ResourceStats, error) {
	// Get basic counts
	var totalResources, featuredResources, totalViews int64

	// Count total resources
	err := s.db.QueryRow(ctx, "SELECT COUNT(*) FROM resources WHERE is_active = true").Scan(&totalResources)
	if err != nil {
		return nil, fmt.Errorf("failed to count total resources: %w", err)
	}

	// Count featured resources
	err = s.db.QueryRow(ctx, "SELECT COUNT(*) FROM resources WHERE is_active = true AND is_featured = true").Scan(&featuredResources)
	if err != nil {
		return nil, fmt.Errorf("failed to count featured resources: %w", err)
	}

	// Sum total views
	err = s.db.QueryRow(ctx, "SELECT COALESCE(SUM(view_count), 0) FROM resources WHERE is_active = true").Scan(&totalViews)
	if err != nil {
		return nil, fmt.Errorf("failed to sum total views: %w", err)
	}

	// Get resources by type
	resourcesByType := make(map[string]int64)
	rows, err := s.db.Query(ctx, `
		SELECT resource_type, COUNT(*) 
		FROM resources 
		WHERE is_active = true 
		GROUP BY resource_type
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to get resources by type: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var resourceType string
		var count int64
		err := rows.Scan(&resourceType, &count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan resource type stats: %w", err)
		}
		resourcesByType[resourceType] = count
	}

	// Get resources by audience
	resourcesByAudience := make(map[string]int64)
	rows, err = s.db.Query(ctx, `
		SELECT target_audience, COUNT(*) 
		FROM resources 
		WHERE is_active = true 
		GROUP BY target_audience
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to get resources by audience: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var audience string
		var count int64
		err := rows.Scan(&audience, &count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan audience stats: %w", err)
		}
		resourcesByAudience[audience] = count
	}

	// Get popular tags
	var popularTags []TagCount
	rows, err = s.db.Query(ctx, `
		SELECT unnest(tags) as tag, COUNT(*) as count
		FROM resources 
		WHERE is_active = true AND tags IS NOT NULL
		GROUP BY tag
		ORDER BY count DESC
		LIMIT 10
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to get popular tags: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var tagCount TagCount
		err := rows.Scan(&tagCount.Tag, &tagCount.Count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan tag stats: %w", err)
		}
		popularTags = append(popularTags, tagCount)
	}

	return &ResourceStats{
		TotalResources:      totalResources,
		FeaturedResources:   featuredResources,
		ResourcesByType:     resourcesByType,
		ResourcesByAudience: resourcesByAudience,
		TotalViews:          totalViews,
		PopularTags:         popularTags,
	}, nil
}

// GetPopularResources retrieves popular resources by view count
func (s *store) GetPopularResources(ctx context.Context, limit int) ([]Resource, error) {
	query := `
		SELECT id, title, description, content, resource_type, url, author, tags, 
			   target_audience, estimated_read_time, is_featured, is_active, view_count,
			   created_at, updated_at
		FROM resources
		WHERE is_active = true
		ORDER BY view_count DESC, created_at DESC
		LIMIT $1
	`

	rows, err := s.db.Query(ctx, query, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query popular resources: %w", err)
	}
	defer rows.Close()

	var resources []Resource
	for rows.Next() {
		var resource Resource
		err := rows.Scan(
			&resource.ID,
			&resource.Title,
			&resource.Description,
			&resource.Content,
			&resource.ResourceType,
			&resource.URL,
			&resource.Author,
			pq.Array(&resource.Tags),
			&resource.TargetAudience,
			&resource.EstimatedReadTime,
			&resource.IsFeatured,
			&resource.IsActive,
			&resource.ViewCount,
			&resource.CreatedAt,
			&resource.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan resource: %w", err)
		}

		resources = append(resources, resource)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return resources, nil
}

// CreateResource creates a new resource (admin only)
func (s *store) CreateResource(ctx context.Context, req *CreateResourceRequest) (*Resource, error) {
	now := time.Now()

	query := `
		INSERT INTO resources (title, description, content, resource_type, url, author, 
							  tags, target_audience, estimated_read_time, is_featured, 
							  is_active, view_count, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		RETURNING id, title, description, content, resource_type, url, author, tags, 
				  target_audience, estimated_read_time, is_featured, is_active, view_count,
				  created_at, updated_at
	`

	var resource Resource
	err := s.db.QueryRow(ctx, query,
		req.Title,
		req.Description,
		req.Content,
		req.ResourceType,
		req.URL,
		req.Author,
		pq.Array(req.Tags),
		req.TargetAudience,
		req.EstimatedReadTime,
		req.IsFeatured,
		true, // is_active
		0,    // view_count
		now,  // created_at
		now,  // updated_at
	).Scan(
		&resource.ID,
		&resource.Title,
		&resource.Description,
		&resource.Content,
		&resource.ResourceType,
		&resource.URL,
		&resource.Author,
		pq.Array(&resource.Tags),
		&resource.TargetAudience,
		&resource.EstimatedReadTime,
		&resource.IsFeatured,
		&resource.IsActive,
		&resource.ViewCount,
		&resource.CreatedAt,
		&resource.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create resource: %w", err)
	}

	return &resource, nil
}

// UpdateResource updates a resource (admin only)
func (s *store) UpdateResource(ctx context.Context, resourceID int, req *UpdateResourceRequest) (*Resource, error) {
	var setParts []string
	var args []interface{}
	argIndex := 1

	if req.Title != nil {
		setParts = append(setParts, fmt.Sprintf("title = $%d", argIndex))
		args = append(args, *req.Title)
		argIndex++
	}

	if req.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *req.Description)
		argIndex++
	}

	if req.Content != nil {
		setParts = append(setParts, fmt.Sprintf("content = $%d", argIndex))
		args = append(args, *req.Content)
		argIndex++
	}

	if req.ResourceType != nil {
		setParts = append(setParts, fmt.Sprintf("resource_type = $%d", argIndex))
		args = append(args, *req.ResourceType)
		argIndex++
	}

	if req.URL != nil {
		setParts = append(setParts, fmt.Sprintf("url = $%d", argIndex))
		args = append(args, *req.URL)
		argIndex++
	}

	if req.Author != nil {
		setParts = append(setParts, fmt.Sprintf("author = $%d", argIndex))
		args = append(args, *req.Author)
		argIndex++
	}

	if req.Tags != nil {
		setParts = append(setParts, fmt.Sprintf("tags = $%d", argIndex))
		args = append(args, pq.Array(req.Tags))
		argIndex++
	}

	if req.TargetAudience != nil {
		setParts = append(setParts, fmt.Sprintf("target_audience = $%d", argIndex))
		args = append(args, *req.TargetAudience)
		argIndex++
	}

	if req.EstimatedReadTime != nil {
		setParts = append(setParts, fmt.Sprintf("estimated_read_time = $%d", argIndex))
		args = append(args, *req.EstimatedReadTime)
		argIndex++
	}

	if req.IsFeatured != nil {
		setParts = append(setParts, fmt.Sprintf("is_featured = $%d", argIndex))
		args = append(args, *req.IsFeatured)
		argIndex++
	}

	// If no fields to update, just return the existing resource
	if len(setParts) == 0 {
		return s.GetResourceByID(ctx, resourceID)
	}

	// Always update the updated_at timestamp
	setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
	args = append(args, time.Now())
	argIndex++

	query := fmt.Sprintf(`
		UPDATE resources 
		SET %s
		WHERE id = $%d AND is_active = true
		RETURNING id, title, description, content, resource_type, url, author, tags, 
				  target_audience, estimated_read_time, is_featured, is_active, view_count,
				  created_at, updated_at
	`, strings.Join(setParts, ", "), argIndex)

	args = append(args, resourceID)

	var resource Resource
	err := s.db.QueryRow(ctx, query, args...).Scan(
		&resource.ID,
		&resource.Title,
		&resource.Description,
		&resource.Content,
		&resource.ResourceType,
		&resource.URL,
		&resource.Author,
		pq.Array(&resource.Tags),
		&resource.TargetAudience,
		&resource.EstimatedReadTime,
		&resource.IsFeatured,
		&resource.IsActive,
		&resource.ViewCount,
		&resource.CreatedAt,
		&resource.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("resource not found")
		}
		return nil, fmt.Errorf("failed to update resource: %w", err)
	}

	return &resource, nil
}

// DeleteResource soft deletes a resource (admin only)
func (s *store) DeleteResource(ctx context.Context, resourceID int) error {
	query := `
		UPDATE resources 
		SET is_active = false, updated_at = $1
		WHERE id = $2
	`

	result, err := s.db.Exec(ctx, query, time.Now(), resourceID)
	if err != nil {
		return fmt.Errorf("failed to delete resource: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("resource not found")
	}

	return nil
}

// ToggleResourceFeatured toggles the featured status of a resource (admin only)
func (s *store) ToggleResourceFeatured(ctx context.Context, resourceID int) error {
	query := `
		UPDATE resources 
		SET is_featured = NOT is_featured, updated_at = $1
		WHERE id = $2 AND is_active = true
	`

	result, err := s.db.Exec(ctx, query, time.Now(), resourceID)
	if err != nil {
		return fmt.Errorf("failed to toggle resource featured status: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("resource not found")
	}

	return nil
}
