package journey

import (
	"context"
	"fmt"
	"time"
)

type service struct {
	store Store
}

func NewService(store Store) Service {
	return &service{
		store: store,
	}
}

// CreateJourneyEntry creates a new journey entry
func (s *service) CreateJourneyEntry(ctx context.Context, userID string, req *CreateJourneyEntryRequest) (*JourneyEntry, error) {
	// Validate user ID
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	// Validate mood rating
	if req.MoodRating < 1 || req.MoodRating > 5 {
		return nil, fmt.Errorf("mood rating must be between 1 and 5")
	}

	// Parse entry date or use today
	var entryDate time.Time
	if req.EntryDate != nil && *req.EntryDate != "" {
		var err error
		entryDate, err = time.Parse("2006-01-02", *req.EntryDate)
		if err != nil {
			return nil, fmt.Errorf("invalid date format, use YYYY-MM-DD")
		}
	} else {
		entryDate = time.Now()
	}

	// Additional validation
	if err := validateJourneyEntryRequest(req); err != nil {
		return nil, err
	}

	entry, err := s.store.CreateJourneyEntry(ctx, userID, entryDate, req)
	if err != nil {
		return nil, err
	}

	// Check for milestones after creating entry
	go s.checkAndAwardMilestones(context.Background(), userID)

	return entry, nil
}

// GetJourneyEntry retrieves a specific journey entry
func (s *service) GetJourneyEntry(ctx context.Context, userID, entryID string) (*JourneyEntry, error) {
	if userID == "" || entryID == "" {
		return nil, fmt.Errorf("user ID and entry ID are required")
	}

	return s.store.GetJourneyEntryByID(ctx, userID, entryID)
}

// GetTodaysEntry retrieves today's journey entry for a user
func (s *service) GetTodaysEntry(ctx context.Context, userID string) (*JourneyEntry, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	today := time.Now().Format("2006-01-02")
	return s.store.GetJourneyEntryByDate(ctx, userID, today)
}

// UpdateJourneyEntry updates an existing journey entry
func (s *service) UpdateJourneyEntry(ctx context.Context, userID, entryID string, req *UpdateJourneyEntryRequest) (*JourneyEntry, error) {
	if userID == "" || entryID == "" {
		return nil, fmt.Errorf("user ID and entry ID are required")
	}

	// Validate mood rating if provided
	if req.MoodRating != nil && (*req.MoodRating < 1 || *req.MoodRating > 5) {
		return nil, fmt.Errorf("mood rating must be between 1 and 5")
	}

	return s.store.UpdateJourneyEntry(ctx, userID, entryID, req)
}

// DeleteJourneyEntry deletes a journey entry
func (s *service) DeleteJourneyEntry(ctx context.Context, userID, entryID string) error {
	if userID == "" || entryID == "" {
		return fmt.Errorf("user ID and entry ID are required")
	}

	return s.store.DeleteJourneyEntry(ctx, userID, entryID)
}

// ListJourneyEntries retrieves a paginated list of journey entries for a user
func (s *service) ListJourneyEntries(ctx context.Context, userID string, page, pageSize int, startDate, endDate *string) (*ListJourneyEntriesResponse, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 30
	}

	return s.store.ListJourneyEntries(ctx, userID, page, pageSize, startDate, endDate)
}

// CreateJourneyGoal creates a new journey goal
func (s *service) CreateJourneyGoal(ctx context.Context, userID string, req *CreateJourneyGoalRequest) (*JourneyGoal, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	// Validate goal type
	if !isValidGoalType(req.GoalType) {
		return nil, fmt.Errorf("invalid goal type: %s", req.GoalType)
	}

	// Parse target date if provided
	var targetDate *time.Time
	if req.TargetDate != nil && *req.TargetDate != "" {
		parsed, err := time.Parse("2006-01-02", *req.TargetDate)
		if err != nil {
			return nil, fmt.Errorf("invalid target date format, use YYYY-MM-DD")
		}
		targetDate = &parsed
	}

	goal, err := s.store.CreateJourneyGoal(ctx, userID, req, targetDate)
	if err != nil {
		return nil, err
	}

	// Check for first goal milestone
	go s.checkFirstGoalMilestone(context.Background(), userID)

	return goal, nil
}

// UpdateJourneyGoal updates an existing journey goal
func (s *service) UpdateJourneyGoal(ctx context.Context, userID, goalID string, req *UpdateJourneyGoalRequest) (*JourneyGoal, error) {
	if userID == "" || goalID == "" {
		return nil, fmt.Errorf("user ID and goal ID are required")
	}

	// Validate status if provided
	if req.Status != nil && !isValidGoalStatus(*req.Status) {
		return nil, fmt.Errorf("invalid goal status: %s", *req.Status)
	}

	// Parse target date if provided
	var targetDate *time.Time
	if req.TargetDate != nil && *req.TargetDate != "" {
		parsed, err := time.Parse("2006-01-02", *req.TargetDate)
		if err != nil {
			return nil, fmt.Errorf("invalid target date format, use YYYY-MM-DD")
		}
		targetDate = &parsed
	}

	return s.store.UpdateJourneyGoal(ctx, userID, goalID, req, targetDate)
}

