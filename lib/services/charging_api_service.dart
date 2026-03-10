// Create file: lib/services/charging_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/charging_models.dart';
import 'api_service.dart';

class ChargingApiService {
  static const String baseUrl = 'http://192.168.1.180:8000/api/charging';
  final ApiService _apiService = ApiService();

  // Get authorization header
  Future<Map<String, String>> _getHeaders() async {
    final token = await _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== VEHICLE MANAGEMENT ====================

  Future<List<Vehicle>> getVehicles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vehicles: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addVehicle(
      Map<String, dynamic> vehicleData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/add/'),
        headers: headers,
        body: jsonEncode(vehicleData),
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

  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$vehicleId/delete/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setDefaultVehicle(String vehicleId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/$vehicleId/set-default/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== CHARGING STATIONS ====================

  Future<List<ChargingStation>> getChargingStations() async {
    try {
      print('🔗 URL being called: ${Uri.parse('$baseUrl/stations/')}');
      final headers = await _getHeaders();
      // ADD THESE DEBUG LINES
      print('📡 Fetching stations...');
      print('🔑 Headers: $headers');

      final response = await http.get(
        Uri.parse('$baseUrl/stations/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChargingStation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching stations: $e');
      return [];
    }
  }

  Future<ChargingStation?> getStationDetail(String stationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stations/$stationId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return ChargingStation.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching station detail: $e');
      return null;
    }
  }

  // ==================== CHARGERS & TIME SLOTS ====================

  Future<List<Charger>> getAvailableChargers(String stationId,
      {String? type}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/stations/$stationId/chargers/';
      if (type != null) {
        url += '?type=$type';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Charger.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching chargers: $e');
      return [];
    }
  }

  Future<List<TimeSlot>> getAvailableTimeSlots(
      String chargerId, DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await http.get(
        Uri.parse('$baseUrl/chargers/$chargerId/time-slots/?date=$dateStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TimeSlot.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching time slots: $e');
      return [];
    }
  }

  // ==================== BOOKINGS ====================

  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/create/'),
        headers: headers,
        body: jsonEncode(bookingData),
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

  Future<List<ChargingBooking>> getCustomerBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChargingBooking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
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

  // ==================== STAFF: GET ALL BOOKINGS ====================

  Future<List<ChargingBooking>> getAllBookings() async {
    try {
      final headers = await _getHeaders();
      // This endpoint should be created for staff to see all bookings
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/all/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChargingBooking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching all bookings: $e');
      return [];
    }
  }

  // ==================== STAFF: UPDATE BOOKING STATUS ====================

  Future<Map<String, dynamic>> updateBookingStatus(
      String bookingId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/update-status/'),
        headers: headers,
        body: jsonEncode({'status': status}),
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
}
