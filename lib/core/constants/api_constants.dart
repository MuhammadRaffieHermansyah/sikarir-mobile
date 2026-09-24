class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.10.5.145:8000/api';

  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
}
