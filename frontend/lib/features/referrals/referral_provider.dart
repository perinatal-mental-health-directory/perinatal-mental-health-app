// frontend/lib/features/referrals/referral_provider.dart
import 'package:flutter/material.dart';
import 'referral_model.dart';
import '../../services/api_service.dart';

class ReferralProvider with ChangeNotifier {
  List<ReferralModel> _sentReferrals = [];
  List<ReferralModel> _receivedReferrals = [];
  List<UserSearchResult> _searchResults = [];
  ReferralModel? _selectedReferral;

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isCreating = false;
  String? _error;

  int _sentCurrentPage = 1;
  int _receivedCurrentPage = 1;
  int _sentTotalPages = 1;
  int _receivedTotalPages = 1;

  // Getters
  List<ReferralModel> get sentReferrals => _sentReferrals;
  List<ReferralModel> get receivedReferrals => _receivedReferrals;
  List<UserSearchResult> get searchResults => _searchResults;
  ReferralModel? get selectedReferral => _selectedReferral;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isCreating => _isCreating;
  String? get error => _error;
  int get sentCurrentPage => _sentCurrentPage;
  int get receivedCurrentPage => _receivedCurrentPage;
  int get sentTotalPages => _sentTotalPages;
  int get receivedTotalPages => _receivedTotalPages;

