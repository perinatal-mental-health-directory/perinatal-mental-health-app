package feedback

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Store struct {
	db *pgxpool.Pool
}

func NewStore(db *pgxpool.Pool) FeedbackStoreInterface {
	return &Store{
		db: db,
	}
}

// CreateFeedback creates new feedback
func (s *Store) CreateFeedback(ctx context.Context, req *CreateFeedbackRequest, userID *string) (*Feedback, error) {
	var feedback Feedback

	query := `
		INSERT INTO feedback (user_id, anonymous, rating, feedback, category, is_active)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, user_id, anonymous, rating, feedback, category, is_active, created_at, updated_at
	`

	err := s.db.QueryRow(ctx, query, userID, req.Anonymous, req.Rating, req.Message, req.Category, true).Scan(
		&feedback.ID,
		&feedback.UserID,
		&feedback.Anonymous,
		&feedback.Rating,
		&feedback.Message,
		&feedback.Category,
		&feedback.IsActive,
		&feedback.CreatedAt,
		&feedback.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create feedback: %w", err)
	}

	return &feedback, nil
}

// ListFeedback retrieves a paginated list of feedback with filters
func (s *Store) ListFeedback(ctx context.Context, page, pageSize int, category, rating string) (*ListFeedbackResponse, error) {
	return s.ListFeedbackWithFilter(ctx, &FeedbackFilter{
		Category: category,
		Rating:   rating,
		Page:     page,
		PageSize: pageSize,
	})
}

