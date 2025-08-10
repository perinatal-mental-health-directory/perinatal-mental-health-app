// frontend/lib/features/resources/resources_provider.dart
import 'package:flutter/material.dart';
import 'resources_model.dart';
import '../../services/api_service.dart';

class ResourcesProvider with ChangeNotifier {
  List<ResourceModel> _resources = [];
  List<ResourceModel> _featuredResources = [];
  ResourceModel? _selectedResource;

  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalResources = 0;

  // Search and filter parameters
  String _searchQuery = '';
  String _selectedResourceType = '';
  String _selectedTargetAudience = '';
  String _selectedTag = '';
  bool? _featuredFilter;

  // Getters
  List<ResourceModel> get resources => _resources;
  List<ResourceModel> get featuredResources => _featuredResources;
  ResourceModel? get selectedResource => _selectedResource;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalResources => _totalResources;
  String get searchQuery => _searchQuery;
  String get selectedResourceType => _selectedResourceType;
  String get selectedTargetAudience => _selectedTargetAudience;
  String get selectedTag => _selectedTag;
  bool? get featuredFilter => _featuredFilter;

  bool get hasMorePages => _currentPage < _totalPages;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load featured resources for dashboard
  Future<void> loadFeaturedResources() async {
    _isFeaturedLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getFeaturedResources(limit: 2); // Changed to 2 as requested
      _featuredResources = response.map((json) => ResourceModel.fromJson(json)).toList();
      print('Loaded ${_featuredResources.length} featured resources');
    } catch (e) {
      print('Failed to load featured resources: $e');
      _error = 'Failed to load featured resources';
      _featuredResources = [];
    }

    _isFeaturedLoading = false;
    notifyListeners();
  }

  // Load resources with pagination and filters
  Future<void> loadResources({
    bool refresh = false,
    String? resourceType,
    String? targetAudience,
    String? search,
    String? tag,
    bool? featured,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _resources.clear();
    }

    _isLoading = true;
    if (refresh) {
      _error = null;
    }

    // Update filter parameters
    _searchQuery = search ?? _searchQuery;
    _selectedResourceType = resourceType ?? _selectedResourceType;
    _selectedTargetAudience = targetAudience ?? _selectedTargetAudience;
    _selectedTag = tag ?? _selectedTag;
    _featuredFilter = featured ?? _featuredFilter;

    notifyListeners();

    try {
      final response = await ApiService.getResources(
        page: _currentPage,
        pageSize: 20,
        resourceType: _selectedResourceType.isEmpty ? null : _selectedResourceType,
        targetAudience: _selectedTargetAudience.isEmpty ? null : _selectedTargetAudience,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        tags: _selectedTag.isEmpty ? null : _selectedTag,
        featured: _featuredFilter,
      );

      final resourcesList = response['resources'] as List? ?? [];
      final newResources = resourcesList.map((json) => ResourceModel.fromJson(json)).toList();

      if (refresh) {
        _resources = newResources;
      } else {
        _resources.addAll(newResources);
      }

      _totalResources = response['total'] ?? 0;
      _totalPages = response['total_pages'] ?? 1;

      print('Loaded ${newResources.length} resources (page $_currentPage/$_totalPages)');

    } catch (e) {
      print('Failed to load resources: $e');
      _error = 'Failed to load resources';
      if (refresh) {
        _resources = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more resources (pagination)
  Future<void> loadMoreResources() async {
    if (_isLoading || !hasMorePages) return;

    _currentPage++;
    await loadResources();
  }

  // Search resources
  Future<void> searchResources(String query) async {
    _searchQuery = query;
    await loadResources(refresh: true, search: query);
  }

  // Filter by resource type
  Future<void> filterByResourceType(String resourceType) async {
    _selectedResourceType = resourceType;
    await loadResources(refresh: true, resourceType: resourceType);
  }

  // Filter by target audience
  Future<void> filterByTargetAudience(String targetAudience) async {
    _selectedTargetAudience = targetAudience;
    await loadResources(refresh: true, targetAudience: targetAudience);
  }

  // Filter by tag
  Future<void> filterByTag(String tag) async {
    _selectedTag = tag;
    await loadResources(refresh: true, tag: tag);
  }

  // Filter by featured status
  Future<void> filterByFeatured(bool? featured) async {
    _featuredFilter = featured;
    await loadResources(refresh: true, featured: featured);
  }

  // Clear all filters
  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedResourceType = '';
    _selectedTargetAudience = '';
    _selectedTag = '';
    _featuredFilter = null;
    await loadResources(refresh: true);
  }

  // Load specific resource details
  Future<void> loadResourceDetails(String resourceId) async {
    try {
      final response = await ApiService.getResource(resourceId);
      _selectedResource = ResourceModel.fromJson(response);
      print('Loaded resource details for: ${_selectedResource!.title}');
    } catch (e) {
      print('Failed to load resource details: $e');
      _error = 'Failed to load resource details';
    }
    notifyListeners();
  }

  // Increment view count
  Future<void> incrementViewCount(String resourceId) async {
    try {
      await ApiService.incrementResourceViewCount(resourceId);
      // Update local count if resource is in our list
      final index = _resources.indexWhere((r) => r.id == resourceId);
      if (index != -1) {
        print('View count incremented for resource: $resourceId');
      }
    } catch (e) {
      print('Failed to increment view count: $e');
      // Non-critical error, don't show to user
    }
  }

  // Get popular resources
  Future<void> loadPopularResources() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getPopularResources(limit: 10);
      _resources = response.map((json) => ResourceModel.fromJson(json)).toList();
      _currentPage = 1;
      _totalPages = 1;
      _totalResources = _resources.length;
      print('Loaded ${_resources.length} popular resources');
    } catch (e) {
      print('Failed to load popular resources: $e');
      _error = 'Failed to load popular resources';
      _resources = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear selected resource
  void clearSelectedResource() {
    _selectedResource = null;
    notifyListeners();
  }

  // Get resources by type for dashboard
  List<ResourceModel> getResourcesByType(String type) {
    return _resources.where((resource) => resource.resourceType == type).toList();
  }

  // Get resource type counts
  Map<String, int> getResourceTypeCounts() {
    final counts = <String, int>{};
    for (final resource in _resources) {
      counts[resource.resourceType] = (counts[resource.resourceType] ?? 0) + 1;
    }
    return counts;
  }

  // Get available tags from current resources
  List<String> getAvailableTags() {
    final tagSet = <String>{};
    for (final resource in _resources) {
      tagSet.addAll(resource.tags);
    }
    final tags = tagSet.toList();
    tags.sort();
    return tags;
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadFeaturedResources(),
      loadResources(refresh: true),
    ]);
  }
}