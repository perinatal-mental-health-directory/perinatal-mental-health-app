// backend/internal/support_groups/service.go
package support_groups

import (
	"context"
	"fmt"
	"github.com/google/uuid"
	"strings"
)

type service struct {
	store Store
}

func NewService(store Store) Service {
	return &service{
		store: store,
	}
}

// ListSupportGroups retrieves a paginated list of support groups
func (s *service) ListSupportGroups(ctx context.Context, page, pageSize int, category, platform string) (*ListSupportGroupsResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	// Validate category if provided
	if category != "" && !isValidCategory(category) {
		return nil, fmt.Errorf("invalid category: %s", category)
	}

	// Validate platform if provided
	if platform != "" && !isValidPlatform(platform) {
		return nil, fmt.Errorf("invalid platform: %s", platform)
	}

	return s.store.ListSupportGroups(ctx, page, pageSize, category, platform)
}

// GetSupportGroup retrieves a support group by ID
func (s *service) GetSupportGroup(ctx context.Context, groupID string) (*SupportGroup, error) {
	if !isValidUUID(groupID) { // Add UUID validation
		return nil, fmt.Errorf("invalid group ID")
	}

	return s.store.GetSupportGroupByID(ctx, groupID)
}

// SearchSupportGroups searches for support groups by query
func (s *service) SearchSupportGroups(ctx context.Context, query string, page, pageSize int) (*ListSupportGroupsResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	// Clean and validate search query
	query = strings.TrimSpace(query)
	if query == "" {
		return nil, fmt.Errorf("search query cannot be empty")
	}

	if len(query) < 2 {
		return nil, fmt.Errorf("search query must be at least 2 characters long")
	}

	return s.store.SearchSupportGroups(ctx, query, page, pageSize)
}

// GetSupportGroupsByCategory retrieves support groups by category
func (s *service) GetSupportGroupsByCategory(ctx context.Context, category string, page, pageSize int) (*ListSupportGroupsResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	if !isValidCategory(category) {
		return nil, fmt.Errorf("invalid category: %s", category)
	}

	return s.store.GetSupportGroupsByCategory(ctx, category, page, pageSize)
}

// GetSupportGroupsByPlatform retrieves support groups by platform
func (s *service) GetSupportGroupsByPlatform(ctx context.Context, platform string, page, pageSize int) (*ListSupportGroupsResponse, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	if !isValidPlatform(platform) {
		return nil, fmt.Errorf("invalid platform: %s", platform)
	}

	return s.store.GetSupportGroupsByPlatform(ctx, platform, page, pageSize)
}

// GetUserGroups retrieves all groups a user is a member of
func (s *service) GetUserGroups(ctx context.Context, userID string) ([]SupportGroup, error) {
	if userID == "" {
		return nil, fmt.Errorf("invalid user ID")
	}

	return s.store.GetUserGroups(ctx, userID)
}

// JoinGroup adds a user to a support group
func (s *service) JoinGroup(ctx context.Context, userID string, groupID string) error {
	if userID == "" {
		return fmt.Errorf("invalid user ID")
	}
	if !isValidUUID(groupID) {
		return fmt.Errorf("invalid group ID")
	}

	// Check if group exists
	group, err := s.store.GetSupportGroupByID(ctx, groupID)
	if err != nil {
		return fmt.Errorf("group not found")
	}

	if !group.IsActive {
		return fmt.Errorf("group is not active")
	}

	// Check if user is already a member
	isMember, err := s.store.IsUserMember(ctx, userID, groupID)
	if err != nil {
		return fmt.Errorf("failed to check membership status")
	}

	if isMember {
		return fmt.Errorf("user is already a member of this group")
	}

	// Check if group has reached max capacity
	if group.HasMaxMembers() {
		members, err := s.store.GetGroupMembers(ctx, groupID)
		if err != nil {
			return fmt.Errorf("failed to check group capacity")
		}

		activeMembers := 0
		for _, member := range members {
			if member.IsActive {
				activeMembers++
			}
		}

		if activeMembers >= *group.MaxMembers {
			return fmt.Errorf("group has reached maximum capacity")
		}
	}

	return s.store.JoinGroup(ctx, userID, groupID)
}

// LeaveGroup removes a user from a support group
func (s *service) LeaveGroup(ctx context.Context, userID string, groupID string) error {
	if userID == "" {
		return fmt.Errorf("invalid user ID")
	}
	if !isValidUUID(groupID) {
		return fmt.Errorf("invalid group ID")
	}

	// Check if user is a member
	isMember, err := s.store.IsUserMember(ctx, userID, groupID)
	if err != nil {
		return fmt.Errorf("failed to check membership status")
	}

	if !isMember {
		return fmt.Errorf("user is not a member of this group")
	}

	return s.store.LeaveGroup(ctx, userID, groupID)
}

// GetGroupMembers retrieves all members of a support group
func (s *service) GetGroupMembers(ctx context.Context, groupID string) ([]GroupMembership, error) {
	if !isValidUUID(groupID) {
		return nil, fmt.Errorf("invalid group ID")
	}

	// Check if group exists
	_, err := s.store.GetSupportGroupByID(ctx, groupID)
	if err != nil {
		return nil, fmt.Errorf("group not found")
	}

	return s.store.GetGroupMembers(ctx, groupID)
}