// ListFeedbackWithFilter retrieves a paginated list of feedback with advanced filters
func (s *Store) ListFeedbackWithFilter(ctx context.Context, filter *FeedbackFilter) (*ListFeedbackResponse, error) {
	if filter.Page < 1 {
		filter.Page = 1
	}
	if filter.PageSize < 1 || filter.PageSize > 100 {
		filter.PageSize = 20
	}

	offset := (filter.Page - 1) * filter.PageSize

	// Build WHERE clause for filters
	var whereConditions []string
	var args []interface{}
	argIndex := 1

	whereConditions = append(whereConditions, "f.is_active = true")

	if filter.Category != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("f.category = $%d", argIndex))
		args = append(args, filter.Category)
		argIndex++
	}

	if filter.Rating != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("f.rating = $%d", argIndex))
		args = append(args, filter.Rating)
		argIndex++
	}

	if filter.Anonymous != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("f.anonymous = $%d", argIndex))
		args = append(args, *filter.Anonymous)
		argIndex++
	}

	if filter.UserID != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("f.user_id = $%d", argIndex))
		args = append(args, filter.UserID)
		argIndex++
	}

	if filter.StartDate != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("f.created_at >= $%d", argIndex))
		args = append(args, *filter.StartDate)
		argIndex++
	}

	if filter.EndDate != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("f.created_at <= $%d", argIndex))
		args = append(args, *filter.EndDate)
		argIndex++
	}

	whereClause := "WHERE " + strings.Join(whereConditions, " AND ")

	// Count total records
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM feedback f %s", whereClause)
	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count feedback: %w", err)
	}

	// Get feedback records
	listQuery := fmt.Sprintf(`
		SELECT f.id, f.user_id, f.anonymous, f.rating, f.feedback, f.category, f.is_active, f.created_at, f.updated_at
		FROM feedback f
		%s
		ORDER BY f.created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, argIndex, argIndex+1)

	args = append(args, filter.PageSize, offset)

	rows, err := s.db.Query(ctx, listQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query feedback: %w", err)
	}
	defer rows.Close()

	var feedbacks []Feedback
	for rows.Next() {
		var feedback Feedback
		err := rows.Scan(
			&feedback.ID,
			&feedback.UserID,
			&feedback.Anonymous,
			&feedback.Rating,
			&feedback.Message,
			&feedback.Category,
			&feedback.IsActive,
			&feedback.CreatedAt,
			&feedback.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan feedback: %w", err)
		}
		feedbacks = append(feedbacks, feedback)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating feedback rows: %w", err)
	}

	totalPages := int((total + int64(filter.PageSize) - 1) / int64(filter.PageSize))

	return &ListFeedbackResponse{
		Feedback:   feedbacks,
		Total:      total,
		Page:       filter.Page,
		PageSize:   filter.PageSize,
		TotalPages: totalPages,
	}, nil
}

// ListFeedbackWithUser retrieves feedback with user information (for admin views)
func (s *Store) ListFeedbackWithUser(ctx context.Context, filter *FeedbackFilter) (*ListFeedbackResponse, error) {
	if filter.Page < 1 {
		filter.Page = 1
	}
	if filter.PageSize < 1 || filter.PageSize > 100 {
		filter.PageSize = 20
	}

	offset := (filter.Page - 1) * filter.PageSize

	// Build WHERE clause for filters
	var whereConditions []string
	var args []interface{}
	argIndex := 1

	whereConditions = append(whereConditions, "f.is_active = true")

	if filter.Category != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("f.category = $%d", argIndex))
		args = append(args, filter.Category)
		argIndex++
	}

	if filter.Rating != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("f.rating = $%d", argIndex))
		args = append(args, filter.Rating)
		argIndex++
	}

	if filter.Anonymous != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("f.anonymous = $%d", argIndex))
		args = append(args, *filter.Anonymous)
		argIndex++
	}

	if filter.UserID != "" {
		whereConditions = append(whereConditions, fmt.Sprintf("f.user_id = $%d", argIndex))
		args = append(args, filter.UserID)
		argIndex++
	}

	if filter.StartDate != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("f.created_at >= $%d", argIndex))
		args = append(args, *filter.StartDate)
		argIndex++
	}

	if filter.EndDate != nil {
		whereConditions = append(whereConditions, fmt.Sprintf("f.created_at <= $%d", argIndex))
		args = append(args, *filter.EndDate)
		argIndex++
	}

	whereClause := "WHERE " + strings.Join(whereConditions, " AND ")

	// Count total records
	countQuery := fmt.Sprintf(`
		SELECT COUNT(*) 
		FROM feedback f 
		LEFT JOIN users u ON f.user_id = u.id 
		%s
	`, whereClause)

	var total int64
	err := s.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count feedback with user: %w", err)
	}

	// Get feedback records with user information
	listQuery := fmt.Sprintf(`
		SELECT f.id, f.user_id, f.anonymous, f.rating, f.feedback, f.category, f.is_active, f.created_at, f.updated_at,
		       u.full_name, u.email, u.role
		FROM feedback f
		LEFT JOIN users u ON f.user_id = u.id
		%s
		ORDER BY f.created_at DESC
		LIMIT $%d OFFSET $%d
	`, whereClause, argIndex, argIndex+1)

	args = append(args, filter.PageSize, offset)

	rows, err := s.db.Query(ctx, listQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query feedback with user: %w", err)
	}
	defer rows.Close()

	var feedbacks []Feedback
	for rows.Next() {
		var feedback Feedback
		var userName, userEmail, userRole *string

		err := rows.Scan(
			&feedback.ID,
			&feedback.UserID,
			&feedback.Anonymous,
			&feedback.Rating,
			&feedback.Message,
			&feedback.Category,
			&feedback.IsActive,
			&feedback.CreatedAt,
			&feedback.UpdatedAt,
			&userName,
			&userEmail,
			&userRole,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan feedback with user: %w", err)
		}

		// Note: You might want to create a separate response type that includes user info
		// For now, we're just returning the feedback without user info in the response
		feedbacks = append(feedbacks, feedback)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating feedback with user rows: %w", err)
	}

	totalPages := int((total + int64(filter.PageSize) - 1) / int64(filter.PageSize))

	return &ListFeedbackResponse{
		Feedback:   feedbacks,
		Total:      total,
		Page:       filter.Page,
		PageSize:   filter.PageSize,
		TotalPages: totalPages,
	}, nil
}

// GetFeedbackStats retrieves comprehensive feedback statistics
func (s *Store) GetFeedbackStats(ctx context.Context) (*FeedbackStats, error) {
	var stats FeedbackStats
	stats.RatingBreakdown = make(map[string]int64)
	stats.CategoryBreakdown = make(map[string]int64)

	// Get total feedback count
	err := s.db.QueryRow(ctx, "SELECT COUNT(*) FROM feedback WHERE is_active = true").Scan(&stats.TotalFeedback)
	if err != nil {
		return nil, fmt.Errorf("failed to get total feedback count: %w", err)
	}

	// Get anonymous vs authenticated counts
	anonymousQuery := `
		SELECT 
			SUM(CASE WHEN anonymous = true THEN 1 ELSE 0 END) as anonymous_count,
			SUM(CASE WHEN anonymous = false THEN 1 ELSE 0 END) as authenticated_count
		FROM feedback 
		WHERE is_active = true
	`
	err = s.db.QueryRow(ctx, anonymousQuery).Scan(&stats.TotalAnonymous, &stats.TotalAuthenticated)
	if err != nil {
		return nil, fmt.Errorf("failed to get anonymous/authenticated counts: %w", err)
	}

	// Get rating breakdown and calculate average
	ratingQuery := `
		SELECT rating, COUNT(*) 
		FROM feedback 
		WHERE is_active = true 
		GROUP BY rating
	`
	rows, err := s.db.Query(ctx, ratingQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to get rating breakdown: %w", err)
	}
	defer rows.Close()

	var totalRatingValue, totalRatings int64
	for rows.Next() {
		var rating string
		var count int64
		if err := rows.Scan(&rating, &count); err != nil {
			return nil, fmt.Errorf("failed to scan rating breakdown: %w", err)
		}
		stats.RatingBreakdown[rating] = count

		// Calculate weighted average
		ratingValue := GetRatingValue(rating)
		totalRatingValue += int64(ratingValue) * count
		totalRatings += count
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rating breakdown rows: %w", err)
	}

	// Calculate average rating
	if totalRatings > 0 {
		stats.AverageRating = float64(totalRatingValue) / float64(totalRatings)
	}

	// Get category breakdown
	categoryQuery := `
		SELECT category, COUNT(*) 
		FROM feedback 
		WHERE is_active = true 
		GROUP BY category
	`
	rows, err = s.db.Query(ctx, categoryQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to get category breakdown: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var category string
		var count int64
		if err := rows.Scan(&category, &count); err != nil {
			return nil, fmt.Errorf("failed to scan category breakdown: %w", err)
		}
		stats.CategoryBreakdown[category] = count
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating category breakdown rows: %w", err)
	}

	// Get recent feedback (last 10)
	recentQuery := `
		SELECT id, user_id, anonymous, rating, feedback, category, is_active, created_at, updated_at
		FROM feedback
		WHERE is_active = true
		ORDER BY created_at DESC
		LIMIT 10
	`
	rows, err = s.db.Query(ctx, recentQuery)
	if err != nil {
		return nil, fmt.Errorf("failed to get recent feedback: %w", err)
	}
	defer rows.Close()

	var recentFeedback []Feedback
	for rows.Next() {
		var feedback Feedback
		err := rows.Scan(
			&feedback.ID,
			&feedback.UserID,
			&feedback.Anonymous,
			&feedback.Rating,
			&feedback.Message,
			&feedback.Category,
			&feedback.IsActive,
			&feedback.CreatedAt,
			&feedback.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan recent feedback: %w", err)
		}
		recentFeedback = append(recentFeedback, feedback)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating recent feedback rows: %w", err)
	}

	stats.RecentFeedback = recentFeedback

	return &stats, nil
}

// GetFeedbackByID retrieves a single feedback by ID
func (s *Store) GetFeedbackByID(ctx context.Context, feedbackID string) (*Feedback, error) {
	var feedback Feedback

	query := `
		SELECT id, user_id, anonymous, rating, feedback, category, is_active, created_at, updated_at
		FROM feedback
		WHERE id = $1 AND is_active = true
	`

	err := s.db.QueryRow(ctx, query, feedbackID).Scan(
		&feedback.ID,
		&feedback.UserID,
		&feedback.Anonymous,
		&feedback.Rating,
		&feedback.Message,
		&feedback.Category,
		&feedback.IsActive,
		&feedback.CreatedAt,
		&feedback.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("feedback not found")
		}
		return nil, fmt.Errorf("failed to get feedback: %w", err)
	}

	return &feedback, nil
}

// UpdateFeedbackStatus updates the status of a feedback (for admin use)
func (s *Store) UpdateFeedbackStatus(ctx context.Context, feedbackID string, isActive bool) error {
	query := `
		UPDATE feedback 
		SET is_active = $1, updated_at = CURRENT_TIMESTAMP
		WHERE id = $2
	`

	result, err := s.db.Exec(ctx, query, isActive, feedbackID)
	if err != nil {
		return fmt.Errorf("failed to update feedback status: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("feedback not found")
	}

	return nil
}

// UpdateFeedback updates feedback content (for user edits)
func (s *Store) UpdateFeedback(ctx context.Context, feedbackID string, req *UpdateFeedbackRequest) (*Feedback, error) {
	// Build dynamic update query
	var setParts []string
	var args []interface{}
	argIndex := 1

	if req.Rating != nil {
		setParts = append(setParts, fmt.Sprintf("rating = $%d", argIndex))
		args = append(args, *req.Rating)
		argIndex++
	}

	if req.Message != nil {
		setParts = append(setParts, fmt.Sprintf("feedback = $%d", argIndex))
		args = append(args, *req.Message)
		argIndex++
	}

	if req.Category != nil {
		setParts = append(setParts, fmt.Sprintf("category = $%d", argIndex))
		args = append(args, *req.Category)
		argIndex++
	}

	if req.IsActive != nil {
		setParts = append(setParts, fmt.Sprintf("is_active = $%d", argIndex))
		args = append(args, *req.IsActive)
		argIndex++
	}

	if len(setParts) == 0 {
		return nil, fmt.Errorf("no fields to update")
	}

	// Always update the updated_at field
	setParts = append(setParts, "updated_at = CURRENT_TIMESTAMP")

	query := fmt.Sprintf(`
		UPDATE feedback 
		SET %s
		WHERE id = $%d
		RETURNING id, user_id, anonymous, rating, feedback, category, is_active, created_at, updated_at
	`, strings.Join(setParts, ", "), argIndex)

	args = append(args, feedbackID)

	var feedback Feedback
	err := s.db.QueryRow(ctx, query, args...).Scan(
		&feedback.ID,
		&feedback.UserID,
		&feedback.Anonymous,
		&feedback.Rating,
		&feedback.Message,
		&feedback.Category,
		&feedback.IsActive,
		&feedback.CreatedAt,
		&feedback.UpdatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("feedback not found")
		}
		return nil, fmt.Errorf("failed to update feedback: %w", err)
	}

	return &feedback, nil
}

// GetUserFeedback retrieves feedback submitted by a specific user
func (s *Store) GetUserFeedback(ctx context.Context, userID string, page, pageSize int) (*ListFeedbackResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	offset := (page - 1) * pageSize

	// Count total records for this user
	var total int64
	err := s.db.QueryRow(ctx, "SELECT COUNT(*) FROM feedback WHERE user_id = $1 AND is_active = true", userID).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count user feedback: %w", err)
	}

	// Get feedback records for this user
	query := `
		SELECT id, user_id, anonymous, rating, feedback, category, is_active, created_at, updated_at
		FROM feedback
		WHERE user_id = $1 AND is_active = true
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := s.db.Query(ctx, query, userID, pageSize, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to query user feedback: %w", err)
	}
	defer rows.Close()

	var feedbacks []Feedback
	for rows.Next() {
		var feedback Feedback
		err := rows.Scan(
			&feedback.ID,
			&feedback.UserID,
			&feedback.Anonymous,
			&feedback.Rating,
			&feedback.Message,
			&feedback.Category,
			&feedback.IsActive,
			&feedback.CreatedAt,
			&feedback.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user feedback: %w", err)
		}
		feedbacks = append(feedbacks, feedback)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating user feedback rows: %w", err)
	}

	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))

	return &ListFeedbackResponse{
		Feedback:   feedbacks,
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
	}, nil
}

