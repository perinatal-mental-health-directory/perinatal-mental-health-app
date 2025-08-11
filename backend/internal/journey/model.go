package journey

import (
	"time"
)

// JourneyEntry represents a daily journey entry
type JourneyEntry struct {
	ID            string    `json:"id" db:"id"`
	UserID        string    `json:"user_id" db:"user_id"`
	EntryDate     time.Time `json:"entry_date" db:"entry_date"`
	MoodRating    int       `json:"mood_rating" db:"mood_rating"`
	AnxietyLevel  *int      `json:"anxiety_level,omitempty" db:"anxiety_level"`
	SleepQuality  *int      `json:"sleep_quality,omitempty" db:"sleep_quality"`
	EnergyLevel   *int      `json:"energy_level,omitempty" db:"energy_level"`
	Notes         *string   `json:"notes,omitempty" db:"notes"`
	Activities    []string  `json:"activities" db:"activities"`
	Symptoms      []string  `json:"symptoms" db:"symptoms"`
	GratitudeNote *string   `json:"gratitude_note,omitempty" db:"gratitude_note"`
	IsPrivate     bool      `json:"is_private" db:"is_private"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
	UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
}

// JourneyGoal represents a user's journey goal
type JourneyGoal struct {
	ID          string     `json:"id" db:"id"`
	UserID      string     `json:"user_id" db:"user_id"`
	Title       string     `json:"title" db:"title"`
	Description *string    `json:"description,omitempty" db:"description"`
	TargetDate  *time.Time `json:"target_date,omitempty" db:"target_date"`
	GoalType    string     `json:"goal_type" db:"goal_type"`
	Status      string     `json:"status" db:"status"`
	IsCompleted bool       `json:"is_completed" db:"is_completed"`
	CompletedAt *time.Time `json:"completed_at,omitempty" db:"completed_at"`
	CreatedAt   time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at" db:"updated_at"`
}

