class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.example.com/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // User
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/update';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
