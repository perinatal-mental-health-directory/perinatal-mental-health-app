package resources

import (
	"context"
	"github.com/labstack/echo/v4"
)

// Service defines the interface for resources business logic
type Service interface {
	ListResources(ctx context.Context, req *ListResourcesRequest) (*ListResourcesResponse, error)
	GetResource(ctx context.Context, resourceID string) (*Resource, error)
	GetFeaturedResources(ctx context.Context, limit int) ([]Resource, error)
	SearchResources(ctx context.Context, query string, page, pageSize int) (*ListResourcesResponse, error)
	IncrementViewCount(ctx context.Context, resourceID string) error
	GetResourcesByTag(ctx context.Context, tag string, page, pageSize int) (*ListResourcesResponse, error)
	GetResourcesByAudience(ctx context.Context, audience string, page, pageSize int) (*ListResourcesResponse, error)
	GetResourceStats(ctx context.Context) (*ResourceStats, error)
	GetPopularResources(ctx context.Context, limit int) ([]Resource, error)

	// Admin/Staff only methods
	CreateResource(ctx context.Context, req *CreateResourceRequest) (*Resource, error)
	UpdateResource(ctx context.Context, resourceID string, req *UpdateResourceRequest) (*Resource, error)
	DeleteResource(ctx context.Context, resourceID string) error
	ToggleResourceFeatured(ctx context.Context, resourceID string) error
}

// Store defines the interface for resources data persistence
type Store interface {
	ListResources(ctx context.Context, req *ListResourcesRequest) (*ListResourcesResponse, error)
	GetResourceByID(ctx context.Context, resourceID string) (*Resource, error)
	GetFeaturedResources(ctx context.Context, limit int) ([]Resource, error)
	SearchResources(ctx context.Context, query string, page, pageSize int) (*ListResourcesResponse, error)
	GetResourcesByTag(ctx context.Context, tag string, page, pageSize int) (*ListResourcesResponse, error)
	GetResourcesByAudience(ctx context.Context, audience string, page, pageSize int) (*ListResourcesResponse, error)
	IncrementViewCount(ctx context.Context, resourceID string) error
	GetResourceStats(ctx context.Context) (*ResourceStats, error)
	GetPopularResources(ctx context.Context, limit int) ([]Resource, error)

	// Admin/Staff only methods
	CreateResource(ctx context.Context, req *CreateResourceRequest) (*Resource, error)
	UpdateResource(ctx context.Context, resourceID string, req *UpdateResourceRequest) (*Resource, error)
	DeleteResource(ctx context.Context, resourceID string) error
	ToggleResourceFeatured(ctx context.Context, resourceID string) error
}

// Handler defines the interface for resources HTTP handlers
type Handler interface {
	ListResources(c echo.Context) error
	GetResource(c echo.Context) error
	GetFeaturedResources(c echo.Context) error
	SearchResources(c echo.Context) error
	GetResourcesByTag(c echo.Context) error
	GetResourcesByAudience(c echo.Context) error
	IncrementViewCount(c echo.Context) error
	GetResourceStats(c echo.Context) error
	GetPopularResources(c echo.Context) error

	// Admin/Staff only methods
	CreateResource(c echo.Context) error
	UpdateResource(c echo.Context) error
	DeleteResource(c echo.Context) error
	ToggleResourceFeatured(c echo.Context) error
}
