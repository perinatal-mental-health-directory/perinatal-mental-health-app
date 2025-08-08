package feedback

import (
	"context"
	"fmt"
)

type Service struct {
	store *Store
}

func NewService(store *Store) *Service {
	return &Service{
		store: store,
	}
}

// CreateFeedback creates new feedback
func (s *Service) CreateFeedback(ctx context.Context, req *CreateFeedbackRequest, userID *string) (*Feedback, error) {
	// Validate rating
	if !isValidRating(req.Rating) {
		return nil, fmt.Errorf("invalid rating: %s", req.Rating)
	}

	return s.store.CreateFeedback(ctx, req, userID)
}

// ListFeedback retrieves a paginated list of feedback
func (s *Service) ListFeedback(ctx context.Context, page, pageSize int, category, rating string) (*ListFeedbackResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	return s.store.ListFeedback(ctx, page, pageSize, category, rating)
}

// GetFeedbackStats retrieves feedback statistics
func (s *Service) GetFeedbackStats(ctx context.Context) (*FeedbackStats, error) {
	return s.store.GetFeedbackStats(ctx)
}

// Helper function to validate feedback ratings
func isValidRating(rating string) bool {
	switch FeedbackRating(rating) {
	case RatingVeryDissatisfied, RatingDissatisfied, RatingNeutral, RatingSatisfied, RatingVerySatisfied:
		return true
	default:
		return false
	}
}
