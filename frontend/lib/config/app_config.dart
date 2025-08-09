// lib/config/app_config.dart
class AppConfig {
  // Backend Configuration
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // For Android emulator, use 10.0.2.2 instead of localhost
  // static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  // For iOS simulator, localhost should work
  // For physical devices, use your machine's IP address
  // static const String baseUrl = 'http://192.168.1.100:8080/api/v1';

  // Timeout configurations
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Storage keys
  static const String tokenKey = 'token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // App information
  static const String appName = 'Perinatal Mental Health App';
  static const String appVersion = '1.0.0';

  // Feature flags
  static const bool debugMode = true;
  static const bool enableLogging = true;
}