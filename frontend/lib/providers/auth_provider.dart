import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Clear error method
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Check if user is already authenticated on app start
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token != null) {
        // Try to get user profile to validate token
        final userProfile = await ApiService.getCurrentUserProfile();
        _user = userProfile;
        _isAuthenticated = true;
        print('User authenticated: ${_user?['email']}');
      }
    } catch (e) {
      print('Auth check failed: $e');
      _isAuthenticated = false;
      _user = null;
      // Clear invalid tokens
      await ApiService.logout();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login method
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      _user = response['user'];
      _isAuthenticated = true;
      print('Login successful: ${_user?['email']}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _user = null;

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register method
  Future<bool> register(String email, String fullName, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Map frontend roles to backend roles
      String backendRole;
      switch (role.toLowerCase()) {
        case 'professional':
          backendRole = 'professional';
          break;
        case 'support staff':
          backendRole = 'nhs_staff';
          break;
        case 'parent':
          backendRole = 'service_user';
          break;
        default:
          backendRole = 'service_user';
      }

      final response = await ApiService.register(email, fullName, password, backendRole);
      _user = response['user'];
      _isAuthenticated = true;
      print('Registration successful: ${_user?['email']}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Registration failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _user = null;

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add this method to your existing AuthProvider class in frontend/lib/providers/auth_provider.dart

  // Enhanced register method with profile information
  Future<bool> registerWithProfile({
    required String email,
    required String fullName,
    required String password,
    required String role,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Map frontend roles to backend roles
      String backendRole;
      switch (role.toLowerCase()) {
        case 'professional':
          backendRole = 'professional';
          break;
        case 'nhs staff':
          backendRole = 'nhs_staff';
          break;
        case 'parent':
          backendRole = 'service_user';
          break;
        default:
          backendRole = 'service_user';
      }

      final response = await ApiService.registerWithProfile(
        email: email,
        fullName: fullName,
        password: password,
        role: backendRole,
        phoneNumber: phoneNumber,
        address: address,
        dateOfBirth: dateOfBirth,
      );

      _user = response['user'];
      _isAuthenticated = true;
      print('Registration with profile successful: ${_user?['email']}');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Registration failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _user = null;

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Forgot password method
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.forgotPassword(email);
      print('Password reset email sent to: $email');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Forgot password failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    await ApiService.logout();
    _isAuthenticated = false;
    _user = null;
    _error = null;
    print('User logged out');
    notifyListeners();
  }

  // Update profile method
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await ApiService.updateCurrentUser(userData);
      _user = updatedUser;
      print('Profile updated successfully');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Profile update failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get user role display name
  String getUserRoleDisplayName() {
    if (_user == null) return 'Unknown';

    switch (_user!['role']?.toString().toLowerCase()) {
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

  // Check server health
  Future<bool> checkServerConnection() async {
    try {
      return await ApiService.checkServerHealth();
    } catch (e) {
      print('Server health check failed: $e');
      return false;
    }
  }
}