  bool get hasSentMorePages => _sentCurrentPage < _sentTotalPages;
  bool get hasReceivedMorePages => _receivedCurrentPage < _receivedTotalPages;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load sent referrals (for professionals/NHS staff)
  Future<void> loadSentReferrals({
    bool refresh = false,
    String? status,
    String? referralType,
  }) async {
    if (refresh) {
      _sentCurrentPage = 1;
      _sentReferrals.clear();
    }

    _isLoading = true;
    if (refresh) {
      _error = null;
    }
    notifyListeners();

    try {
      final response = await ApiService.getSentReferrals(
        page: _sentCurrentPage,
        pageSize: 20,
        status: status,
        referralType: referralType,
      );

      final referralsList = response['referrals'] as List? ?? [];
      final newReferrals = referralsList.map((json) => ReferralModel.fromJson(json)).toList();

      if (refresh) {
        _sentReferrals = newReferrals;
      } else {
        _sentReferrals.addAll(newReferrals);
      }

      _sentTotalPages = response['total_pages'] ?? 1;

      print('Loaded ${newReferrals.length} sent referrals (page $_sentCurrentPage/$_sentTotalPages)');

    } catch (e) {
      print('Failed to load sent referrals: $e');
      _error = 'Failed to load sent referrals';
      if (refresh) {
        _sentReferrals = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load received referrals (for parents)
  Future<void> loadReceivedReferrals({
    bool refresh = false,
    String? status,
    String? referralType,
  }) async {
    if (refresh) {
      _receivedCurrentPage = 1;
      _receivedReferrals.clear();
    }

    _isLoading = true;
    if (refresh) {
      _error = null;
    }
    notifyListeners();

    try {
      final response = await ApiService.getReceivedReferrals(
        page: _receivedCurrentPage,
        pageSize: 20,
        status: status,
        referralType: referralType,
      );

      final referralsList = response['referrals'] as List? ?? [];
      final newReferrals = referralsList.map((json) => ReferralModel.fromJson(json)).toList();

      if (refresh) {
        _receivedReferrals = newReferrals;
      } else {
        _receivedReferrals.addAll(newReferrals);
      }

      _receivedTotalPages = response['total_pages'] ?? 1;

      print('Loaded ${newReferrals.length} received referrals (page $_receivedCurrentPage/$_receivedTotalPages)');

    } catch (e) {
      print('Failed to load received referrals: $e');
      _error = 'Failed to load received referrals';
      if (refresh) {
        _receivedReferrals = [];
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more sent referrals
  Future<void> loadMoreSentReferrals() async {
    if (_isLoading || !hasSentMorePages) return;

    _sentCurrentPage++;
    await loadSentReferrals();
  }

  // Load more received referrals
  Future<void> loadMoreReceivedReferrals() async {
    if (_isLoading || !hasReceivedMorePages) return;

    _receivedCurrentPage++;
    await loadReceivedReferrals();
  }

  // Search users (for creating referrals)
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.searchUsers(
        query: query.trim(),
        role: 'service_user', // Only search for parents
        limit: 20,
      );

      final usersList = response['users'] as List? ?? [];
      _searchResults = usersList.map((json) => UserSearchResult.fromJson(json)).toList();

      print('Found ${_searchResults.length} users for query: $query');

    } catch (e) {
      print('Failed to search users: $e');
      _error = 'Failed to search users';
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Create referral
  Future<bool> createReferral(CreateReferralRequest request) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.createReferral(request);
      final newReferral = ReferralModel.fromJson(response);

      // Add to sent referrals list
      _sentReferrals.insert(0, newReferral);

      print('Successfully created referral: ${newReferral.id}');

      _isCreating = false;
      notifyListeners();
      return true;

    } catch (e) {
      print('Failed to create referral: $e');
      _error = e.toString().replaceAll('Exception: ', '');

      _isCreating = false;
      notifyListeners();
      return false;
    }
  }

  // Update referral status
  Future<bool> updateReferralStatus(String referralId, String status) async {
    try {
      await ApiService.updateReferralStatus(referralId, status);

      // Update in received referrals list
      final index = _receivedReferrals.indexWhere((r) => r.id == referralId);
      if (index != -1) {
        final updatedReferral = ReferralModel.fromJson({
          ..._receivedReferrals[index].toJson(),
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        });
        _receivedReferrals[index] = updatedReferral;
      }

      print('Successfully updated referral status: $referralId -> $status');
      notifyListeners();
      return true;

    } catch (e) {
      print('Failed to update referral status: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Get referral details
  Future<void> loadReferralDetails(String referralId) async {
    try {
      final response = await ApiService.getReferral(referralId);
      _selectedReferral = ReferralModel.fromJson(response);
      print('Loaded referral details: ${_selectedReferral!.id}');
      notifyListeners();
    } catch (e) {
      print('Failed to load referral details: $e');
      _error = 'Failed to load referral details';
      notifyListeners();
    }
  }

  // Clear selected referral
  void clearSelectedReferral() {
    _selectedReferral = null;
    notifyListeners();
  }

  // Check if an item has been referred to a user
  bool isItemReferred(String itemId, String itemType) {
    return _receivedReferrals.any((referral) =>
    referral.itemId == itemId &&
        referral.referralType == itemType &&
        referral.status != 'declined'
    );
  }

  // Get referral for a specific item
  ReferralModel? getReferralForItem(String itemId, String itemType) {
    try {
      return _receivedReferrals.firstWhere((referral) =>
      referral.itemId == itemId &&
          referral.referralType == itemType &&
          referral.status != 'declined'
      );
    } catch (e) {
      return null;
    }
  }

  // Get pending referrals count
  int get pendingReceivedCount {
    return _receivedReferrals.where((r) => r.isPending).length;
  }

  int get pendingSentCount {
    return _sentReferrals.where((r) => r.isPending).length;
  }

  // Get referrals by status
  List<ReferralModel> getSentReferralsByStatus(String status) {
    return _sentReferrals.where((r) => r.status == status).toList();
  }

  List<ReferralModel> getReceivedReferralsByStatus(String status) {
    return _receivedReferrals.where((r) => r.status == status).toList();
  }

  // Get referrals by type
  List<ReferralModel> getSentReferralsByType(String type) {
    return _sentReferrals.where((r) => r.referralType == type).toList();
  }

  List<ReferralModel> getReceivedReferralsByType(String type) {
    return _receivedReferrals.where((r) => r.referralType == type).toList();
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadSentReferrals(refresh: true),
      loadReceivedReferrals(refresh: true),
    ]);
  }

  // Get referral statistics
  Map<String, int> getSentReferralStats() {
    final stats = <String, int>{
      'total': _sentReferrals.length,
      'pending': 0,
      'accepted': 0,
      'declined': 0,
      'viewed': 0,
      'services': 0,
      'resources': 0,
      'support_groups': 0,
    };

    for (final referral in _sentReferrals) {
      stats[referral.status] = (stats[referral.status] ?? 0) + 1;
      stats[referral.referralType] = (stats[referral.referralType] ?? 0) + 1;
    }

    return stats;
  }

  Map<String, int> getReceivedReferralStats() {
    final stats = <String, int>{
      'total': _receivedReferrals.length,
      'pending': 0,
      'accepted': 0,
      'declined': 0,
      'viewed': 0,
      'services': 0,
      'resources': 0,
      'support_groups': 0,
    };

    for (final referral in _receivedReferrals) {
      stats[referral.status] = (stats[referral.status] ?? 0) + 1;
      stats[referral.referralType] = (stats[referral.referralType] ?? 0) + 1;
    }

    return stats;
  }
}