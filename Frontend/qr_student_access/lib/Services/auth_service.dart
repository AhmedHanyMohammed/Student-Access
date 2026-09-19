import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/user.dart';
import 'api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_jwt_token';
  static const String _userKey = 'auth_user_json';

  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  /// Registers a new user with the backend API.
  Future<UserProfile> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/auth/register');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone?.trim(),
      }),
    );

    final data = _decodeBody(response.body);

    if (response.statusCode == 200) {
      final token = data['token'] as String;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession(token, user);
      return user;
    } else {
      final message = data['message'] ?? 'Registration failed with code ${response.statusCode}';
      throw Exception(message);
    }
  }

  /// Logs in an existing user with email and password.
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/auth/login');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final data = _decodeBody(response.body);

    if (response.statusCode == 200) {
      final token = data['token'] as String;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession(token, user);
      return user;
    } else {
      final message = data['message'] ?? 'Invalid credentials.';
      throw Exception(message);
    }
  }

  /// Retrieves the stored JWT token.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Retrieves the cached logged-in user profile.
  Future<UserProfile?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Checks if user is authenticated.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logs out user and clears local session.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Returns HTTP headers including the Bearer Authorization header if available.
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> _persistSession(String token, UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'message': body};
    }
  }
}
