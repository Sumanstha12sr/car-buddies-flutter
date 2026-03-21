import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_models.dart';
import 'api_service.dart';

class ServiceApiService {
  static const String baseUrl =
      'https://obeyingly-flamy-humberto.ngrok-free.dev/api/services';
  final ApiService _apiService = ApiService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== CUSTOMER ====================

  /// Get all service categories with their services
  Future<List<ServiceCategory>> getServiceCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((j) => ServiceCategory.fromJson(j)).toList();
      }
      print('❌ getServiceCategories: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('❌ getServiceCategories exception: $e');
      return [];
    }
  }

  /// Get services under a specific category
  Future<List<Service>> getServicesByCategory(String categoryName) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/category/$categoryName/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((j) => Service.fromJson(j)).toList();
      }
      print('❌ getServicesByCategory: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ getServicesByCategory exception: $e');
      return [];
    }
  }

  /// Create a new service booking
  Future<Map<String, dynamic>> createServiceBooking({
    required String serviceId,
    required String vehicleId,
    required String bookingDate,
    required String preferredTime,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/create/'),
        headers: headers,
        body: jsonEncode({
          'service': serviceId,
          'vehicle': vehicleId,
          'booking_date': bookingDate,
          'preferred_time': preferredTime,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );

      print('📡 createServiceBooking: ${response.statusCode}');
      print('📡 body: ${response.body}');

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

  /// Get all bookings for logged-in customer
  Future<List<ServiceBooking>> getCustomerServiceBookings({
    String? category,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/bookings/';
      if (category != null) url += '?category=$category';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((j) => ServiceBooking.fromJson(j)).toList();
      }
      print('❌ getCustomerServiceBookings: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ getCustomerServiceBookings exception: $e');
      return [];
    }
  }

  /// Cancel a booking
  Future<bool> cancelServiceBooking(String bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Submit feedback after service
  Future<Map<String, dynamic>> submitFeedback({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/feedback/'),
        headers: headers,
        body: jsonEncode({
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
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

  /// Get vehicle health report
  Future<ServiceReport?> getServiceReport(String bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId/report/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return ServiceReport.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('❌ getServiceReport exception: $e');
      return null;
    }
  }

  // ==================== STAFF ====================

  /// Staff: get all service bookings
  Future<List<ServiceBooking>> staffGetAllServiceBookings({
    String? category,
    String? bookingStatus,
  }) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/staff/bookings/';
      final params = <String>[];
      if (category != null) params.add('category=$category');
      if (bookingStatus != null) params.add('status=$bookingStatus');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((j) => ServiceBooking.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('❌ staffGetAllServiceBookings exception: $e');
      return [];
    }
  }

  /// Staff: update booking status
  Future<Map<String, dynamic>> staffUpdateBookingStatus({
    required String bookingId,
    required String newStatus,
    String? staffNotes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/staff/bookings/$bookingId/update-status/'),
        headers: headers,
        body: jsonEncode({
          'status': newStatus,
          if (staffNotes != null && staffNotes.isNotEmpty)
            'staff_notes': staffNotes,
        }),
      );
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'data': {'error': 'Connection error: $e'},
      };
    }
  }

  /// Staff: get available mechanics
  Future<List<dynamic>> staffGetAvailableMechanics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/staff/mechanics/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('❌ staffGetAvailableMechanics exception: $e');
      return [];
    }
  }

  /// Staff: assign mechanic to EV check booking
  Future<Map<String, dynamic>> staffAssignMechanic({
    required String bookingId,
    required String mechanicId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/staff/bookings/$bookingId/assign-mechanic/'),
        headers: headers,
        body: jsonEncode({'mechanic_id': mechanicId}),
      );
      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'data': {'error': 'Connection error: $e'},
      };
    }
  }

  /// Staff: get service statistics
  Future<Map<String, dynamic>?> staffGetServiceStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/staff/statistics/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ staffGetServiceStatistics exception: $e');
      return null;
    }
  }

  // ==================== CUSTOMER ANALYTICS ====================

  /// Get customer analytics (spending, trends, bookings breakdown)
  Future<Map<String, dynamic>?> getCustomerAnalytics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/customer/analytics/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('❌ getCustomerAnalytics: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ getCustomerAnalytics exception: $e');
      return null;
    }
  }

  // ==================== CONFLICT CHECK ====================

  /// Check which hours are already booked for a vehicle on a date
  /// Returns list of booked hours e.g. [9, 10, 14]
  Future<List<int>> getVehicleBookedSlots({
    required String vehicleId,
    required String date, // format: YYYY-MM-DD
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicle/$vehicleId/booked-slots/?date=$date'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<int>.from(data['booked_hours'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ getVehicleBookedSlots exception: $e');
      return [];
    }
  }
}
