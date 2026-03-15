import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/charging_models.dart';
import 'api_service.dart';

class ChargingApiService {
  // static const String baseUrl = 'http:// 192.168.1.218:8000/api/charging';
  //static const String baseUrl =
  // 'https://web-production-a06f0.up.railway.app/api/charging';
  static const String baseUrl =
      'https://obeyingly-flamy-humberto.ngrok-free.dev/api/charging';

  final ApiService _apiService = ApiService();

  // Auth headers
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
      print(' getVehicles error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print(' getVehicles exception: $e');
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stations/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChargingStation.fromJson(json)).toList();
      }
      print(
          ' getChargingStations error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print(' getChargingStations exception: $e');
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
      print(' getStationDetail exception: $e');
      return null;
    }
  }

  // ==================== CHARGERS ====================

  Future<List<Charger>> getAvailableChargers(String stationId,
      {String? type}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/stations/$stationId/chargers/';
      if (type != null) url += '?type=$type';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Charger.fromJson(json)).toList();
      }
      print(
          ' getAvailableChargers error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print(' getAvailableChargers exception: $e');
      return [];
    }
  }

  // Get ALL chargers including occupied ones
  Future<List<Charger>> getAllChargers(String stationId, {String? type}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stations/$stationId/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> chargersJson = data['chargers'] ?? [];
        List<Charger> chargers =
            chargersJson.map((json) => Charger.fromJson(json)).toList();
        if (type != null) {
          chargers = chargers.where((c) => c.chargerType == type).toList();
        }
        return chargers;
      }
      return [];
    } catch (e) {
      print(' getAllChargers exception: $e');
      return [];
    }
  }

  // ==================== TIME SLOTS ====================

  Future<List<TimeSlot>> getAvailableTimeSlots(
      String chargerId, DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = date.toIso8601String().split('T')[0];

      // checking debugs
      print('🔍 Fetching time slots:');
      print('   chargerId: $chargerId');
      print('   date: $dateStr');
      print('   URL: $baseUrl/chargers/$chargerId/time-slots/?date=$dateStr');

      final response = await http.get(
        Uri.parse('$baseUrl/chargers/$chargerId/time-slots/?date=$dateStr'),
        headers: headers,
      );

      print('📡 Time slots status: ${response.statusCode}');
      print('📡 Time slots body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TimeSlot.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print(' getAvailableTimeSlots exception: $e');
      return [];
    }
  }

  // ==================== BOOKINGS ====================

  Future<Map<String, dynamic>> createBooking({
    required String chargerId,
    required String vehicleId,
    required String timeSlotId,
    required String bookingDate,
    double? estimatedEnergy,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/create/'),
        headers: headers,
        body: jsonEncode({
          'charger': chargerId,
          'vehicle': vehicleId,
          'time_slot': timeSlotId,
          'booking_date': bookingDate,
          if (estimatedEnergy != null) 'estimated_energy': estimatedEnergy,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );

      print('📡 createBooking status: ${response.statusCode}');
      print('📡 createBooking body: ${response.body}');

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
      print(
          ' getCustomerBookings error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print(' getCustomerBookings exception: $e');
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

  // ==================== STAFF ENDPOINTS ====================

  Future<List<ChargingBooking>> getAllBookings({String? status}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/bookings/all/';
      if (status != null) url += '?status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChargingBooking.fromJson(json)).toList();
      }
      print(' getAllBookings error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print(' getAllBookings exception: $e');
      return [];
    }
  }

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

  Future<Map<String, dynamic>?> getBookingStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/statistics/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print(' getBookingStatistics exception: $e');
      return null;
    }
  }

  // ==================== LIVE AVAILABILITY ====================

  Future<List<dynamic>> getLiveStationAvailability() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/stations/live-availability/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print(' getLiveStationAvailability exception: $e');
      return [];
    }
  }
}
