package referrals

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

type service struct {
	store Store
}

func NewService(store Store) Service {
	return &service{
		store: store,
	}
}

// CreateReferral creates a new referral
func (s *service) CreateReferral(ctx context.Context, referredBy string, req *CreateReferralRequest) (*Referral, error) {
	// Validate referrer can make referrals
	if err := s.store.ValidateUserCanMakeReferrals(ctx, referredBy); err != nil {
		return nil, fmt.Errorf("referrer validation failed: %w", err)
	}

	// Validate recipient exists and can receive referrals
	if err := s.store.ValidateUserExists(ctx, req.ReferredTo); err != nil {
		return nil, fmt.Errorf("recipient validation failed: %w", err)
	}

	if err := s.store.ValidateUserCanReceiveReferrals(ctx, req.ReferredTo); err != nil {
		return nil, fmt.Errorf("recipient cannot receive referrals: %w", err)
	}

	// Validate item exists
	if err := s.store.ValidateItemExists(ctx, req.ItemID, req.ReferralType); err != nil {
		return nil, fmt.Errorf("item validation failed: %w", err)
	}

	// Check for duplicate referrals
	isDuplicate, err := s.store.CheckDuplicateReferral(ctx, referredBy, req.ReferredTo, req.ItemID, req.ReferralType)
	if err != nil {
		return nil, fmt.Errorf("failed to check duplicate referral: %w", err)
	}

	if isDuplicate {
		return nil, fmt.Errorf("a similar referral already exists for this item and recipient")
	}

	// Validate referral type
	if !isValidReferralType(req.ReferralType) {
		return nil, fmt.Errorf("invalid referral type: %s", req.ReferralType)
	}

	// Additional validation
	if err := validateReferralRequest(req); err != nil {
		return nil, err
	}

	// Create referral
	now := time.Now()
	referral := &Referral{
		ID:           uuid.New().String(),
		ReferredBy:   referredBy,
		ReferredTo:   req.ReferredTo,
		ReferralType: req.ReferralType,
		ItemID:       req.ItemID,
		Reason:       strings.TrimSpace(req.Reason),
		Status:       string(StatusPending),
		IsUrgent:     req.IsUrgent,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	// Handle metadata
	if req.Metadata != nil {
		metadataJSON, err := json.Marshal(req.Metadata)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal metadata: %w", err)
		}
		metadataStr := string(metadataJSON)
		referral.Metadata = &metadataStr
	}

	return s.store.CreateReferral(ctx, referral)
}

// ListReferralsSent retrieves sent referrals for a user
func (s *service) ListReferralsSent(ctx context.Context, referredBy string, req *ListReferralsRequest) (*ListReferralsResponse, error) {
	if req.Page < 1 {
		req.Page = 1
	}
	if req.PageSize < 1 || req.PageSize > 100 {
		req.PageSize = 20
	}

	// Validate status if provided
	if req.Status != "" && !isValidReferralStatus(req.Status) {
		return nil, fmt.Errorf("invalid status: %s", req.Status)
	}

	// Validate referral type if provided
	if req.ReferralType != "" && !isValidReferralType(req.ReferralType) {
		return nil, fmt.Errorf("invalid referral type: %s", req.ReferralType)
	}

	return s.store.ListReferralsSent(ctx, referredBy, req)
}

// ListReferralsReceived retrieves received referrals for a user
func (s *service) ListReferralsReceived(ctx context.Context, referredTo string, req *ListReferralsRequest) (*ListReferralsResponse, error) {
	if req.Page < 1 {
		req.Page = 1
	}
	if req.PageSize < 1 || req.PageSize > 100 {
		req.PageSize = 20
	}

	// Validate status if provided
	if req.Status != "" && !isValidReferralStatus(req.Status) {
		return nil, fmt.Errorf("invalid status: %s", req.Status)
	}

	// Validate referral type if provided
	if req.ReferralType != "" && !isValidReferralType(req.ReferralType) {
		return nil, fmt.Errorf("invalid referral type: %s", req.ReferralType)
	}

	return s.store.ListReferralsReceived(ctx, referredTo, req)
}

