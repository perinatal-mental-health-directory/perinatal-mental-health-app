// frontend/lib/features/profile/privacy_provider.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PrivacyProvider with ChangeNotifier {
  Map<String, dynamic> _preferences = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic> get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Individual preference getters
  bool get dataTrackingEnabled => _preferences['data_tracking_enabled'] ?? true;
  bool get dataSharingEnabled => _preferences['data_sharing_enabled'] ?? false;
  bool get cookiesEnabled => _preferences['cookies_enabled'] ?? true;
  bool get marketingEmailsEnabled => _preferences['marketing_emails_enabled'] ?? false;
  bool get analyticsEnabled => _preferences['analytics_enabled'] ?? true;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load user privacy preferences
  Future<void> loadPrivacyPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _preferences = await ApiService.getPrivacyPreferences();
      print('Privacy preferences loaded: $_preferences');
    } catch (e) {
      print('Failed to load privacy preferences: $e');
      _error = 'Failed to load privacy settings';
      // Set default preferences if loading fails
      _preferences = {
        'data_tracking_enabled': true,
        'data_sharing_enabled': false,
        'cookies_enabled': true,
        'marketing_emails_enabled': false,
        'analytics_enabled': true,
      };
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update individual preference
  Future<bool> updatePreference(String key, dynamic value) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedPreferences = Map<String, dynamic>.from(_preferences);
      updatedPreferences[key] = value;

      await ApiService.updatePrivacyPreferences(updatedPreferences);
      _preferences = updatedPreferences;

      print('Privacy preference updated: $key = $value');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to update privacy preference: $e');
      _error = 'Failed to update privacy setting';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update multiple preferences at once
  Future<bool> updatePreferences(Map<String, dynamic> newPreferences) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.updatePrivacyPreferences(newPreferences);
      _preferences = Map<String, dynamic>.from(newPreferences);

      print('Privacy preferences updated: $newPreferences');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to update privacy preferences: $e');
      _error = 'Failed to update privacy settings';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Request data download
  Future<bool> requestDataDownload() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.requestDataDownload();
      print('Data download requested successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to request data download: $e');
      _error = 'Failed to request data download';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Request account deletion
  Future<bool> requestAccountDeletion(String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.requestAccountDeletion(reason);
      print('Account deletion requested successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to request account deletion: $e');
      _error = 'Failed to request account deletion';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get data retention information
  Future<Map<String, dynamic>?> getDataRetentionInfo() async {
    try {
      return await ApiService.getDataRetentionInfo();
    } catch (e) {
      print('Failed to get data retention info: $e');
      _error = 'Failed to load data retention information';
      notifyListeners();
      return null;
    }
  }

  // Export user data
  Future<String?> exportUserData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final exportData = await ApiService.exportUserData();
      _isLoading = false;
      notifyListeners();
      return exportData;
    } catch (e) {
      print('Failed to export user data: $e');
      _error = 'Failed to export user data';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Reset all preferences to default
  Future<bool> resetToDefaultPreferences() async {
    final defaultPreferences = {
      'data_tracking_enabled': true,
      'data_sharing_enabled': false,
      'cookies_enabled': true,
      'marketing_emails_enabled': false,
      'analytics_enabled': true,
    };

    return await updatePreferences(defaultPreferences);
  }
}