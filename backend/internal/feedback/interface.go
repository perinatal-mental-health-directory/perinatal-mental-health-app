package feedback

import (
	"context"
)

// FeedbackStoreInterface defines the interface for feedback storage operations
type FeedbackStoreInterface interface {
	CreateFeedback(ctx context.Context, req *CreateFeedbackRequest, userID *string) (*Feedback, error)
	ListFeedback(ctx context.Context, page, pageSize int, category, rating string) (*ListFeedbackResponse, error)
	GetFeedbackStats(ctx context.Context) (*FeedbackStats, error)
	GetFeedbackByID(ctx context.Context, feedbackID string) (*Feedback, error)
	UpdateFeedbackStatus(ctx context.Context, feedbackID string, isActive bool) error
	GetUserFeedback(ctx context.Context, userID string, page, pageSize int) (*ListFeedbackResponse, error)
}

// FeedbackServiceInterface defines the interface for feedback business logic
type FeedbackServiceInterface interface {
	CreateFeedback(ctx context.Context, req *CreateFeedbackRequest, userID *string) (*Feedback, error)
	ListFeedback(ctx context.Context, page, pageSize int, category, rating string) (*ListFeedbackResponse, error)
	GetFeedbackStats(ctx context.Context) (*FeedbackStats, error)
	GetFeedbackByID(ctx context.Context, feedbackID string) (*Feedback, error)
	UpdateFeedbackStatus(ctx context.Context, feedbackID string, isActive bool) error
	GetUserFeedback(ctx context.Context, userID string, page, pageSize int) (*ListFeedbackResponse, error)
	ValidateFeedbackRequest(req *CreateFeedbackRequest) error
}
