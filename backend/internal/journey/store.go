package journey

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
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

// Journey Entries Implementation

func (s *store) CreateJourneyEntry(ctx context.Context, userID string, entryDate time.Time, req *CreateJourneyEntryRequest) (*JourneyEntry, error) {
	// Check if entry already exists for this date
	existingEntry, err := s.GetJourneyEntryByDate(ctx, userID, entryDate.Format("2006-01-02"))
	if err == nil && existingEntry != nil {
		return nil, fmt.Errorf("entry already exists for this date")
	}

	entryID := uuid.New()
	entry := &JourneyEntry{
		ID:            entryID.String(),
		UserID:        userID,
		EntryDate:     entryDate,
		MoodRating:    req.MoodRating,
		AnxietyLevel:  req.AnxietyLevel,
		SleepQuality:  req.SleepQuality,
		EnergyLevel:   req.EnergyLevel,
		Notes:         req.Notes,
		Activities:    req.Activities,
		Symptoms:      req.Symptoms,
		GratitudeNote: req.GratitudeNote,
		IsPrivate:     req.IsPrivate,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
	}

	query := `
		INSERT INTO journey_entries (
			id, user_id, entry_date, mood_rating, anxiety_level, sleep_quality, 
			energy_level, notes, activities, symptoms, gratitude_note, is_private, 
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
		)
	`

	_, err = s.db.Exec(ctx, query,
		entry.ID, entry.UserID, entry.EntryDate, entry.MoodRating,
		entry.AnxietyLevel, entry.SleepQuality, entry.EnergyLevel,
		entry.Notes, pq.Array(entry.Activities), pq.Array(entry.Symptoms),
		entry.GratitudeNote, entry.IsPrivate, entry.CreatedAt, entry.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create journey entry: %w", err)
	}

	return entry, nil
}

func (s *store) GetJourneyEntryByID(ctx context.Context, userID, entryID string) (*JourneyEntry, error) {
	query := `
		SELECT id, user_id, entry_date, mood_rating, anxiety_level, sleep_quality,
			   energy_level, notes, activities, symptoms, gratitude_note, is_private,
			   created_at, updated_at
		FROM journey_entries
		WHERE id = $1 AND user_id = $2
	`

	row := s.db.QueryRow(ctx, query, entryID, userID)
	return s.scanJourneyEntry(row)
}

func (s *store) GetJourneyEntryByDate(ctx context.Context, userID, date string) (*JourneyEntry, error) {
	query := `
		SELECT id, user_id, entry_date, mood_rating, anxiety_level, sleep_quality,
			   energy_level, notes, activities, symptoms, gratitude_note, is_private,
			   created_at, updated_at
		FROM journey_entries
		WHERE user_id = $1 AND DATE(entry_date) = $2
	`

	row := s.db.QueryRow(ctx, query, userID, date)
	return s.scanJourneyEntry(row)
}

