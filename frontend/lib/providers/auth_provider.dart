import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token != null) {
        final userProfile = await ApiService.getCurrentUserProfile();
        _user = userProfile['user'];
        _isAuthenticated = true;
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password);
      _user = response['user'];
      _isAuthenticated = true;
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(String email, String fullName, String password, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(email, fullName, password, role);
      _user = response['user'];
      _isAuthenticated = true;
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> userData) async {
    try {
      final updatedUser = await ApiService.updateCurrentUser(userData);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
