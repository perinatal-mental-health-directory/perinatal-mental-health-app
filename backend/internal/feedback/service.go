package feedback

import (
	"context"
	"fmt"
	"strings"
)

type Service struct {
	store FeedbackStoreInterface
}

func NewService(store FeedbackStoreInterface) *Service {
	return &Service{
		store: store,
	}
}

// CreateFeedback creates new feedback
func (s *Service) CreateFeedback(ctx context.Context, req *CreateFeedbackRequest, userID *string) (*Feedback, error) {
	// Validate the request
	if err := s.ValidateFeedbackRequest(req); err != nil {
		return nil, err
	}

	// Validate rating
	if !isValidRating(req.Rating) {
		return nil, fmt.Errorf("invalid rating: %s", req.Rating)
	}

	// If anonymous, ensure userID is nil
	if req.Anonymous {
		userID = nil
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

	// Validate rating if provided
	if rating != "" && !isValidRating(rating) {
		return nil, fmt.Errorf("invalid rating filter: %s", rating)
	}

	return s.store.ListFeedback(ctx, page, pageSize, category, rating)
}

// GetFeedbackStats retrieves feedback statistics
func (s *Service) GetFeedbackStats(ctx context.Context) (*FeedbackStats, error) {
	return s.store.GetFeedbackStats(ctx)
}

// GetFeedbackByID retrieves a single feedback by ID
func (s *Service) GetFeedbackByID(ctx context.Context, feedbackID string) (*Feedback, error) {
	if feedbackID == "" {
		return nil, fmt.Errorf("feedback ID is required")
	}

	return s.store.GetFeedbackByID(ctx, feedbackID)
}

// UpdateFeedbackStatus updates the status of a feedback (admin operation)
func (s *Service) UpdateFeedbackStatus(ctx context.Context, feedbackID string, isActive bool) error {
	if feedbackID == "" {
		return fmt.Errorf("feedback ID is required")
	}

	return s.store.UpdateFeedbackStatus(ctx, feedbackID, isActive)
}

// GetUserFeedback retrieves feedback submitted by a specific user
func (s *Service) GetUserFeedback(ctx context.Context, userID string, page, pageSize int) (*ListFeedbackResponse, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	return s.store.GetUserFeedback(ctx, userID, page, pageSize)
}

// ValidateFeedbackRequest validates the feedback request
func (s *Service) ValidateFeedbackRequest(req *CreateFeedbackRequest) error {
	if req == nil {
		return fmt.Errorf("feedback request is required")
	}

	if strings.TrimSpace(req.Message) == "" {
		return fmt.Errorf("feedback message is required")
	}

	if len(strings.TrimSpace(req.Message)) < 10 {
		return fmt.Errorf("feedback message must be at least 10 characters long")
	}

	if len(strings.TrimSpace(req.Message)) > 1000 {
		return fmt.Errorf("feedback message must be less than 1000 characters")
	}

	if strings.TrimSpace(req.Category) == "" {
		return fmt.Errorf("feedback category is required")
	}

	if strings.TrimSpace(req.Rating) == "" {
		return fmt.Errorf("feedback rating is required")
	}

	// Validate category against allowed values
	validCategories := []string{
		"general", "app_usability", "services", "support", "bug_report", "feature_request",
	}

	isValidCategory := false
	for _, validCategory := range validCategories {
		if req.Category == validCategory {
			isValidCategory = true
			break
		}
	}

	if !isValidCategory {
		return fmt.Errorf("invalid category: %s", req.Category)
	}

	return nil
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
