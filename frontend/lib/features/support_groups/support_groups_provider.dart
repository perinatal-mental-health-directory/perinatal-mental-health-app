// frontend/lib/features/support_groups/support_groups_provider.dart
import 'package:flutter/material.dart';
import 'package:perinatal_app/features/support_groups/support_groups_model.dart';
import '../../services/api_service.dart';

class SupportGroupsProvider with ChangeNotifier {
  List<SupportGroupModel> _supportGroups = [];
  List<SupportGroupModel> _userGroups = [];
  SupportGroupModel? _selectedGroup;
  List<GroupMembership> _groupMembers = [];

  bool _isLoading = false;
  bool _isUserGroupsLoading = false;
  bool _isMembersLoading = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalGroups = 0;

  // Search and filter parameters
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedPlatform = '';

  // Getters
  List<SupportGroupModel> get supportGroups => _supportGroups;
  List<SupportGroupModel> get userGroups => _userGroups;
  SupportGroupModel? get selectedGroup => _selectedGroup;
  List<GroupMembership> get groupMembers => _groupMembers;
  bool get isLoading => _isLoading;
  bool get isUserGroupsLoading => _isUserGroupsLoading;
  bool get isMembersLoading => _isMembersLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalGroups => _totalGroups;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedPlatform => _selectedPlatform;

  bool get hasMorePages => _currentPage < _totalPages;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load support groups with pagination
  Future<void> loadSupportGroups({
    bool refresh = false,
    String? category,
    String? platform,
    String? search,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _supportGroups.clear();
    }

    _isLoading = true;
    if (refresh) {
      _error = null;
    }

    // Update search parameters
    _searchQuery = search ?? _searchQuery;
    _selectedCategory = category ?? _selectedCategory;
    _selectedPlatform = platform ?? _selectedPlatform;

    notifyListeners();

    try {
      final response = await ApiService.getSupportGroups(
        page: _currentPage,
        pageSize: 20,
        category: _selectedCategory.isEmpty ? null : _selectedCategory,
        platform: _selectedPlatform.isEmpty ? null : _selectedPlatform,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      final groupsList = response['support_groups'] as List? ?? [];
      final newGroups = groupsList.map((json) => SupportGroupModel.fromJson(json)).toList();

      if (refresh) {
        _supportGroups = newGroups;
      } else {
        _supportGroups.addAll(newGroups);
      }

      _totalGroups = response['total'] ?? 0;
      _totalPages = response['total_pages'] ?? 1;

      print('Loaded ${newGroups.length} support groups (page $_currentPage/$_totalPages)');

    } catch (e) {
      print('Failed to load support groups: $e');
      _error = 'Failed to load support groups';
      if (refresh) {
        _supportGroups = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more support groups (pagination)
  Future<void> loadMoreSupportGroups() async {
    if (_isLoading || !hasMorePages) return;

    _currentPage++;
    await loadSupportGroups();
  }

  // Search support groups
  Future<void> searchSupportGroups(String query) async {
    _searchQuery = query;
    await loadSupportGroups(refresh: true, search: query);
  }

  // Filter by category
  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    await loadSupportGroups(refresh: true, category: category);
  }

  // Filter by platform
  Future<void> filterByPlatform(String platform) async {
    _selectedPlatform = platform;
    await loadSupportGroups(refresh: true, platform: platform);
  }

  // Clear filters
  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedPlatform = '';
    await loadSupportGroups(refresh: true);
  }

  // Load specific support group details
  Future<void> loadSupportGroupDetails(int groupId) async {
    try {
      final response = await ApiService.getSupportGroup(groupId);
      _selectedGroup = SupportGroupModel.fromJson(response);
      print('Loaded support group details for: ${_selectedGroup!.name}');
    } catch (e) {
      print('Failed to load support group details: $e');
      _error = 'Failed to load support group details';
    }
    notifyListeners();
  }

  // Clear selected group
  void clearSelectedGroup() {
    _selectedGroup = null;
    _groupMembers = [];
    notifyListeners();
  }

  // Load user's groups
  Future<void> loadUserGroups() async {
    _isUserGroupsLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getUserGroups();
      final groupsList = response['groups'] as List? ?? [];
      _userGroups = groupsList.map((json) => SupportGroupModel.fromJson(json)).toList();
      print('Loaded ${_userGroups.length} user groups');
    } catch (e) {
      print('Failed to load user groups: $e');
      _error = 'Failed to load your groups';
      _userGroups = [];
    }

    _isUserGroupsLoading = false;
    notifyListeners();
  }

  // Join a support group
  Future<bool> joinGroup(int groupId) async {
    try {
      await ApiService.joinSupportGroup(groupId);
      print('Successfully joined group $groupId');

      // Refresh user groups and selected group details
      await Future.wait([
        loadUserGroups(),
        if (_selectedGroup != null) loadGroupMembers(groupId),
      ]);

      return true;
    } catch (e) {
      print('Failed to join group: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Leave a support group
  Future<bool> leaveGroup(int groupId) async {
    try {
      await ApiService.leaveSupportGroup(groupId);
      print('Successfully left group $groupId');

      // Refresh user groups and selected group details
      await Future.wait([
        loadUserGroups(),
        if (_selectedGroup != null) loadGroupMembers(groupId),
      ]);

      return true;
    } catch (e) {
      print('Failed to leave group: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Load group members
  Future<void> loadGroupMembers(int groupId) async {
    _isMembersLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.getSupportGroupMembers(groupId);
      final membersList = response['members'] as List? ?? [];
      _groupMembers = membersList.map((json) => GroupMembership.fromJson(json)).toList();
      print('Loaded ${_groupMembers.length} group members');
    } catch (e) {
      print('Failed to load group members: $e');
      _error = 'Failed to load group members';
      _groupMembers = [];
    }

    _isMembersLoading = false;
    notifyListeners();
  }

  // Check if user is member of a group
  bool isUserMemberOfGroup(int groupId) {
    return _userGroups.any((group) => group.id == groupId);
  }

  // Get groups by category
  List<SupportGroupModel> getGroupsByCategory(String category) {
    return _supportGroups.where((group) => group.category == category).toList();
  }

  // Get groups by platform
  List<SupportGroupModel> getGroupsByPlatform(String platform) {
    return _supportGroups.where((group) => group.platform == platform).toList();
  }

  // Get category counts
  Map<String, int> getCategoryCounts() {
    final counts = <String, int>{};
    for (final group in _supportGroups) {
      counts[group.category] = (counts[group.category] ?? 0) + 1;
    }
    return counts;
  }

  // Get platform counts
  Map<String, int> getPlatformCounts() {
    final counts = <String, int>{};
    for (final group in _supportGroups) {
      counts[group.platform] = (counts[group.platform] ?? 0) + 1;
    }
    return counts;
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadSupportGroups(refresh: true),
      loadUserGroups(),
    ]);
  }

  // Get member count for a group
  int getMemberCount(int groupId) {
    if (_selectedGroup?.id == groupId) {
      return _groupMembers.where((member) => member.isActive).length;
    }
    return 0; // Unknown if not loaded
  }

  // Get user's role in a group
  String? getUserRoleInGroup(int groupId, String userId) {
    if (_selectedGroup?.id == groupId) {
      final membership = _groupMembers.firstWhere(
            (member) => member.userId == userId && member.isActive,
        orElse: () => GroupMembership(
          id: 0,
          userId: '',
          groupId: 0,
          joinedAt: DateTime.now(),
          isActive: false,
          role: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return membership.isActive ? membership.role : null;
    }
    return null;
  }
}