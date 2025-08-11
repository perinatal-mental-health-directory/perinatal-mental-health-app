package journey

import (
	"context"
	"time"

	"github.com/labstack/echo/v4"
)

// Service defines the interface for journey business logic
type Service interface {
	// Journey Entries
	CreateJourneyEntry(ctx context.Context, userID string, req *CreateJourneyEntryRequest) (*JourneyEntry, error)
	GetJourneyEntry(ctx context.Context, userID, entryID string) (*JourneyEntry, error)
	GetTodaysEntry(ctx context.Context, userID string) (*JourneyEntry, error)
	UpdateJourneyEntry(ctx context.Context, userID, entryID string, req *UpdateJourneyEntryRequest) (*JourneyEntry, error)
	DeleteJourneyEntry(ctx context.Context, userID, entryID string) error
	ListJourneyEntries(ctx context.Context, userID string, page, pageSize int, startDate, endDate *string) (*ListJourneyEntriesResponse, error)

	// Journey Goals
	CreateJourneyGoal(ctx context.Context, userID string, req *CreateJourneyGoalRequest) (*JourneyGoal, error)
	UpdateJourneyGoal(ctx context.Context, userID, goalID string, req *UpdateJourneyGoalRequest) (*JourneyGoal, error)
	DeleteJourneyGoal(ctx context.Context, userID, goalID string) error
	ListJourneyGoals(ctx context.Context, userID string, status *string) ([]JourneyGoal, error)

	// Journey Analytics
	GetJourneyStats(ctx context.Context, userID string) (*JourneyStats, error)
	GetJourneyInsights(ctx context.Context, userID string) (*JourneyInsights, error)
	ListJourneyMilestones(ctx context.Context, userID string, limit int) ([]JourneyMilestone, error)
}

// Store defines the interface for journey data persistence
type Store interface {
	// Journey Entries
	CreateJourneyEntry(ctx context.Context, userID string, entryDate time.Time, req *CreateJourneyEntryRequest) (*JourneyEntry, error)
	GetJourneyEntryByID(ctx context.Context, userID, entryID string) (*JourneyEntry, error)
	GetJourneyEntryByDate(ctx context.Context, userID, date string) (*JourneyEntry, error)
	UpdateJourneyEntry(ctx context.Context, userID, entryID string, req *UpdateJourneyEntryRequest) (*JourneyEntry, error)
	DeleteJourneyEntry(ctx context.Context, userID, entryID string) error
	ListJourneyEntries(ctx context.Context, userID string, page, pageSize int, startDate, endDate *string) (*ListJourneyEntriesResponse, error)

	// Journey Goals
	CreateJourneyGoal(ctx context.Context, userID string, req *CreateJourneyGoalRequest, targetDate *time.Time) (*JourneyGoal, error)
	UpdateJourneyGoal(ctx context.Context, userID, goalID string, req *UpdateJourneyGoalRequest, targetDate *time.Time) (*JourneyGoal, error)
	DeleteJourneyGoal(ctx context.Context, userID, goalID string) error
	ListJourneyGoals(ctx context.Context, userID string, status *string) ([]JourneyGoal, error)

	// Journey Milestones
	CreateJourneyMilestone(ctx context.Context, milestone *JourneyMilestone) error
	ListJourneyMilestones(ctx context.Context, userID string, limit int) ([]JourneyMilestone, error)
	CheckMilestoneExists(ctx context.Context, userID, milestoneType string) (bool, error)

	// Journey Analytics
	GetJourneyStats(ctx context.Context, userID string) (*JourneyStats, error)
}

// Handler defines the interface for journey HTTP handlers
type Handler interface {
	// Journey Entries
	CreateJourneyEntry(c echo.Context) error
	GetJourneyEntry(c echo.Context) error
	GetTodaysEntry(c echo.Context) error
	UpdateJourneyEntry(c echo.Context) error
	DeleteJourneyEntry(c echo.Context) error
	ListJourneyEntries(c echo.Context) error

	// Journey Goals
	CreateJourneyGoal(c echo.Context) error
	UpdateJourneyGoal(c echo.Context) error
	DeleteJourneyGoal(c echo.Context) error
	ListJourneyGoals(c echo.Context) error

	// Journey Analytics
	GetJourneyStats(c echo.Context) error
	GetJourneyInsights(c echo.Context) error
	ListJourneyMilestones(c echo.Context) error
}