// DeleteFeedback soft deletes feedback by setting is_active to false
func (s *Store) DeleteFeedback(ctx context.Context, feedbackID string) error {
	query := `
		UPDATE feedback 
		SET is_active = false, updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
	`

	result, err := s.db.Exec(ctx, query, feedbackID)
	if err != nil {
		return fmt.Errorf("failed to delete feedback: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("feedback not found")
	}

	return nil
}

// GetFeedbackSummary retrieves summary statistics for dashboard
func (s *Store) GetFeedbackSummary(ctx context.Context) (*FeedbackSummary, error) {
	now := time.Now()
	today := now.Truncate(24 * time.Hour)
	weekAgo := now.AddDate(0, 0, -7)
	monthAgo := now.AddDate(0, -1, 0)

	summary := &FeedbackSummary{}

	// Get counts by time period
	countQuery := `
		SELECT 
			COUNT(*) as total_count,
			COUNT(CASE WHEN created_at >= $1 THEN 1 END) as today_count,
			COUNT(CASE WHEN created_at >= $2 THEN 1 END) as week_count,
			COUNT(CASE WHEN created_at >= $3 THEN 1 END) as month_count
		FROM feedback 
		WHERE is_active = true
	`

	err := s.db.QueryRow(ctx, countQuery, today, weekAgo, monthAgo).Scan(
		&summary.TotalCount,
		&summary.TodayCount,
		&summary.WeekCount,
		&summary.MonthCount,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get feedback summary counts: %w", err)
	}

	// Get rating metrics
	ratingQuery := `
		SELECT 
			AVG(CASE 
				WHEN rating = 'Very Dissatisfied' THEN 1
				WHEN rating = 'Dissatisfied' THEN 2
				WHEN rating = 'Neutral' THEN 3
				WHEN rating = 'Satisfied' THEN 4
				WHEN rating = 'Very Satisfied' THEN 5
				ELSE 0
			END) as avg_rating,
			COUNT(CASE WHEN rating IN ('Satisfied', 'Very Satisfied') THEN 1 END) * 100.0 / COUNT(*) as positive_ratio,
			COUNT(CASE WHEN rating IN ('Dissatisfied', 'Very Dissatisfied') THEN 1 END) * 100.0 / COUNT(*) as negative_ratio
		FROM feedback 
		WHERE is_active = true AND rating != ''
	`

	err = s.db.QueryRow(ctx, ratingQuery).Scan(
		&summary.AverageRating,
		&summary.PositiveRatio,
		&summary.NegativeRatio,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get feedback rating metrics: %w", err)
	}

	return summary, nil
}

// GetFeedbackTrends retrieves feedback trends over time
func (s *Store) GetFeedbackTrends(ctx context.Context, days int) ([]FeedbackTrend, error) {
	if days <= 0 {
		days = 30
	}

	query := `
		SELECT 
			DATE(created_at) as date,
			COUNT(*) as count
		FROM feedback 
		WHERE is_active = true 
		AND created_at >= CURRENT_DATE - INTERVAL '%d days'
		GROUP BY DATE(created_at)
		ORDER BY date
	`

	rows, err := s.db.Query(ctx, fmt.Sprintf(query, days))
	if err != nil {
		return nil, fmt.Errorf("failed to get feedback trends: %w", err)
	}
	defer rows.Close()

	var trends []FeedbackTrend
	for rows.Next() {
		var trend FeedbackTrend
		err := rows.Scan(&trend.Date, &trend.Count)
		if err != nil {
			return nil, fmt.Errorf("failed to scan feedback trend: %w", err)
		}
		trends = append(trends, trend)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating feedback trend rows: %w", err)
	}

	return trends, nil
}
