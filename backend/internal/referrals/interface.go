package referrals

import (
	"context"
	"github.com/labstack/echo/v4"
)

// Service defines the interface for referrals business logic
type Service interface {
	CreateReferral(ctx context.Context, referredBy string, req *CreateReferralRequest) (*Referral, error)
	ListReferralsSent(ctx context.Context, referredBy string, req *ListReferralsRequest) (*ListReferralsResponse, error)
	ListReferralsReceived(ctx context.Context, referredTo string, req *ListReferralsRequest) (*ListReferralsResponse, error)
	GetReferral(ctx context.Context, referralID string, userID string) (*Referral, error)
	UpdateReferral(ctx context.Context, referralID string, userID string, req *UpdateReferralRequest) (*Referral, error)
	UpdateReferralStatus(ctx context.Context, referralID string, userID string, status string) error
	SearchUsers(ctx context.Context, req *UserSearchRequest) (*UserSearchResponse, error)
	GetReferralStats(ctx context.Context, userID string) (*ReferralStats, error)
	GetReferralsByItem(ctx context.Context, itemID string, itemType string, userID string) ([]Referral, error)
	DeleteReferral(ctx context.Context, referralID string, userID string) error
}

// Store defines the interface for referrals data persistence
type Store interface {
	CreateReferral(ctx context.Context, referral *Referral) (*Referral, error)
	GetReferralByID(ctx context.Context, referralID string) (*Referral, error)
	GetReferralWithDetails(ctx context.Context, referralID string) (*Referral, error)
	ListReferralsSent(ctx context.Context, referredBy string, req *ListReferralsRequest) (*ListReferralsResponse, error)
	ListReferralsReceived(ctx context.Context, referredTo string, req *ListReferralsRequest) (*ListReferralsResponse, error)
	UpdateReferral(ctx context.Context, referralID string, req *UpdateReferralRequest) (*Referral, error)
	UpdateReferralStatus(ctx context.Context, referralID string, status string) error
	DeleteReferral(ctx context.Context, referralID string) error
	SearchUsers(ctx context.Context, req *UserSearchRequest) (*UserSearchResponse, error)
	GetReferralStats(ctx context.Context, userID string) (*ReferralStats, error)
	GetReferralsByItem(ctx context.Context, itemID string, itemType string) ([]Referral, error)
	CheckDuplicateReferral(ctx context.Context, referredBy, referredTo, itemID, itemType string) (bool, error)

	// Validation helpers
	ValidateUserExists(ctx context.Context, userID string) error
	ValidateItemExists(ctx context.Context, itemID string, itemType string) error
	ValidateUserCanReceiveReferrals(ctx context.Context, userID string) error
	ValidateUserCanMakeReferrals(ctx context.Context, userID string) error
}

// Handler defines the interface for referrals HTTP handlers
type Handler interface {
	CreateReferral(c echo.Context) error
	ListSentReferrals(c echo.Context) error
	ListReceivedReferrals(c echo.Context) error
	GetReferral(c echo.Context) error
	UpdateReferral(c echo.Context) error
	UpdateReferralStatus(c echo.Context) error
	DeleteReferral(c echo.Context) error
	SearchUsers(c echo.Context) error
	GetReferralStats(c echo.Context) error
	GetReferralsByItem(c echo.Context) error
}