func (s *store) UpdateJourneyEntry(ctx context.Context, userID, entryID string, req *UpdateJourneyEntryRequest) (*JourneyEntry, error) {
	// Build dynamic update query
	setParts := []string{"updated_at = NOW()"}
	args := []interface{}{userID, entryID}
	argIndex := 3

	if req.MoodRating != nil {
		setParts = append(setParts, fmt.Sprintf("mood_rating = $%d", argIndex))
		args = append(args, *req.MoodRating)
		argIndex++
	}

	if req.AnxietyLevel != nil {
		setParts = append(setParts, fmt.Sprintf("anxiety_level = $%d", argIndex))
		args = append(args, *req.AnxietyLevel)
		argIndex++
	}

	if req.SleepQuality != nil {
		setParts = append(setParts, fmt.Sprintf("sleep_quality = $%d", argIndex))
		args = append(args, *req.SleepQuality)
		argIndex++
	}

	if req.EnergyLevel != nil {
		setParts = append(setParts, fmt.Sprintf("energy_level = $%d", argIndex))
		args = append(args, *req.EnergyLevel)
		argIndex++
	}

	if req.Notes != nil {
		setParts = append(setParts, fmt.Sprintf("notes = $%d", argIndex))
		args = append(args, *req.Notes)
		argIndex++
	}

	if req.Activities != nil {
		setParts = append(setParts, fmt.Sprintf("activities = $%d", argIndex))
		args = append(args, pq.Array(req.Activities))
		argIndex++
	}

	if req.Symptoms != nil {
		setParts = append(setParts, fmt.Sprintf("symptoms = $%d", argIndex))
		args = append(args, pq.Array(req.Symptoms))
		argIndex++
	}

	if req.GratitudeNote != nil {
		setParts = append(setParts, fmt.Sprintf("gratitude_note = $%d", argIndex))
		args = append(args, *req.GratitudeNote)
		argIndex++
	}

	if req.IsPrivate != nil {
		setParts = append(setParts, fmt.Sprintf("is_private = $%d", argIndex))
		args = append(args, *req.IsPrivate)
		argIndex++
	}

	if len(setParts) == 1 {
		// Only updated_at was set, no actual changes
		return s.GetJourneyEntryByID(ctx, userID, entryID)
	}

	query := fmt.Sprintf(`
		UPDATE journey_entries 
		SET %s
		WHERE user_id = $1 AND id = $2
		RETURNING id, user_id, entry_date, mood_rating, anxiety_level, sleep_quality,
				  energy_level, notes, activities, symptoms, gratitude_note, is_private,
				  created_at, updated_at
	`, strings.Join(setParts, ", "))

	row := s.db.QueryRow(ctx, query, args...)
	return s.scanJourneyEntry(row)
}

func (s *store) DeleteJourneyEntry(ctx context.Context, userID, entryID string) error {
	query := `DELETE FROM journey_entries WHERE user_id = $1 AND id = $2`

	result, err := s.db.Exec(ctx, query, userID, entryID)
	if err != nil {
		return fmt.Errorf("failed to delete journey entry: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("journey entry not found")
	}

	return nil
}

func (s *store) ListJourneyEntries(ctx context.Context, userID string, page, pageSize int, startDate, endDate *string) (*ListJourneyEntriesResponse, error) {
	// Count total entries
	countQuery := `SELECT COUNT(*) FROM journey_entries WHERE user_id = $1`
	countArgs := []interface{}{userID}

	if startDate != nil && *startDate != "" {
		countQuery += ` AND entry_date >= $2`
		countArgs = append(countArgs, *startDate)

		if endDate != nil && *endDate != "" {
			countQuery += ` AND entry_date <= $3`
			countArgs = append(countArgs, *endDate)
		}
	} else if endDate != nil && *endDate != "" {
		countQuery += ` AND entry_date <= $2`
		countArgs = append(countArgs, *endDate)
	}

	var total int64
	err := s.db.QueryRow(ctx, countQuery, countArgs...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count journey entries: %w", err)
	}

	// Calculate pagination
	offset := (page - 1) * pageSize
	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))

	// Initialize empty entries slice - this ensures we never return nil
	entries := make([]JourneyEntry, 0)

	// Only query if there are entries to avoid unnecessary database calls
	if total > 0 {
		// Get entries
		query := `
			SELECT id, user_id, entry_date, mood_rating, anxiety_level, sleep_quality,
				   energy_level, notes, activities, symptoms, gratitude_note, is_private,
				   created_at, updated_at
			FROM journey_entries
			WHERE user_id = $1
		`
		args := []interface{}{userID}
		argIndex := 2

		if startDate != nil && *startDate != "" {
			query += fmt.Sprintf(` AND entry_date >= $%d`, argIndex)
			args = append(args, *startDate)
			argIndex++

			if endDate != nil && *endDate != "" {
				query += fmt.Sprintf(` AND entry_date <= $%d`, argIndex)
				args = append(args, *endDate)
				argIndex++
			}
		} else if endDate != nil && *endDate != "" {
			query += fmt.Sprintf(` AND entry_date <= $%d`, argIndex)
			args = append(args, *endDate)
			argIndex++
		}

		query += fmt.Sprintf(` ORDER BY entry_date DESC LIMIT $%d OFFSET $%d`, argIndex, argIndex+1)
		args = append(args, pageSize, offset)

		rows, err := s.db.Query(ctx, query, args...)
		if err != nil {
			return nil, fmt.Errorf("failed to list journey entries: %w", err)
		}
		defer rows.Close()

		for rows.Next() {
			entry, err := s.scanJourneyEntryFromRows(rows)
			if err != nil {
				return nil, fmt.Errorf("failed to scan journey entry: %w", err)
			}
			entries = append(entries, *entry)
		}
	}

	return &ListJourneyEntriesResponse{
		Entries:    entries,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
	}, nil
}