// GetReferral retrieves a referral by ID with access control
func (s *service) GetReferral(ctx context.Context, referralID string, userID string) (*Referral, error) {
	if referralID == "" {
		return nil, fmt.Errorf("invalid referral ID")
	}

	referral, err := s.store.GetReferralWithDetails(ctx, referralID)
	if err != nil {
		return nil, err
	}

	// Check if user has access to this referral
	if !referral.CanViewDetails(userID) {
		return nil, fmt.Errorf("access denied: you don't have permission to view this referral")
	}

	return referral, nil
}

// UpdateReferral updates a referral with access control
func (s *service) UpdateReferral(ctx context.Context, referralID string, userID string, req *UpdateReferralRequest) (*Referral, error) {
	if referralID == "" {
		return nil, fmt.Errorf("invalid referral ID")
	}

	// Get existing referral to check permissions
	existingReferral, err := s.store.GetReferralByID(ctx, referralID)
	if err != nil {
		return nil, err
	}

	// Check if user can update this referral
	if !existingReferral.CanBeUpdatedBy(userID) {
		return nil, fmt.Errorf("access denied: you don't have permission to update this referral")
	}

	// Additional validation based on user role
	if userID == existingReferral.ReferredTo {
		// Recipients can only update status
		if req.Reason != nil || req.IsUrgent != nil || req.Metadata != nil {
			return nil, fmt.Errorf("recipients can only update referral status")
		}
	}

	// Validate status if provided
	if req.Status != nil && !isValidReferralStatus(*req.Status) {
		return nil, fmt.Errorf("invalid status: %s", *req.Status)
	}

	return s.store.UpdateReferral(ctx, referralID, req)
}

// UpdateReferralStatus updates only the status of a referral
func (s *service) UpdateReferralStatus(ctx context.Context, referralID string, userID string, status string) error {
	if referralID == "" {
		return fmt.Errorf("invalid referral ID")
	}

	if !isValidReferralStatus(status) {
		return fmt.Errorf("invalid status: %s", status)
	}

	// Get existing referral to check permissions
	existingReferral, err := s.store.GetReferralByID(ctx, referralID)
	if err != nil {
		return err
	}

	// Only the recipient can update status (accept/decline)
	if userID != existingReferral.ReferredTo {
		return fmt.Errorf("access denied: only the recipient can update referral status")
	}

	// Validate status transitions
	if err := validateStatusTransition(existingReferral.Status, status); err != nil {
		return err
	}

	return s.store.UpdateReferralStatus(ctx, referralID, status)
}

// SearchUsers searches for users that can receive referrals
func (s *service) SearchUsers(ctx context.Context, req *UserSearchRequest) (*UserSearchResponse, error) {
	if req.Limit < 1 || req.Limit > 50 {
		req.Limit = 20
	}

	// Clean and validate search query
	req.Query = strings.TrimSpace(req.Query)
	if len(req.Query) < 3 {
		return nil, fmt.Errorf("search query must be at least 3 characters long")
	}

	// If no role specified, default to service_user (parents)
	if req.Role == "" {
		req.Role = "service_user"
	}

	return s.store.SearchUsers(ctx, req)
}

// GetReferralStats retrieves referral statistics for a user
func (s *service) GetReferralStats(ctx context.Context, userID string) (*ReferralStats, error) {
	if userID == "" {
		return nil, fmt.Errorf("invalid user ID")
	}

	return s.store.GetReferralStats(ctx, userID)
}

// GetReferralsByItem gets referrals for a specific item (with access control)
func (s *service) GetReferralsByItem(ctx context.Context, itemID string, itemType string, userID string) ([]Referral, error) {
	if itemID == "" {
		return nil, fmt.Errorf("invalid item ID")
	}

	if !isValidReferralType(itemType) {
		return nil, fmt.Errorf("invalid referral type: %s", itemType)
	}

	// Validate item exists
	if err := s.store.ValidateItemExists(ctx, itemID, itemType); err != nil {
		return nil, fmt.Errorf("item validation failed: %w", err)
	}

	referrals, err := s.store.GetReferralsByItem(ctx, itemID, itemType)
	if err != nil {
		return nil, err
	}

	// Filter referrals based on user access
	var accessibleReferrals []Referral
	for _, referral := range referrals {
		if referral.CanViewDetails(userID) {
			accessibleReferrals = append(accessibleReferrals, referral)
		}
	}

	return accessibleReferrals, nil
}

