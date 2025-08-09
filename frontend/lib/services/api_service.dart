import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Helper method to get headers with auth token
  static Future<Map<String, String>> getHeaders() async {
    final token = await _storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Authentication endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Add this method to your ApiService class in frontend/lib/services/api_service.dart

  // Enhanced registration with profile information
  static Future<Map<String, dynamic>> registerWithProfile({
    required String email,
    required String fullName,
    required String password,
    required String role,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
  }) async {
    try {
      final requestBody = {
        'email': email,
        'full_name': fullName,
        'password': password,
        'role': role,
      };

      // Add optional profile fields
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        requestBody['phone_number'] = phoneNumber;
      }
      if (address != null && address.isNotEmpty) {
        requestBody['address'] = address;
      }
      if (dateOfBirth != null) {
        requestBody['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0]; // YYYY-MM-DD format
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Enhanced register response status: ${response.statusCode}');
      print('Enhanced register response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Enhanced register error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  static Future<Map<String, dynamic>> register(String email, String fullName, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'full_name': fullName,
          'password': password,
          'role': role.toLowerCase().replaceAll(' ', '_'), // Convert "NHS Staff" to "nhs_staff"
        }),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Register error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Forgot password response status: ${response.statusCode}');
      print('Forgot password response body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      print('Forgot password error: $e');
      throw Exception('Failed to send reset email: $e');
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        throw Exception('No refresh token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(key: 'refresh_token', value: data['refresh_token']);
        return data;
      } else {
        await logout(); // Clear invalid tokens
        throw Exception('Session expired');
      }
    } catch (e) {
      print('Refresh token error: $e');
      throw Exception('Session expired');
    }
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  // User endpoints
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: headers,
      );

      print('Get profile response status: ${response.statusCode}');
      print('Get profile response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Try to refresh token
        await refreshToken();
        // Retry the request
        final newHeaders = await getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/me'),
          headers: newHeaders,
        );

        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to get user profile');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get user profile');
      }
    } catch (e) {
      print('Get profile error: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }

  static Future<Map<String, dynamic>> updateCurrentUser(Map<String, dynamic> userData) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/me'),
        headers: headers,
        body: jsonEncode(userData),
      );

      print('Update user response status: ${response.statusCode}');
      print('Update user response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Try to refresh token
        await refreshToken();
        // Retry the request
        final newHeaders = await getHeaders();
        final retryResponse = await http.put(
          Uri.parse('$baseUrl/me'),
          headers: newHeaders,
          body: jsonEncode(userData),
        );

        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to update user');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update user');
      }
    } catch (e) {
      print('Update user error: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Services endpoints
  static Future<Map<String, dynamic>> getServices({
    int page = 1,
    int pageSize = 20,
    String? serviceType,
    String? search,
    String? location,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (serviceType != null && serviceType.isNotEmpty) {
        queryParams['service_type'] = serviceType;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }

      final uri = Uri.parse('$baseUrl/services').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Get services response status: ${response.statusCode}');
      print('Get services response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get services');
      }
    } catch (e) {
      print('Get services error: $e');
      return {
        'services': [],
        'total': 0,
        'page': page,
        'page_size': pageSize,
        'total_pages': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> searchServices({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/services').replace(queryParameters: {
        'search': query,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Search services response status: ${response.statusCode}');
      print('Search services response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search services');
      }
    } catch (e) {
      print('Search services error: $e');
      return {
        'services': [],
        'total': 0,
        'page': page,
        'page_size': pageSize,
        'total_pages': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> getService(String serviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/services/$serviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Get service response status: ${response.statusCode}');
      print('Get service response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Service not found');
      }
    } catch (e) {
      print('Get service error: $e');
      throw Exception('Failed to get service: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getFeaturedServices({int limit = 6}) async {
    try {
      final uri = Uri.parse('$baseUrl/services/featured').replace(queryParameters: {
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Get featured services response status: ${response.statusCode}');
      print('Get featured services response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['services'] ?? []);
      } else {
        throw Exception('Failed to get featured services');
      }
    } catch (e) {
      print('Get featured services error: $e');
      return [];
    }
  }

  // Feedback endpoints
  static Future<Map<String, dynamic>> submitFeedback({
    required bool anonymous,
    required String rating,
    required String feedback,
    required String category,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: headers,
        body: jsonEncode({
          'anonymous': anonymous,
          'rating': rating,
          'feedback': feedback,
          'category': category,
        }),
      );

      print('Submit feedback response status: ${response.statusCode}');
      print('Submit feedback response body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to submit feedback');
      }
    } catch (e) {
      print('Submit feedback error: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // Referrals endpoints
  static Future<Map<String, dynamic>> createReferral({
    required String patientName,
    required String contact,
    required String reason,
    required String serviceType,
    required bool isUrgent,
    int? serviceId,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/referrals'),
        headers: headers,
        body: jsonEncode({
          'patient_name': patientName,
          'contact': contact,
          'reason': reason,
          'service_type': serviceType,
          'is_urgent': isUrgent,
          if (serviceId != null) 'service_id': serviceId,
        }),
      );

      print('Create referral response status: ${response.statusCode}');
      print('Create referral response body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create referral');
      }
    } catch (e) {
      print('Create referral error: $e');
      throw Exception('Failed to create referral: $e');
    }
  }

  static Future<List<dynamic>> getReferrals({int page = 1, int pageSize = 20}) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/referrals?page=$page&page_size=$pageSize'),
        headers: headers,
      );

      print('Get referrals response status: ${response.statusCode}');
      print('Get referrals response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['referrals'] ?? [];
      } else {
        throw Exception('Failed to get referrals');
      }
    } catch (e) {
      print('Get referrals error: $e');
      return []; // Return empty list on error
    }
  }

  // Add these methods to your existing ApiService class in frontend/lib/services/api_service.dart

  // Change password endpoint
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      print('Change password response status: ${response.statusCode}');
      print('Change password response body: ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        // Try to refresh token
        await refreshToken();
        // Retry the request
        final newHeaders = await getHeaders();
        final retryResponse = await http.post(
          Uri.parse('$baseUrl/auth/change-password'),
          headers: newHeaders,
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        );

        if (retryResponse.statusCode == 200) {
          return;
        } else {
          final errorData = jsonDecode(retryResponse.body);
          throw Exception(errorData['error'] ?? 'Failed to change password');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to change password');
      }
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Failed to change password: $e');
    }
  }

  // Update user profile with extended information
  static Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    String? address,
    String? emergencyContact,
  }) async {
    try {
      final headers = await getHeaders();
      final updateData = <String, dynamic>{};

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (emergencyContact != null) updateData['emergency_contact'] = emergencyContact;

      final response = await http.put(
        Uri.parse('$baseUrl/me'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // Try to refresh token
        await refreshToken();
        // Retry the request
        final newHeaders = await getHeaders();
        final retryResponse = await http.put(
          Uri.parse('$baseUrl/me'),
          headers: newHeaders,
          body: jsonEncode(updateData),
        );

        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to update profile');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user preferences/settings
  static Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/me/preferences'),
        headers: headers,
      );

      print('Get preferences response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/me/preferences'),
          headers: newHeaders,
        );

        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          return {}; // Return empty preferences if not found
        }
      } else {
        return {}; // Return empty preferences if not found
      }
    } catch (e) {
      print('Get preferences error: $e');
      return {}; // Return empty preferences on error
    }
  }

  // Update user preferences
  static Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/me/preferences'),
        headers: headers,
        body: jsonEncode(preferences),
      );

      print('Update preferences response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.put(
          Uri.parse('$baseUrl/me/preferences'),
          headers: newHeaders,
          body: jsonEncode(preferences),
        );

        if (retryResponse.statusCode != 200) {
          throw Exception('Failed to update preferences');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update preferences');
      }
    } catch (e) {
      print('Update preferences error: $e');
      throw Exception('Failed to update preferences: $e');
    }
  }

  // Health check endpoint
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceAll('/api/v1', '')}/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print('Health check response status: ${response.statusCode}');
      print('Health check response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }

  // Add these methods to your ApiService class in frontend/lib/services/api_service.dart

  // Privacy Settings Endpoints

  // Add these methods to your existing ApiService class in frontend/lib/services/api_service.dart

// Privacy Settings Endpoints

// Get user privacy preferences
  static Future<Map<String, dynamic>> getPrivacyPreferences() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/privacy/preferences'),
        headers: headers,
      );

      print('Get privacy preferences response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/privacy/preferences'),
          headers: newHeaders,
        );

        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          return {}; // Return empty preferences if not found
        }
      } else {
        return {}; // Return empty preferences if not found
      }
    } catch (e) {
      print('Get privacy preferences error: $e');
      return {}; // Return empty preferences on error
    }
  }