// Journey Goals Implementation

func (s *store) CreateJourneyGoal(ctx context.Context, userID string, req *CreateJourneyGoalRequest, targetDate *time.Time) (*JourneyGoal, error) {
	goalID := uuid.New()
	goal := &JourneyGoal{
		ID:          goalID.String(),
		UserID:      userID,
		Title:       req.Title,
		Description: req.Description,
		TargetDate:  targetDate,
		GoalType:    req.GoalType,
		Status:      GoalStatusActive,
		IsCompleted: false,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	query := `
		INSERT INTO journey_goals (
			id, user_id, title, description, target_date, goal_type, status,
			is_completed, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10
		)
	`

	_, err := s.db.Exec(ctx, query,
		goal.ID, goal.UserID, goal.Title, goal.Description, goal.TargetDate,
		goal.GoalType, goal.Status, goal.IsCompleted, goal.CreatedAt, goal.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create journey goal: %w", err)
	}

	return goal, nil
}

func (s *store) UpdateJourneyGoal(ctx context.Context, userID, goalID string, req *UpdateJourneyGoalRequest, targetDate *time.Time) (*JourneyGoal, error) {
	// Build dynamic update query
	setParts := []string{"updated_at = NOW()"}
	args := []interface{}{userID, goalID}
	argIndex := 3

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

	if targetDate != nil {
		setParts = append(setParts, fmt.Sprintf("target_date = $%d", argIndex))
		args = append(args, targetDate)
		argIndex++
	}

	if req.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, *req.Status)
		argIndex++

		// If status is completed, set completion date and flag
		if *req.Status == GoalStatusCompleted {
			setParts = append(setParts, fmt.Sprintf("is_completed = true, completed_at = $%d", argIndex))
			args = append(args, time.Now())
			argIndex++
		} else {
			setParts = append(setParts, "is_completed = false, completed_at = NULL")
		}
	}

	query := fmt.Sprintf(`
		UPDATE journey_goals 
		SET %s
		WHERE user_id = $1 AND id = $2
		RETURNING id, user_id, title, description, target_date, goal_type, status,
				  is_completed, completed_at, created_at, updated_at
	`, strings.Join(setParts, ", "))

	row := s.db.QueryRow(ctx, query, args...)
	return s.scanJourneyGoal(row)
}

func (s *store) DeleteJourneyGoal(ctx context.Context, userID, goalID string) error {
	query := `DELETE FROM journey_goals WHERE user_id = $1 AND id = $2`

	result, err := s.db.Exec(ctx, query, userID, goalID)
	if err != nil {
		return fmt.Errorf("failed to delete journey goal: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("journey goal not found")
	}

	return nil
}

func (s *store) ListJourneyGoals(ctx context.Context, userID string, status *string) ([]JourneyGoal, error) {
	query := `
		SELECT id, user_id, title, description, target_date, goal_type, status,
			   is_completed, completed_at, created_at, updated_at
		FROM journey_goals
		WHERE user_id = $1
	`
	args := []interface{}{userID}

	if status != nil && *status != "" {
		query += ` AND status = $2`
		args = append(args, *status)
	}

	query += ` ORDER BY created_at DESC`

	rows, err := s.db.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list journey goals: %w", err)
	}
	defer rows.Close()

	// Initialize empty slice to ensure we never return nil
	goals := make([]JourneyGoal, 0)
	for rows.Next() {
		goal, err := s.scanJourneyGoalFromRows(rows)
		if err != nil {
			return nil, fmt.Errorf("failed to scan journey goal: %w", err)
		}
		goals = append(goals, *goal)
	}

	return goals, nil
}