// DeleteJourneyGoal deletes a journey goal
func (s *service) DeleteJourneyGoal(ctx context.Context, userID, goalID string) error {
	if userID == "" || goalID == "" {
		return fmt.Errorf("user ID and goal ID are required")
	}

	return s.store.DeleteJourneyGoal(ctx, userID, goalID)
}

// ListJourneyGoals retrieves all journey goals for a user
func (s *service) ListJourneyGoals(ctx context.Context, userID string, status *string) ([]JourneyGoal, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	if status != nil && !isValidGoalStatus(*status) {
		return nil, fmt.Errorf("invalid goal status: %s", *status)
	}

	return s.store.ListJourneyGoals(ctx, userID, status)
}

// GetJourneyStats retrieves journey statistics for a user
func (s *service) GetJourneyStats(ctx context.Context, userID string) (*JourneyStats, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	return s.store.GetJourneyStats(ctx, userID)
}

// GetJourneyInsights generates insights for a user's journey
func (s *service) GetJourneyInsights(ctx context.Context, userID string) (*JourneyInsights, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	stats, err := s.store.GetJourneyStats(ctx, userID)
	if err != nil {
		return nil, err
	}

	insights := &JourneyInsights{
		MoodPatterns:    []string{},
		Recommendations: []string{},
		Achievements:    []string{},
		NextGoals:       []string{},
	}

	// Generate mood patterns
	if stats.TotalEntries > 0 {
		switch stats.MoodTrend {
		case "improving":
			insights.MoodPatterns = append(insights.MoodPatterns, "Your mood has been improving over time! 📈")
		case "declining":
			insights.MoodPatterns = append(insights.MoodPatterns, "Your mood shows some challenges lately. Consider reaching out for support. 💙")
		default:
			insights.MoodPatterns = append(insights.MoodPatterns, "Your mood has been relatively stable. 📊")
		}

		if stats.AverageMood >= 4.0 {
			insights.MoodPatterns = append(insights.MoodPatterns, "You maintain a positive mood most days! ✨")
		}
	}

	// Generate recommendations
	if stats.CurrentStreak == 0 {
		insights.Recommendations = append(insights.Recommendations, "Start your journey today with a quick mood check-in")
	} else if stats.CurrentStreak < 7 {
		insights.Recommendations = append(insights.Recommendations, "Try to build a weekly habit of daily entries")
	}

	if stats.ActiveGoals == 0 {
		insights.Recommendations = append(insights.Recommendations, "Set your first goal to guide your mental health journey")
	}

	// Generate achievements
	if stats.TotalEntries > 0 {
		insights.Achievements = append(insights.Achievements, fmt.Sprintf("🎯 %d total journal entries", stats.TotalEntries))
	}
	if stats.LongestStreak > 0 {
		insights.Achievements = append(insights.Achievements, fmt.Sprintf("🔥 %d days longest streak", stats.LongestStreak))
	}
	if stats.CompletedGoals > 0 {
		insights.Achievements = append(insights.Achievements, fmt.Sprintf("✅ %d goals completed", stats.CompletedGoals))
	}

	// Generate next goals suggestions
	if stats.ActiveGoals < 3 {
		insights.NextGoals = append(insights.NextGoals, "Daily mood tracking")
		insights.NextGoals = append(insights.NextGoals, "Improve sleep quality")
		insights.NextGoals = append(insights.NextGoals, "Practice mindfulness")
	}

	return insights, nil
}

// ListJourneyMilestones retrieves milestones for a user
func (s *service) ListJourneyMilestones(ctx context.Context, userID string, limit int) ([]JourneyMilestone, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	if limit <= 0 {
		limit = 10
	}

	return s.store.ListJourneyMilestones(ctx, userID, limit)
}

// Helper functions

func validateJourneyEntryRequest(req *CreateJourneyEntryRequest) error {
	// Validate optional ratings
	if req.AnxietyLevel != nil && (*req.AnxietyLevel < 1 || *req.AnxietyLevel > 5) {
		return fmt.Errorf("anxiety level must be between 1 and 5")
	}

	if req.SleepQuality != nil && (*req.SleepQuality < 1 || *req.SleepQuality > 5) {
		return fmt.Errorf("sleep quality must be between 1 and 5")
	}

	if req.EnergyLevel != nil && (*req.EnergyLevel < 1 || *req.EnergyLevel > 5) {
		return fmt.Errorf("energy level must be between 1 and 5")
	}

	// Validate activities and symptoms arrays
	if len(req.Activities) > 10 {
		return fmt.Errorf("too many activities, maximum 10 allowed")
	}

	if len(req.Symptoms) > 10 {
		return fmt.Errorf("too many symptoms, maximum 10 allowed")
	}

	// Validate string lengths
	if req.Notes != nil && len(*req.Notes) > 1000 {
		return fmt.Errorf("notes too long, maximum 1000 characters")
	}

	if req.GratitudeNote != nil && len(*req.GratitudeNote) > 500 {
		return fmt.Errorf("gratitude note too long, maximum 500 characters")
	}

	return nil
}