// Update user privacy preferences
  static Future<void> updatePrivacyPreferences(Map<String, dynamic> preferences) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/privacy/preferences'),
        headers: headers,
        body: jsonEncode(preferences),
      );

      print('Update privacy preferences response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.put(
          Uri.parse('$baseUrl/privacy/preferences'),
          headers: newHeaders,
          body: jsonEncode(preferences),
        );

        if (retryResponse.statusCode != 200) {
          final errorData = jsonDecode(retryResponse.body);
          throw Exception(errorData['error'] ?? 'Failed to update privacy preferences');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update privacy preferences');
      }
    } catch (e) {
      print('Update privacy preferences error: $e');
      throw Exception('Failed to update privacy preferences: $e');
    }
  }

// Request data download
  static Future<void> requestDataDownload() async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/privacy/request-data-download'),
        headers: headers,
      );

      print('Request data download response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.post(
          Uri.parse('$baseUrl/privacy/request-data-download'),
          headers: newHeaders,
        );

        if (retryResponse.statusCode != 200) {
          final errorData = jsonDecode(retryResponse.body);
          throw Exception(errorData['error'] ?? 'Failed to request data download');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to request data download');
      }
    } catch (e) {
      print('Request data download error: $e');
      throw Exception('Failed to request data download: $e');
    }
  }

