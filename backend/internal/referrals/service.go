package referrals

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

// CreateReferral creates a new referral
func (s *Service) CreateReferral(ctx context.Context, req *CreateReferralRequest, userID string) (*Referral, error) {
	return s.store.CreateReferral(ctx, req, userID)
}

// ListReferrals retrieves a paginated list of referrals
func (s *Service) ListReferrals(ctx context.Context, page, pageSize int, userID, status string, urgent bool) (*ListReferralsResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	return s.store.ListReferrals(ctx, page, pageSize, userID, status, urgent)
}

// GetReferral retrieves a referral by ID
func (s *Service) GetReferral(ctx context.Context, referralID int, userID string) (*Referral, error) {
	return s.store.GetReferralByID(ctx, referralID, userID)
}

// UpdateReferral updates a referral
func (s *Service) UpdateReferral(ctx context.Context, referralID int, req *UpdateReferralRequest) (*Referral, error) {
	// Validate status if provided
	if req.Status != nil && !isValidStatus(*req.Status) {
		return nil, fmt.Errorf("invalid status: %s", *req.Status)
	}

	return s.store.UpdateReferral(ctx, referralID, req)
}

// GetReferralStats retrieves referral statistics
func (s *Service) GetReferralStats(ctx context.Context) (*ReferralStats, error) {
	return s.store.GetReferralStats(ctx)
}

// Helper function to validate referral statuses
func isValidStatus(status string) bool {
	switch ReferralStatus(status) {
	case StatusPending, StatusAccepted, StatusRejected, StatusCompleted, StatusCancelled:
		return true
	default:
		return false
	}
}
