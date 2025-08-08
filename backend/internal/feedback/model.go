package feedback

import (
	"time"
)

// Feedback represents user feedback
type Feedback struct {
	ID        int       `json:"id" db:"id"`
	UserID    *string   `json:"user_id,omitempty" db:"user_id"`
	Anonymous bool      `json:"anonymous" db:"anonymous"`
	Rating    string    `json:"rating" db:"rating"`
	Message   string    `json:"feedback" db:"feedback"`
	Category  string    `json:"category" db:"category"`
	IsActive  bool      `json:"is_active" db:"is_active"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// FeedbackRating represents valid rating values
type FeedbackRating string

const (
	RatingVeryDissatisfied FeedbackRating = "Very Dissatisfied"
	RatingDissatisfied     FeedbackRating = "Dissatisfied"
	RatingNeutral          FeedbackRating = "Neutral"
	RatingSatisfied        FeedbackRating = "Satisfied"
	RatingVerySatisfied    FeedbackRating = "Very Satisfied"
)

// CreateFeedbackRequest represents the request to create feedback
type CreateFeedbackRequest struct {
	Anonymous bool   `json:"anonymous"`
	Rating    string `json:"rating" validate:"required"`
	Message   string `json:"feedback" validate:"required,min=10,max=1000"`
	Category  string `json:"category" validate:"required"`
}

// ListFeedbackResponse represents the response for listing feedback
type ListFeedbackResponse struct {
	Feedback   []Feedback `json:"feedback"`
	Total      int64      `json:"total"`
	Page       int        `json:"page"`
	PageSize   int        `json:"page_size"`
	TotalPages int        `json:"total_pages"`
}

// FeedbackStats represents feedback statistics
type FeedbackStats struct {
	TotalFeedback     int64            `json:"total_feedback"`
	RatingBreakdown   map[string]int64 `json:"rating_breakdown"`
	CategoryBreakdown map[string]int64 `json:"category_breakdown"`
}
