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
}