// DeleteReferral deletes a referral with access control
func (s *service) DeleteReferral(ctx context.Context, referralID string, userID string) error {
	if referralID == "" {
		return fmt.Errorf("invalid referral ID")
	}

	// Get existing referral to check permissions
	existingReferral, err := s.store.GetReferralByID(ctx, referralID)
	if err != nil {
		return err
	}

	// Only the referrer can delete a referral, and only if it's still pending
	if userID != existingReferral.ReferredBy {
		return fmt.Errorf("access denied: only the referrer can delete a referral")
	}

	if existingReferral.Status != string(StatusPending) {
		return fmt.Errorf("cannot delete referral: status is %s", existingReferral.Status)
	}

	return s.store.DeleteReferral(ctx, referralID)
}

// Helper functions

// isValidReferralType validates referral type
func isValidReferralType(referralType string) bool {
	validTypes := []string{"service", "resource", "support_group"}
	for _, validType := range validTypes {
		if referralType == validType {
			return true
		}
	}
	return false
}

// isValidReferralStatus validates referral status
func isValidReferralStatus(status string) bool {
	validStatuses := []string{"pending", "accepted", "declined", "viewed"}
	for _, validStatus := range validStatuses {
		if status == validStatus {
			return true
		}
	}
	return false
}

// validateReferralRequest performs additional validation on referral requests
func validateReferralRequest(req *CreateReferralRequest) error {
	// Validate required fields
	if strings.TrimSpace(req.ReferredTo) == "" {
		return fmt.Errorf("referred_to is required")
	}

	if strings.TrimSpace(req.ItemID) == "" {
		return fmt.Errorf("item_id is required")
	}

	if strings.TrimSpace(req.Reason) == "" {
		return fmt.Errorf("reason is required")
	}

	// Validate reason length
	reason := strings.TrimSpace(req.Reason)
	if len(reason) < 10 {
		return fmt.Errorf("reason must be at least 10 characters long")
	}

	if len(reason) > 1000 {
		return fmt.Errorf("reason cannot exceed 1000 characters")
	}

	// Validate UUID format for referred_to
	if !isValidUUID(req.ReferredTo) {
		return fmt.Errorf("invalid referred_to UUID format")
	}

	// Validate item ID format based on type
	if req.ReferralType == "support_group" {
		// Support groups use integer IDs
		if !isValidInteger(req.ItemID) {
			return fmt.Errorf("invalid support group ID format")
		}
	} else {
		// Services and resources use UUID
		if !isValidUUID(req.ItemID) {
			return fmt.Errorf("invalid item ID UUID format")
		}
	}

	return nil
}

// validateStatusTransition validates if a status transition is allowed
func validateStatusTransition(currentStatus, newStatus string) error {
	// Define allowed transitions
	allowedTransitions := map[string][]string{
		"pending":  {"accepted", "declined", "viewed"},
		"accepted": {"declined"},             // Can change mind
		"declined": {"accepted"},             // Can change mind
		"viewed":   {"accepted", "declined"}, // Can take action after viewing
	}

	if currentStatus == newStatus {
		return nil // No change
	}

	allowed, exists := allowedTransitions[currentStatus]
	if !exists {
		return fmt.Errorf("invalid current status: %s", currentStatus)
	}

	for _, allowedStatus := range allowed {
		if newStatus == allowedStatus {
			return nil
		}
	}

	return fmt.Errorf("cannot transition from %s to %s", currentStatus, newStatus)
}

// isValidUUID checks if a string is a valid UUID
func isValidUUID(u string) bool {
	_, err := uuid.Parse(u)
	return err == nil
}

// isValidInteger checks if a string is a valid integer
func isValidInteger(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}
