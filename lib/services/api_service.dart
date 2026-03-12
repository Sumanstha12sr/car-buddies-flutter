import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.218:8000/api';
  //static const String baseUrl =
  // 'https://web-production-a06f0.up.railway.app/api';
  //  REGISTRATION

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
          'confirm_password': passwordConfirm,
          'phone_number': phone ?? '',
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

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // customer login
      final customerResponse = await http.post(
        Uri.parse('$baseUrl/login/customer/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (customerResponse.statusCode == 200) {
        final data = jsonDecode(customerResponse.body);
        await _saveToken(data['access']);
        await _saveUserType('customer');
        print(' Customer login successful');
        return {'success': true, 'data': data};
      }

      // staff login
      final staffResponse = await http.post(
        Uri.parse('$baseUrl/login/staff/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (staffResponse.statusCode == 200) {
        final data = jsonDecode(staffResponse.body);
        await _saveToken(data['access']);
        await _saveUserType('staff');
        print(' Staff login successful');
        return {'success': true, 'data': data};
      }

      try {
        final errorData = jsonDecode(customerResponse.body);
        final errorMsg = errorData['error'] ??
            errorData['detail'] ??
            'Invalid email or password';
        return {
          'success': false,
          'data': {'error': errorMsg},
        };
      } catch (_) {
        return {
          'success': false,
          'data': {'error': 'Invalid email or password'},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': {'error': 'Connection error. Check your network.'},
      };
    }
  }

  // other functions

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access']);
        await _saveUserType('customer');
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
        await _saveToken(data['access']);
        await _saveUserType('staff');
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

  // ==================== TOKEN MANAGEMENT ====================

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<void> _saveUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', userType);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_type');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