// Request account deletion
  static Future<void> requestAccountDeletion(String reason) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/privacy/request-account-deletion'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );

      print('Request account deletion response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.post(
          Uri.parse('$baseUrl/privacy/request-account-deletion'),
          headers: newHeaders,
          body: jsonEncode({'reason': reason}),
        );

        if (retryResponse.statusCode != 200) {
          final errorData = jsonDecode(retryResponse.body);
          throw Exception(errorData['error'] ?? 'Failed to request account deletion');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to request account deletion');
      }
    } catch (e) {
      print('Request account deletion error: $e');
      throw Exception('Failed to request account deletion: $e');
    }
  }

  // Get data retention information
  static Future<Map<String, dynamic>> getDataRetentionInfo() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/privacy/data-retention-info'),
        headers: headers,
      );

      print('Get data retention info response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/privacy/data-retention-info'),
          headers: newHeaders,
        );

        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to get data retention info');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get data retention info');
      }
    } catch (e) {
      print('Get data retention info error: $e');
      throw Exception('Failed to get data retention info: $e');
    }
  }

// Export user data
  static Future<String> exportUserData() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/privacy/export-data'),
        headers: headers,
      );

      print('Export user data response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonEncode(data); // Return as JSON string
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/privacy/export-data'),
          headers: newHeaders,
        );

        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          return jsonEncode(data);
        } else {
          throw Exception('Failed to export user data');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to export user data');
      }
    } catch (e) {
      print('Export user data error: $e');
      throw Exception('Failed to export user data: $e');
    }
  }

// Get user data requests
  static Future<List<dynamic>> getDataRequests() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/privacy/data-requests'),
        headers: headers,
      );

      print('Get data requests response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['requests'] ?? [];
      } else if (response.statusCode == 401) {
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/privacy/data-requests'),
          headers: newHeaders,
        );

        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          return data['requests'] ?? [];
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Get data requests error: $e');
      return [];
    }
  }

  // Add these methods to your existing ApiService class in frontend/lib/services/api_service.dart

// Resources endpoints
  static Future<Map<String, dynamic>> getResources({
    int page = 1,
    int pageSize = 20,
    String? resourceType,
    String? targetAudience,
    String? search,
    String? tags,
    bool? featured,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (resourceType != null && resourceType.isNotEmpty) {
        queryParams['resource_type'] = resourceType;
      }

      if (targetAudience != null && targetAudience.isNotEmpty) {
        queryParams['target_audience'] = targetAudience;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags;
      }

      if (featured != null) {
        queryParams['featured'] = featured.toString();
      }

      final uri = Uri.parse('$baseUrl/resources').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Get resources response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get resources');
      }
    } catch (e) {
      print('Get resources error: $e');
      return {
        'resources': [],
        'total': 0,
        'page': page,
        'page_size': pageSize,
        'total_pages': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> getResource(int resourceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resources/$resourceId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Get resource response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Resource not found');
      }
    } catch (e) {
      print('Get resource error: $e');
      throw Exception('Failed to get resource: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getFeaturedResources({int limit = 6}) async {
    try {
      final uri = Uri.parse('$baseUrl/resources/featured').replace(queryParameters: {
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Get featured resources response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['resources'] ?? []);
      } else {
        throw Exception('Failed to get featured resources');
      }
    } catch (e) {
      print('Get featured resources error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPopularResources({int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/resources/popular').replace(queryParameters: {
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Get popular resources response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['resources'] ?? []);
      } else {
        throw Exception('Failed to get popular resources');
      }
    } catch (e) {
      print('Get popular resources error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> searchResources({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/resources/search').replace(queryParameters: {
        'q': query,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Search resources response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search resources');
      }
    } catch (e) {
      print('Search resources error: $e');
      return {
        'resources': [],
        'total': 0,
        'page': page,
        'page_size': pageSize,
        'total_pages': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> getResourcesByTag({
    required String tag,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/resources/by-tag').replace(queryParameters: {
        'tag': tag,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Get resources by tag response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get resources by tag');
      }
    } catch (e) {
      print('Get resources by tag error: $e');
      return {
        'resources': [],
        'total': 0,
        'page': page,
        'page_size': pageSize,
        'total_pages': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> getResourcesByAudience({
    required String audience,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/resources/by-audience').replace(queryParameters: {
        'audience': audience,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });

      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

      print('Get resources by audience response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get resources by audience');
      }
    } catch (e) {
      print('Get resources by audience error: $e');
      return {
        'resources': [],
        'total': 0,
        'page': page,
        'page_size': pageSize,
        'total_pages': 0,
      };
    }
  }

  static Future<void> incrementResourceViewCount(int resourceId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/resources/$resourceId/view'),
        headers: headers,
      );

      print('Increment view count response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        // Try to refresh token
        await refreshToken();
        final newHeaders = await getHeaders();
        final retryResponse = await http.post(
          Uri.parse('$baseUrl/resources/$resourceId/view'),
          headers: newHeaders,
        );

        if (retryResponse.statusCode != 200) {
          throw Exception('Failed to increment view count');
        }
      } else {
        throw Exception('Failed to increment view count');
      }
    } catch (e) {
      print('Increment view count error: $e');
      // Don't throw error for view count as it's not critical
    }
  }
}