// IsUserMember checks if a user is a member of a support group
func (s *service) IsUserMember(ctx context.Context, userID string, groupID string) (bool, error) {
	if userID == "" {
		return false, fmt.Errorf("invalid user ID")
	}
	if !isValidUUID(groupID) {
		return false, fmt.Errorf("invalid group ID")
	}

	return s.store.IsUserMember(ctx, userID, groupID)
}

// GetSupportGroupStats retrieves support group statistics
func (s *service) GetSupportGroupStats(ctx context.Context) (*SupportGroupStats, error) {
	return s.store.GetSupportGroupStats(ctx)
}

// CreateSupportGroup creates a new support group (admin only)
func (s *service) CreateSupportGroup(ctx context.Context, req *CreateSupportGroupRequest) (*SupportGroup, error) {
	// Validate category
	if !isValidCategory(req.Category) {
		return nil, fmt.Errorf("invalid category: %s", req.Category)
	}

	// Validate platform
	if !isValidPlatform(req.Platform) {
		return nil, fmt.Errorf("invalid platform: %s", req.Platform)
	}

	// Additional validation
	if err := validateSupportGroupRequest(req); err != nil {
		return nil, err
	}

	return s.store.CreateSupportGroup(ctx, req)
}

// UpdateSupportGroup updates a support group (admin only)
func (s *service) UpdateSupportGroup(ctx context.Context, groupID string, req *UpdateSupportGroupRequest) (*SupportGroup, error) {
	if !isValidUUID(groupID) {
		return nil, fmt.Errorf("invalid group ID")
	}

	// Validate category if provided
	if req.Category != nil && !isValidCategory(*req.Category) {
		return nil, fmt.Errorf("invalid category: %s", *req.Category)
	}

	// Validate platform if provided
	if req.Platform != nil && !isValidPlatform(*req.Platform) {
		return nil, fmt.Errorf("invalid platform: %s", *req.Platform)
	}

	return s.store.UpdateSupportGroup(ctx, groupID, req)
}

// DeleteSupportGroup soft deletes a support group (admin only)
func (s *service) DeleteSupportGroup(ctx context.Context, groupID string) error {
	if !isValidUUID(groupID) {
		return fmt.Errorf("invalid group ID")
	}

	return s.store.DeleteSupportGroup(ctx, groupID)
}

// RemoveUserFromGroup removes a user from a group (admin only)
func (s *service) RemoveUserFromGroup(ctx context.Context, userID string, groupID string) error {
	if userID == "" {
		return fmt.Errorf("invalid user ID")
	}
	if !isValidUUID(groupID) {
		return fmt.Errorf("invalid group ID")
	}

	// Check if user is a member
	isMember, err := s.store.IsUserMember(ctx, userID, groupID)
	if err != nil {
		return fmt.Errorf("failed to check membership status")
	}

	if !isMember {
		return fmt.Errorf("user is not a member of this group")
	}

	return s.store.RemoveUserFromGroup(ctx, userID, groupID)
}

// Helper functions

// isValidCategory validates category
func isValidCategory(category string) bool {
	validCategories := []string{"postnatal", "prenatal", "anxiety", "depression", "partner_support", "general"}
	for _, validCategory := range validCategories {
		if category == validCategory {
			return true
		}
	}
	return false
}

// isValidPlatform validates platform
func isValidPlatform(platform string) bool {
	validPlatforms := []string{"online", "in_person", "hybrid"}
	for _, validPlatform := range validPlatforms {
		if platform == validPlatform {
			return true
		}
	}
	return false
}

// validateSupportGroupRequest performs additional validation on support group requests
func validateSupportGroupRequest(req *CreateSupportGroupRequest) error {
	// Validate required fields
	if strings.TrimSpace(req.Name) == "" {
		return fmt.Errorf("group name is required")
	}

	if strings.TrimSpace(req.Description) == "" {
		return fmt.Errorf("group description is required")
	}

	// Validate name length
	if len(req.Name) > 255 {
		return fmt.Errorf("group name cannot exceed 255 characters")
	}

	// Validate URL if provided
	if req.URL != nil && strings.TrimSpace(*req.URL) != "" {
		// Basic URL validation (the struct tag validation should handle this too)
		if !strings.HasPrefix(*req.URL, "http://") && !strings.HasPrefix(*req.URL, "https://") {
			return fmt.Errorf("URL must be a valid HTTP or HTTPS URL")
		}
	}

	// For online platform, URL should be provided
	if req.Platform == "online" && (req.URL == nil || strings.TrimSpace(*req.URL) == "") {
		return fmt.Errorf("URL is required for online support groups")
	}

	// Validate max members
	if req.MaxMembers != nil && *req.MaxMembers <= 1 {
		return fmt.Errorf("max members must be greater than 1")
	}

	return nil
}

func isValidUUID(u string) bool {
	_, err := uuid.Parse(u)
	return err == nil
}
