package feedback

import (
	"time"
)

// Feedback represents user feedback
type Feedback struct {
	ID        string    `json:"id" db:"id"`
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

// FeedbackCategory represents valid category values
type FeedbackCategory string

const (
	CategoryGeneral        FeedbackCategory = "general"
	CategoryAppUsability   FeedbackCategory = "app_usability"
	CategoryServices       FeedbackCategory = "services"
	CategorySupport        FeedbackCategory = "support"
	CategoryBugReport      FeedbackCategory = "bug_report"
	CategoryFeatureRequest FeedbackCategory = "feature_request"
)

// CreateFeedbackRequest represents the request to create feedback
type CreateFeedbackRequest struct {
	Anonymous bool   `json:"anonymous"`
	Rating    string `json:"rating" validate:"required"`
	Message   string `json:"feedback" validate:"required,min=10,max=1000"`
	Category  string `json:"category" validate:"required,oneof=general app_usability services support bug_report feature_request"`
}

// UpdateFeedbackRequest represents the request to update feedback
type UpdateFeedbackRequest struct {
	Rating   *string `json:"rating,omitempty" validate:"omitempty"`
	Message  *string `json:"feedback,omitempty" validate:"omitempty,min=10,max=1000"`
	Category *string `json:"category,omitempty" validate:"omitempty,oneof=general app_usability services support bug_report feature_request"`
	IsActive *bool   `json:"is_active,omitempty"`
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
	TotalFeedback      int64            `json:"total_feedback"`
	RatingBreakdown    map[string]int64 `json:"rating_breakdown"`
	CategoryBreakdown  map[string]int64 `json:"category_breakdown"`
	RecentFeedback     []Feedback       `json:"recent_feedback,omitempty"`
	AverageRating      float64          `json:"average_rating"`
	TotalAnonymous     int64            `json:"total_anonymous"`
	TotalAuthenticated int64            `json:"total_authenticated"`
}

// FeedbackFilter represents filters for listing feedback
type FeedbackFilter struct {
	Category  string     `json:"category,omitempty"`
	Rating    string     `json:"rating,omitempty"`
	Anonymous *bool      `json:"anonymous,omitempty"`
	UserID    string     `json:"user_id,omitempty"`
	IsActive  *bool      `json:"is_active,omitempty"`
	StartDate *time.Time `json:"start_date,omitempty"`
	EndDate   *time.Time `json:"end_date,omitempty"`
	Page      int        `json:"page"`
	PageSize  int        `json:"page_size"`
}

// FeedbackSummary represents a summary of feedback for dashboard
type FeedbackSummary struct {
	TotalCount    int64   `json:"total_count"`
	TodayCount    int64   `json:"today_count"`
	WeekCount     int64   `json:"week_count"`
	MonthCount    int64   `json:"month_count"`
	AverageRating float64 `json:"average_rating"`
	PositiveRatio float64 `json:"positive_ratio"` // Percentage of satisfied + very satisfied
	NegativeRatio float64 `json:"negative_ratio"` // Percentage of dissatisfied + very dissatisfied
}

// FeedbackWithUser represents feedback with user information (for admin views)
type FeedbackWithUser struct {
	Feedback
	UserName  *string `json:"user_name,omitempty"`
	UserEmail *string `json:"user_email,omitempty"`
	UserRole  *string `json:"user_role,omitempty"`
}

// FeedbackTrend represents feedback trend data
type FeedbackTrend struct {
	Date  string `json:"date"`
	Count int64  `json:"count"`
}

// GetValidRatings returns all valid rating values
func GetValidRatings() []string {
	return []string{
		string(RatingVeryDissatisfied),
		string(RatingDissatisfied),
		string(RatingNeutral),
		string(RatingSatisfied),
		string(RatingVerySatisfied),
	}
}

// GetValidCategories returns all valid category values
func GetValidCategories() []string {
	return []string{
		string(CategoryGeneral),
		string(CategoryAppUsability),
		string(CategoryServices),
		string(CategorySupport),
		string(CategoryBugReport),
		string(CategoryFeatureRequest),
	}
}

// IsValidRating checks if a rating value is valid
func IsValidRating(rating string) bool {
	validRatings := GetValidRatings()
	for _, validRating := range validRatings {
		if rating == validRating {
			return true
		}
	}
	return false
}

// IsValidCategory checks if a category value is valid
func IsValidCategory(category string) bool {
	validCategories := GetValidCategories()
	for _, validCategory := range validCategories {
		if category == validCategory {
			return true
		}
	}
	return false
}

// GetRatingValue converts rating string to numeric value for calculations
func GetRatingValue(rating string) int {
	switch FeedbackRating(rating) {
	case RatingVeryDissatisfied:
		return 1
	case RatingDissatisfied:
		return 2
	case RatingNeutral:
		return 3
	case RatingSatisfied:
		return 4
	case RatingVerySatisfied:
		return 5
	default:
		return 0
	}
}

// IsPositiveRating checks if a rating is positive (satisfied or very satisfied)
func IsPositiveRating(rating string) bool {
	return rating == string(RatingSatisfied) || rating == string(RatingVerySatisfied)
}

// IsNegativeRating checks if a rating is negative (dissatisfied or very dissatisfied)
func IsNegativeRating(rating string) bool {
	return rating == string(RatingDissatisfied) || rating == string(RatingVeryDissatisfied)
}

// GetCategoryDisplayName returns a human-readable category name
func GetCategoryDisplayName(category string) string {
	switch FeedbackCategory(category) {
	case CategoryGeneral:
		return "General Feedback"
	case CategoryAppUsability:
		return "App Usability"
	case CategoryServices:
		return "Services Directory"
	case CategorySupport:
		return "Support & Help"
	case CategoryBugReport:
		return "Bug Report"
	case CategoryFeatureRequest:
		return "Feature Request"
	default:
		return "Unknown Category"
	}
}

// GetRatingDisplayName returns a human-readable rating name
func GetRatingDisplayName(rating string) string {
	switch FeedbackRating(rating) {
	case RatingVeryDissatisfied:
		return "Very Dissatisfied"
	case RatingDissatisfied:
		return "Dissatisfied"
	case RatingNeutral:
		return "Neutral"
	case RatingSatisfied:
		return "Satisfied"
	case RatingVerySatisfied:
		return "Very Satisfied"
	default:
		return "Unknown Rating"
	}
}

// Sanitize removes sensitive information from feedback for public display
func (f *Feedback) Sanitize() *Feedback {
	sanitized := *f
	if f.Anonymous {
		sanitized.UserID = nil
	}
	return &sanitized
}

// ToSummary creates a feedback summary from a slice of feedback
func ToSummary(feedbacks []Feedback) *FeedbackSummary {
	if len(feedbacks) == 0 {
		return &FeedbackSummary{}
	}

	summary := &FeedbackSummary{
		TotalCount: int64(len(feedbacks)),
	}

	now := time.Now()
	today := now.Truncate(24 * time.Hour)
	weekAgo := now.AddDate(0, 0, -7)
	monthAgo := now.AddDate(0, -1, 0)

	var totalRating, positiveCount, negativeCount int64

	for _, feedback := range feedbacks {
		// Count by time periods
		if feedback.CreatedAt.After(today) {
			summary.TodayCount++
		}
		if feedback.CreatedAt.After(weekAgo) {
			summary.WeekCount++
		}
		if feedback.CreatedAt.After(monthAgo) {
			summary.MonthCount++
		}

		// Calculate rating metrics
		ratingValue := GetRatingValue(feedback.Rating)
		totalRating += int64(ratingValue)

		if IsPositiveRating(feedback.Rating) {
			positiveCount++
		} else if IsNegativeRating(feedback.Rating) {
			negativeCount++
		}
	}

	// Calculate averages and ratios
	if summary.TotalCount > 0 {
		summary.AverageRating = float64(totalRating) / float64(summary.TotalCount)
		summary.PositiveRatio = float64(positiveCount) / float64(summary.TotalCount) * 100
		summary.NegativeRatio = float64(negativeCount) / float64(summary.TotalCount) * 100
	}

	return summary
}