func isValidGoalType(goalType string) bool {
	validTypes := []string{GoalTypeMood, GoalTypeSleep, GoalTypeExercise, GoalTypeMindfulness, GoalTypeSocial, GoalTypeCustom}
	for _, validType := range validTypes {
		if goalType == validType {
			return true
		}
	}
	return false
}

func isValidGoalStatus(status string) bool {
	validStatuses := []string{GoalStatusActive, GoalStatusCompleted, GoalStatusPaused, GoalStatusCancelled}
	for _, validStatus := range validStatuses {
		if status == validStatus {
			return true
		}
	}
	return false
}

// Milestone checking functions (run in background)
func (s *service) checkAndAwardMilestones(ctx context.Context, userID string) {
	// Check for first entry milestone
	s.checkFirstEntryMilestone(ctx, userID)

	// Check for streak milestones
	s.checkStreakMilestones(ctx, userID)

	// Check for mood stability milestone
	s.checkMoodStabilityMilestone(ctx, userID)
}

func (s *service) checkFirstEntryMilestone(ctx context.Context, userID string) {
	exists, err := s.store.CheckMilestoneExists(ctx, userID, MilestoneFirstEntry)
	if err != nil || exists {
		return
	}

	milestone := &JourneyMilestone{
		UserID:        userID,
		MilestoneType: MilestoneFirstEntry,
		Title:         "First Entry",
		Description:   stringPtr("Congratulations on starting your mental health journey! 🌟"),
		AchievedAt:    time.Now(),
		CreatedAt:     time.Now(),
	}

	s.store.CreateJourneyMilestone(ctx, milestone)
}

func (s *service) checkStreakMilestones(ctx context.Context, userID string) {
	stats, err := s.store.GetJourneyStats(ctx, userID)
	if err != nil {
		return
	}

	// Check for week streak milestone
	if stats.CurrentStreak >= 7 {
		exists, err := s.store.CheckMilestoneExists(ctx, userID, MilestoneWeekStreak)
		if err == nil && !exists {
			milestone := &JourneyMilestone{
				UserID:        userID,
				MilestoneType: MilestoneWeekStreak,
				Title:         "7-Day Streak",
				Description:   stringPtr("Amazing! You've maintained a 7-day streak! 🔥"),
				AchievedAt:    time.Now(),
				CreatedAt:     time.Now(),
			}
			s.store.CreateJourneyMilestone(ctx, milestone)
		}
	}

	// Check for month streak milestone
	if stats.CurrentStreak >= 30 {
		exists, err := s.store.CheckMilestoneExists(ctx, userID, MilestoneMonthStreak)
		if err == nil && !exists {
			milestone := &JourneyMilestone{
				UserID:        userID,
				MilestoneType: MilestoneMonthStreak,
				Title:         "30-Day Streak",
				Description:   stringPtr("Incredible! You've maintained a 30-day streak! 🏆"),
				AchievedAt:    time.Now(),
				CreatedAt:     time.Now(),
			}
			s.store.CreateJourneyMilestone(ctx, milestone)
		}
	}
}

func (s *service) checkMoodStabilityMilestone(ctx context.Context, userID string) {
	stats, err := s.store.GetJourneyStats(ctx, userID)
	if err != nil {
		return
	}

	// Check if user has good average mood for at least 14 days
	if stats.TotalEntries >= 14 && stats.AverageMood >= 4.0 {
		exists, err := s.store.CheckMilestoneExists(ctx, userID, MilestoneMoodStable)
		if err == nil && !exists {
			milestone := &JourneyMilestone{
				UserID:        userID,
				MilestoneType: MilestoneMoodStable,
				Title:         "Mood Stability",
				Description:   stringPtr("You're maintaining great mental wellness! Keep it up! 💙"),
				AchievedAt:    time.Now(),
				CreatedAt:     time.Now(),
			}
			s.store.CreateJourneyMilestone(ctx, milestone)
		}
	}
}

func (s *service) checkFirstGoalMilestone(ctx context.Context, userID string) {
	exists, err := s.store.CheckMilestoneExists(ctx, userID, MilestoneFirstGoal)
	if err != nil || exists {
		return
	}

	milestone := &JourneyMilestone{
		UserID:        userID,
		MilestoneType: MilestoneFirstGoal,
		Title:         "First Goal Set",
		Description:   stringPtr("Great job setting your first goal! 🎯"),
		AchievedAt:    time.Now(),
		CreatedAt:     time.Now(),
	}

	s.store.CreateJourneyMilestone(ctx, milestone)
}

// Helper function
func stringPtr(s string) *string {
	return &s
}
