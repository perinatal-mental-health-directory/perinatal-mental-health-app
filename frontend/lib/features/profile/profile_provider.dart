// frontend/lib/features/profile/profile_provider.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Load user profile
  Future<void> loadUserProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userProfile = await ApiService.getCurrentUserProfile();
      print('Profile loaded: ${_userProfile?['user']?['email']}');
    } catch (e) {
      print('Failed to load profile: $e');
      _error = 'Failed to load profile';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{};

      if (fullName != null && fullName.isNotEmpty) {
        updateData['full_name'] = fullName;
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        updateData['phone_number'] = phoneNumber;
      }
      if (address != null && address.isNotEmpty) {
        updateData['address'] = address;
      }

      if (updateData.isEmpty) {
        _error = 'No changes to save';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updatedProfile = await ApiService.updateCurrentUser(updateData);
      _userProfile = updatedProfile;
      print('Profile updated successfully');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to update profile: $e');
      _error = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Note: You'll need to add this endpoint to your backend
      await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      print('Password changed successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to change password: $e');
      _error = 'Failed to change password: ${e.toString().replaceAll('Exception: ', '')}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Submit feedback
  Future<bool> submitFeedback({
    required bool anonymous,
    required String rating,
    required String feedback,
    String category = 'general',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.submitFeedback(
        anonymous: anonymous,
        rating: rating,
        feedback: feedback,
        category: category,
      );

      print('Feedback submitted successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to submit feedback: $e');
      _error = 'Failed to submit feedback';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get user role display name
  String getUserRoleDisplayName() {
    final role = _userProfile?['user']?['role']?.toString().toLowerCase();
    switch (role) {
      case 'professional':
        return 'Professional';
      case 'nhs_staff':
        return 'NHS Staff';
      case 'charity':
        return 'Charity';
      case 'service_user':
        return 'Parent';
      default:
        return 'User';
    }
  }

  // Get user email
  String getUserEmail() {
    return _userProfile?['user']?['email'] ?? 'user@example.com';
  }

  // Get user full name
  String getUserFullName() {
    return _userProfile?['user']?['full_name'] ?? 'User';
  }

  // Get user phone number
  String? getUserPhoneNumber() {
    return _userProfile?['phone_number'];
  }

  // Get user address
  String? getUserAddress() {
    return _userProfile?['address'];
  }
}