// Journey Milestones Implementation

func (s *store) CreateJourneyMilestone(ctx context.Context, milestone *JourneyMilestone) error {
	if milestone.ID == "" {
		milestoneID := uuid.New()
		milestone.ID = milestoneID.String()
	}

	query := `
		INSERT INTO journey_milestones (
			id, user_id, milestone_type, title, description, achieved_at, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7
		)
	`

	_, err := s.db.Exec(ctx, query,
		milestone.ID, milestone.UserID, milestone.MilestoneType,
		milestone.Title, milestone.Description, milestone.AchievedAt, milestone.CreatedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to create journey milestone: %w", err)
	}

	return nil
}

func (s *store) ListJourneyMilestones(ctx context.Context, userID string, limit int) ([]JourneyMilestone, error) {
	query := `
		SELECT id, user_id, milestone_type, title, description, achieved_at, created_at
		FROM journey_milestones
		WHERE user_id = $1
		ORDER BY achieved_at DESC
		LIMIT $2
	`

	rows, err := s.db.Query(ctx, query, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list journey milestones: %w", err)
	}
	defer rows.Close()

	// Initialize empty slice to ensure we never return nil
	milestones := make([]JourneyMilestone, 0)
	for rows.Next() {
		milestone, err := s.scanJourneyMilestoneFromRows(rows)
		if err != nil {
			return nil, fmt.Errorf("failed to scan journey milestone: %w", err)
		}
		milestones = append(milestones, *milestone)
	}

	return milestones, nil
}

