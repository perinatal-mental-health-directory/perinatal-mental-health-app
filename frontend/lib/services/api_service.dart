
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Authentication endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> register(String email, String fullName, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _storage.write(key: 'token', value: data['token']);
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  static Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // User endpoints
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user profile: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateCurrentUser(Map<String, dynamic> userData) async {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: headers,
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // Services endpoints
  static Future<List<dynamic>> getServices({int page = 1, int pageSize = 20}) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/services?page=$page&page_size=$pageSize'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['services'] ?? [];
    } else {
      throw Exception('Failed to get services: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getService(String serviceId) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get service: ${response.body}');
    }
  }

  // Feedback endpoints
  static Future<Map<String, dynamic>> submitFeedback(String serviceId, int rating, String comment) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/feedback'),
      headers: headers,
      body: jsonEncode({
        'service_id': serviceId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit feedback: ${response.body}');
    }
  }

  // Referrals endpoints
  static Future<Map<String, dynamic>> createReferral(String serviceId, String notes) async {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/referrals'),
      headers: headers,
      body: jsonEncode({
        'service_id': serviceId,
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create referral: ${response.body}');
    }
  }

  static Future<List<dynamic>> getReferrals({int page = 1, int pageSize = 20}) async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/referrals?page=$page&page_size=$pageSize'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['referrals'] ?? [];
    } else {
      throw Exception('Failed to get referrals: ${response.body}');
    }
  }
}