// JourneyMilestone represents achievement milestones
type JourneyMilestone struct {
	ID            string    `json:"id" db:"id"`
	UserID        string    `json:"user_id" db:"user_id"`
	MilestoneType string    `json:"milestone_type" db:"milestone_type"`
	Title         string    `json:"title" db:"title"`
	Description   *string   `json:"description,omitempty" db:"description"`
	AchievedAt    time.Time `json:"achieved_at" db:"achieved_at"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
}

// CreateJourneyEntryRequest represents the request to create a journey entry
type CreateJourneyEntryRequest struct {
	EntryDate     *string  `json:"entry_date,omitempty"` // YYYY-MM-DD format, defaults to today
	MoodRating    int      `json:"mood_rating" validate:"required,min=1,max=5"`
	AnxietyLevel  *int     `json:"anxiety_level,omitempty" validate:"omitempty,min=1,max=5"`
	SleepQuality  *int     `json:"sleep_quality,omitempty" validate:"omitempty,min=1,max=5"`
	EnergyLevel   *int     `json:"energy_level,omitempty" validate:"omitempty,min=1,max=5"`
	Notes         *string  `json:"notes,omitempty" validate:"omitempty,max=1000"`
	Activities    []string `json:"activities,omitempty"`
	Symptoms      []string `json:"symptoms,omitempty"`
	GratitudeNote *string  `json:"gratitude_note,omitempty" validate:"omitempty,max=500"`
	IsPrivate     bool     `json:"is_private"`
}

// UpdateJourneyEntryRequest represents the request to update a journey entry
type UpdateJourneyEntryRequest struct {
	MoodRating    *int     `json:"mood_rating,omitempty" validate:"omitempty,min=1,max=5"`
	AnxietyLevel  *int     `json:"anxiety_level,omitempty" validate:"omitempty,min=1,max=5"`
	SleepQuality  *int     `json:"sleep_quality,omitempty" validate:"omitempty,min=1,max=5"`
	EnergyLevel   *int     `json:"energy_level,omitempty" validate:"omitempty,min=1,max=5"`
	Notes         *string  `json:"notes,omitempty" validate:"omitempty,max=1000"`
	Activities    []string `json:"activities,omitempty"`
	Symptoms      []string `json:"symptoms,omitempty"`
	GratitudeNote *string  `json:"gratitude_note,omitempty" validate:"omitempty,max=500"`
	IsPrivate     *bool    `json:"is_private,omitempty"`
}

// CreateJourneyGoalRequest represents the request to create a journey goal
type CreateJourneyGoalRequest struct {
	Title       string  `json:"title" validate:"required,min=1,max=255"`
	Description *string `json:"description,omitempty" validate:"omitempty,max=1000"`
	TargetDate  *string `json:"target_date,omitempty"` // YYYY-MM-DD format
	GoalType    string  `json:"goal_type" validate:"required,oneof=mood sleep exercise mindfulness social custom"`
}

// UpdateJourneyGoalRequest represents the request to update a journey goal
type UpdateJourneyGoalRequest struct {
	Title       *string `json:"title,omitempty" validate:"omitempty,min=1,max=255"`
	Description *string `json:"description,omitempty" validate:"omitempty,max=1000"`
	TargetDate  *string `json:"target_date,omitempty"` // YYYY-MM-DD format
	Status      *string `json:"status,omitempty" validate:"omitempty,oneof=active completed paused cancelled"`
}

// ListJourneyEntriesResponse represents the response for listing journey entries
type ListJourneyEntriesResponse struct {
	Entries    []JourneyEntry `json:"entries"`
	Total      int64          `json:"total"`
	Page       int            `json:"page"`
	PageSize   int            `json:"page_size"`
	TotalPages int            `json:"total_pages"`
}

// JourneyStats represents journey statistics for a user
type JourneyStats struct {
	TotalEntries     int64              `json:"total_entries"`
	CurrentStreak    int                `json:"current_streak"`
	LongestStreak    int                `json:"longest_streak"`
	AverageMood      float64            `json:"average_mood"`
	MoodTrend        string             `json:"mood_trend"` // "improving", "stable", "declining"
	CompletedGoals   int64              `json:"completed_goals"`
	ActiveGoals      int64              `json:"active_goals"`
	TotalMilestones  int64              `json:"total_milestones"`
	RecentMilestones []JourneyMilestone `json:"recent_milestones"`
	MoodBreakdown    map[string]int64   `json:"mood_breakdown"`
	WeeklyMoodData   []DailyMoodData    `json:"weekly_mood_data"`
}

// DailyMoodData represents mood data for a specific day
type DailyMoodData struct {
	Date       string `json:"date"`
	MoodRating *int   `json:"mood_rating,omitempty"`
	HasEntry   bool   `json:"has_entry"`
}

// JourneyInsights represents insights for the user
type JourneyInsights struct {
	MoodPatterns    []string `json:"mood_patterns"`
	Recommendations []string `json:"recommendations"`
	Achievements    []string `json:"achievements"`
	NextGoals       []string `json:"next_goals"`
}

// Constants for goal types
const (
	GoalTypeMood        = "mood"
	GoalTypeSleep       = "sleep"
	GoalTypeExercise    = "exercise"
	GoalTypeMindfulness = "mindfulness"
	GoalTypeSocial      = "social"
	GoalTypeCustom      = "custom"
)

// Constants for goal status
const (
	GoalStatusActive    = "active"
	GoalStatusCompleted = "completed"
	GoalStatusPaused    = "paused"
	GoalStatusCancelled = "cancelled"
)

// Constants for milestone types
const (
	MilestoneFirstEntry   = "first_entry"
	MilestoneWeekStreak   = "week_streak"
	MilestoneMonthStreak  = "month_streak"
	MilestoneFirstGoal    = "first_goal"
	MilestoneMoodStable   = "mood_stable"
	MilestoneYearComplete = "year_complete"
)

// Helper methods for JourneyEntry
func (je *JourneyEntry) GetMoodEmoji() string {
	switch je.MoodRating {
	case 1:
		return "😢"
	case 2:
		return "😟"
	case 3:
		return "😐"
	case 4:
		return "😊"
	case 5:
		return "😄"
	default:
		return "😐"
	}
}

func (je *JourneyEntry) GetMoodLabel() string {
	switch je.MoodRating {
	case 1:
		return "Very Low"
	case 2:
		return "Low"
	case 3:
		return "Neutral"
	case 4:
		return "Good"
	case 5:
		return "Excellent"
	default:
		return "Unknown"
	}
}

// Helper methods for JourneyGoal
func (jg *JourneyGoal) GetGoalTypeDisplayName() string {
	switch jg.GoalType {
	case GoalTypeMood:
		return "Mood Improvement"
	case GoalTypeSleep:
		return "Sleep Quality"
	case GoalTypeExercise:
		return "Physical Activity"
	case GoalTypeMindfulness:
		return "Mindfulness & Meditation"
	case GoalTypeSocial:
		return "Social Connection"
	case GoalTypeCustom:
		return "Personal Goal"
	default:
		return "Goal"
	}
}

func (jg *JourneyGoal) GetStatusDisplayName() string {
	switch jg.Status {
	case GoalStatusActive:
		return "In Progress"
	case GoalStatusCompleted:
		return "Completed"
	case GoalStatusPaused:
		return "Paused"
	case GoalStatusCancelled:
		return "Cancelled"
	default:
		return "Unknown"
	}
}

func (jg *JourneyGoal) IsOverdue() bool {
	if jg.TargetDate == nil || jg.IsCompleted {
		return false
	}
	return time.Now().After(*jg.TargetDate)
}
