import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.180:8000/api';
  // Customer Registration
  Future<Map<String, dynamic>> customerRegister({
    required String email,
    required String fullName,
    required String password,
    required String passwordConfirm,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'full_name': fullName,
          'password': password,
          'password_confirm': passwordConfirm,
          'phone': phone ?? '',
        }),
      );

      return {
        'success': response.statusCode == 201,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'data': {'error': 'Connection error: $e'},
      };
    }
  }

  // Customer Login
  Future<Map<String, dynamic>> customerLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/customer/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      // print(response.statusCode);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save token
        await _saveToken(data['access']);
        // ADD THESE DEBUG LINES
        final savedToken = await getToken();
        print('✅ Token saved: $savedToken');

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'data': jsonDecode(response.body)};
      }
    } catch (e) {
      return {
        'success': false,
        'data': {'error': 'Connection error: $e'},
      };
    }
  }

  // Staff Login
  Future<Map<String, dynamic>> staffLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/staff/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save token
        await _saveToken(data['access']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'data': jsonDecode(response.body)};
      }
    } catch (e) {
      return {
        'success': false,
        'data': {'error': 'Connection error: $e'},
      };
    }
  }

  // Save token to local storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Get token from local storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
