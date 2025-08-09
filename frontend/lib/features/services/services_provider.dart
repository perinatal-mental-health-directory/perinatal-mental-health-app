// lib/providers/services_provider.dart
import 'package:flutter/material.dart';
import 'package:perinatal_app/features/services/services_model.dart';
import '../../services/api_service.dart';

class ServicesProvider with ChangeNotifier {
  List<ServiceModel> _services = [];
  List<ServiceModel> _featuredServices = [];
  ServiceModel? _selectedService;

  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalServices = 0;

  // Search and filter parameters
  String _searchQuery = '';
  String _selectedServiceType = '';

  // Getters
  List<ServiceModel> get services => _services;
  List<ServiceModel> get featuredServices => _featuredServices;
  ServiceModel? get selectedService => _selectedService;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalServices => _totalServices;
  String get searchQuery => _searchQuery;
  String get selectedServiceType => _selectedServiceType;

  bool get hasMorePages => _currentPage < _totalPages;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load featured services for dashboard
  Future<void> loadFeaturedServices() async {
    _isFeaturedLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getFeaturedServices(limit: 3);
      _featuredServices = response.map((json) => ServiceModel.fromJson(json)).toList();
      print('Loaded ${_featuredServices.length} featured services');
    } catch (e) {
      print('Failed to load featured services: $e');
      _error = 'Failed to load featured services';
      _featuredServices = [];
    }

    _isFeaturedLoading = false;
    notifyListeners();
  }

  // Load services with pagination
  Future<void> loadServices({
    bool refresh = false,
    String? serviceType,
    String? search,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _services.clear();
    }

    _isLoading = true;
    if (refresh) {
      _error = null;
    }

    // Update search parameters
    _searchQuery = search ?? _searchQuery;
    _selectedServiceType = serviceType ?? _selectedServiceType;

    notifyListeners();

    try {
      final response = await ApiService.getServices(
        page: _currentPage,
        pageSize: 20,
        serviceType: _selectedServiceType.isEmpty ? null : _selectedServiceType,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      final servicesList = response['services'] as List? ?? [];
      final newServices = servicesList.map((json) => ServiceModel.fromJson(json)).toList();

      if (refresh) {
        _services = newServices;
      } else {
        _services.addAll(newServices);
      }

      _totalServices = response['total'] ?? 0;
      _totalPages = response['total_pages'] ?? 1;

      print('Loaded ${newServices.length} services (page $_currentPage/$_totalPages)');

    } catch (e) {
      print('Failed to load services: $e');
      _error = 'Failed to load services';
      if (refresh) {
        _services = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more services (pagination)
  Future<void> loadMoreServices() async {
    if (_isLoading || !hasMorePages) return;

    _currentPage++;
    await loadServices();
  }

  // Search services
  Future<void> searchServices(String query) async {
    _searchQuery = query;
    await loadServices(refresh: true, search: query);
  }

  // Filter by service type
  Future<void> filterByServiceType(String serviceType) async {
    _selectedServiceType = serviceType;
    await loadServices(refresh: true, serviceType: serviceType);
  }

  // Clear filters
  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedServiceType = '';
    await loadServices(refresh: true);
  }

  // Load specific service details
  Future<void> loadServiceDetails(String serviceId) async {
    try {
      final response = await ApiService.getService(serviceId);
      _selectedService = ServiceModel.fromJson(response);
      print('Loaded service details for: ${_selectedService!.name}');
    } catch (e) {
      print('Failed to load service details: $e');
      _error = 'Failed to load service details';
    }
    notifyListeners();
  }

  // Clear selected service
  void clearSelectedService() {
    _selectedService = null;
    notifyListeners();
  }

  // Get services by type for dashboard
  List<ServiceModel> getServicesByType(String type) {
    return _services.where((service) => service.serviceType == type).toList();
  }

  // Get service counts by type
  Map<String, int> getServiceCounts() {
    final counts = <String, int>{};
    for (final service in _services) {
      counts[service.serviceType] = (counts[service.serviceType] ?? 0) + 1;
    }
    return counts;
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadFeaturedServices(),
      loadServices(refresh: true),
    ]);
  }

  // Get service type counts for dashboard
  Map<String, int> getFeaturedServiceCounts() {
    final counts = <String, int>{};
    for (final service in _featuredServices) {
      counts[service.serviceType] = (counts[service.serviceType] ?? 0) + 1;
    }
    return counts;
  }
}