func (s *store) CheckMilestoneExists(ctx context.Context, userID, milestoneType string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM journey_milestones WHERE user_id = $1 AND milestone_type = $2)`

	var exists bool
	err := s.db.QueryRow(ctx, query, userID, milestoneType).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check milestone existence: %w", err)
	}

	return exists, nil
}

// Journey Analytics Implementation

func (s *store) GetJourneyStats(ctx context.Context, userID string) (*JourneyStats, error) {
	stats := &JourneyStats{
		MoodBreakdown:    make(map[string]int64),
		WeeklyMoodData:   make([]DailyMoodData, 0),
		RecentMilestones: make([]JourneyMilestone, 0),
	}

	// Get total entries
	err := s.db.QueryRow(ctx,
		`SELECT COUNT(*) FROM journey_entries WHERE user_id = $1`,
		userID).Scan(&stats.TotalEntries)
	if err != nil {
		return nil, fmt.Errorf("failed to get total entries: %w", err)
	}

	// Get current and longest streak
	stats.CurrentStreak, stats.LongestStreak = s.calculateStreaks(ctx, userID)

	// Get average mood
	err = s.db.QueryRow(ctx,
		`SELECT COALESCE(AVG(mood_rating), 0) FROM journey_entries WHERE user_id = $1`,
		userID).Scan(&stats.AverageMood)
	if err != nil {
		return nil, fmt.Errorf("failed to get average mood: %w", err)
	}

	// Get mood trend
	stats.MoodTrend = s.calculateMoodTrend(ctx, userID)

	// Get goal counts
	err = s.db.QueryRow(ctx,
		`SELECT COUNT(*) FROM journey_goals WHERE user_id = $1 AND status = 'completed'`,
		userID).Scan(&stats.CompletedGoals)
	if err != nil {
		stats.CompletedGoals = 0
	}

	err = s.db.QueryRow(ctx,
		`SELECT COUNT(*) FROM journey_goals WHERE user_id = $1 AND status = 'active'`,
		userID).Scan(&stats.ActiveGoals)
	if err != nil {
		stats.ActiveGoals = 0
	}

	// Get total milestones
	err = s.db.QueryRow(ctx,
		`SELECT COUNT(*) FROM journey_milestones WHERE user_id = $1`,
		userID).Scan(&stats.TotalMilestones)
	if err != nil {
		stats.TotalMilestones = 0
	}

	// Get recent milestones - ensure we get a slice, not nil
	recentMilestones, err := s.ListJourneyMilestones(ctx, userID, 3)
	if err == nil && recentMilestones != nil {
		stats.RecentMilestones = recentMilestones
	}

	// Get mood breakdown
	rows, err := s.db.Query(ctx,
		`SELECT mood_rating, COUNT(*) FROM journey_entries WHERE user_id = $1 GROUP BY mood_rating`,
		userID)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var moodRating int
			var count int64
			if rows.Scan(&moodRating, &count) == nil {
				stats.MoodBreakdown[fmt.Sprintf("%d", moodRating)] = count
			}
		}
	}

	// Get weekly mood data (last 7 days)
	weeklyData := s.getWeeklyMoodData(ctx, userID)
	if weeklyData != nil {
		stats.WeeklyMoodData = weeklyData
	}

	return stats, nil
}

// Helper functions

func (s *store) scanJourneyEntry(row pgx.Row) (*JourneyEntry, error) {
	entry := &JourneyEntry{}
	var activities, symptoms pq.StringArray

	err := row.Scan(
		&entry.ID, &entry.UserID, &entry.EntryDate, &entry.MoodRating,
		&entry.AnxietyLevel, &entry.SleepQuality, &entry.EnergyLevel,
		&entry.Notes, &activities, &symptoms, &entry.GratitudeNote,
		&entry.IsPrivate, &entry.CreatedAt, &entry.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("journey entry not found")
		}
		return nil, err
	}

	// Ensure arrays are never nil
	if activities == nil {
		entry.Activities = make([]string, 0)
	} else {
		entry.Activities = []string(activities)
	}

	if symptoms == nil {
		entry.Symptoms = make([]string, 0)
	} else {
		entry.Symptoms = []string(symptoms)
	}

	return entry, nil
}

func (s *store) scanJourneyEntryFromRows(rows pgx.Rows) (*JourneyEntry, error) {
	entry := &JourneyEntry{}
	var activities, symptoms pq.StringArray

	err := rows.Scan(
		&entry.ID, &entry.UserID, &entry.EntryDate, &entry.MoodRating,
		&entry.AnxietyLevel, &entry.SleepQuality, &entry.EnergyLevel,
		&entry.Notes, &activities, &symptoms, &entry.GratitudeNote,
		&entry.IsPrivate, &entry.CreatedAt, &entry.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	// Ensure arrays are never nil
	if activities == nil {
		entry.Activities = make([]string, 0)
	} else {
		entry.Activities = []string(activities)
	}

	if symptoms == nil {
		entry.Symptoms = make([]string, 0)
	} else {
		entry.Symptoms = []string(symptoms)
	}

	return entry, nil
}

func (s *store) scanJourneyGoal(row pgx.Row) (*JourneyGoal, error) {
	goal := &JourneyGoal{}

	err := row.Scan(
		&goal.ID, &goal.UserID, &goal.Title, &goal.Description,
		&goal.TargetDate, &goal.GoalType, &goal.Status,
		&goal.IsCompleted, &goal.CompletedAt, &goal.CreatedAt, &goal.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("journey goal not found")
		}
		return nil, err
	}

	return goal, nil
}

func (s *store) scanJourneyGoalFromRows(rows pgx.Rows) (*JourneyGoal, error) {
	goal := &JourneyGoal{}

	err := rows.Scan(
		&goal.ID, &goal.UserID, &goal.Title, &goal.Description,
		&goal.TargetDate, &goal.GoalType, &goal.Status,
		&goal.IsCompleted, &goal.CompletedAt, &goal.CreatedAt, &goal.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return goal, nil
}

func (s *store) scanJourneyMilestoneFromRows(rows pgx.Rows) (*JourneyMilestone, error) {
	milestone := &JourneyMilestone{}

	err := rows.Scan(
		&milestone.ID, &milestone.UserID, &milestone.MilestoneType,
		&milestone.Title, &milestone.Description, &milestone.AchievedAt, &milestone.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	return milestone, nil
}

func (s *store) calculateStreaks(ctx context.Context, userID string) (int, int) {
	// Get all entry dates ordered by date desc
	query := `
		SELECT DATE(entry_date) as entry_date 
		FROM journey_entries 
		WHERE user_id = $1 
		ORDER BY entry_date DESC
	`

	rows, err := s.db.Query(ctx, query, userID)
	if err != nil {
		return 0, 0
	}
	defer rows.Close()

	var dates []time.Time
	for rows.Next() {
		var date time.Time
		if rows.Scan(&date) == nil {
			dates = append(dates, date)
		}
	}

	if len(dates) == 0 {
		return 0, 0
	}

	// Calculate current streak
	currentStreak := 0
	today := time.Now().Truncate(24 * time.Hour)
	expectedDate := today

	for _, date := range dates {
		dateOnly := date.Truncate(24 * time.Hour)
		if dateOnly.Equal(expectedDate) {
			currentStreak++
			expectedDate = expectedDate.AddDate(0, 0, -1)
		} else if dateOnly.Before(expectedDate) {
			// If we find a date before the expected date, check if it's yesterday
			// (allowing for gaps in the current streak calculation)
			if currentStreak == 0 && dateOnly.Equal(today.AddDate(0, 0, -1)) {
				currentStreak++
				expectedDate = dateOnly.AddDate(0, 0, -1)
			} else {
				break
			}
		}
	}

	// Calculate longest streak
	longestStreak := 0
	tempStreak := 1

	for i := 1; i < len(dates); i++ {
		prevDate := dates[i-1].Truncate(24 * time.Hour)
		currDate := dates[i].Truncate(24 * time.Hour)

		// Check if dates are consecutive
		if prevDate.AddDate(0, 0, -1).Equal(currDate) {
			tempStreak++
		} else {
			if tempStreak > longestStreak {
				longestStreak = tempStreak
			}
			tempStreak = 1
		}
	}

	if tempStreak > longestStreak {
		longestStreak = tempStreak
	}

	return currentStreak, longestStreak
}

func (s *store) calculateMoodTrend(ctx context.Context, userID string) string {
	// Get mood ratings from last 14 days vs previous 14 days
	query := `
		SELECT 
			AVG(CASE WHEN entry_date >= CURRENT_DATE - INTERVAL '14 days' THEN mood_rating END) as recent_avg,
			AVG(CASE WHEN entry_date >= CURRENT_DATE - INTERVAL '28 days' AND entry_date < CURRENT_DATE - INTERVAL '14 days' THEN mood_rating END) as previous_avg
		FROM journey_entries 
		WHERE user_id = $1
	`

	var recentAvg, previousAvg sql.NullFloat64
	err := s.db.QueryRow(ctx, query, userID).Scan(&recentAvg, &previousAvg)
	if err != nil || !recentAvg.Valid || !previousAvg.Valid {
		return "stable"
	}

	diff := recentAvg.Float64 - previousAvg.Float64
	if diff > 0.3 {
		return "improving"
	} else if diff < -0.3 {
		return "declining"
	}

	return "stable"
}

func (s *store) getWeeklyMoodData(ctx context.Context, userID string) []DailyMoodData {
	// Initialize with empty slice to ensure we never return nil
	weeklyData := make([]DailyMoodData, 0, 7)

	// Generate last 7 days
	for i := 6; i >= 0; i-- {
		date := time.Now().AddDate(0, 0, -i)
		dateStr := date.Format("2006-01-02")

		// Check if there's an entry for this date
		var moodRating sql.NullInt32
		query := `SELECT mood_rating FROM journey_entries WHERE user_id = $1 AND DATE(entry_date) = $2`
		err := s.db.QueryRow(ctx, query, userID, dateStr).Scan(&moodRating)

		dayData := DailyMoodData{
			Date:     dateStr,
			HasEntry: err == nil && moodRating.Valid,
		}

		if dayData.HasEntry {
			rating := int(moodRating.Int32)
			dayData.MoodRating = &rating
		}

		weeklyData = append(weeklyData, dayData)
	}

	return weeklyData
}
