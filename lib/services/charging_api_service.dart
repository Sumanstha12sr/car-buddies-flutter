import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/charging_models.dart';
import 'api_service.dart';

class ChargingApiService {
  static const String baseUrl =
      'https://obeyingly-flamy-humberto.ngrok-free.dev/api/charging';
  final ApiService _apiService = ApiService();

  // ── Auth headers ─────────────────────────────────────────────────
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
      print('❌ getVehicles error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('❌ getVehicles exception: $e');
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
          '❌ getChargingStations error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('❌ getChargingStations exception: $e');
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
      print('❌ getStationDetail exception: $e');
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
          '❌ getAvailableChargers error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('❌ getAvailableChargers exception: $e');
      return [];
    }
  }

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
      print('❌ getAllChargers exception: $e');
      return [];
    }
  }

  // ==================== TIME SLOTS ====================

  /// Main method used by TimeSlotSelectionScreen
  /// Backend returns a flat List of slot objects directly
  Future<Map<String, dynamic>> getAvailableTimeSlotsWithMeta({
    required String chargerId,
    required DateTime date,
    required String vehicleId,
  }) async {
    try {
      final headers = await _getHeaders();
      final dateStr = date.toIso8601String().split('T')[0];
      final url =
          '$baseUrl/chargers/$chargerId/time-slots/?date=$dateStr&vehicle_id=$vehicleId';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📡 timeslots status: ${response.statusCode}');
      print('📡 timeslots body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        List<TimeSlot> slotsList = [];

        // ── Handle both response shapes safely ───────────────────
        // Shape A — flat list (current backend): [ {...}, {...} ]
        // Shape B — wrapped map (old backend):   { "slots": [...] }
        if (body is List) {
          slotsList = body
              .map((json) => _timeSlotFromJson(json as Map<String, dynamic>))
              .toList();
        } else if (body is Map && body['slots'] != null) {
          slotsList = (body['slots'] as List)
              .map((json) => _timeSlotFromJson(json as Map<String, dynamic>))
              .toList();
        }

        return {
          'slots': slotsList,
          'hours_needed': (body is Map) ? (body['hours_needed'] ?? 1) : 1,
          'charger_type': (body is Map) ? (body['charger_type'] ?? '') : '',
          'charger_power': (body is Map) ? (body['charger_power'] ?? '') : '',
          'vehicle_battery':
              (body is Map) ? (body['vehicle_battery'] ?? '') : '',
        };
      }

      print(
          '❌ getAvailableTimeSlotsWithMeta: ${response.statusCode} ${response.body}');
      return {'slots': <TimeSlot>[], 'hours_needed': 1};
    } catch (e) {
      print('❌ getAvailableTimeSlotsWithMeta exception: $e');
      return {'slots': <TimeSlot>[], 'hours_needed': 1};
    }
  }

  /// Fetches time slots for car wash / EV checkup from backend.
  /// Passes serviceId so backend can check:
  ///   - is_available: false  → another user booked this service at this time
  ///   - user_conflict: true  → this customer already has a booking at this time
  Future<List<Map<String, dynamic>>> getServiceTimeSlots({
    required DateTime date,
    String? serviceId,
  }) async {
    try {
      final headers = await _getHeaders();
      final dateStr = date.toIso8601String().split('T')[0];

      // ── Always include service ID so backend can check per-service availability
      // If serviceId is null, return empty — caller should wait for service selection
      if (serviceId == null || serviceId.isEmpty) {
        print('⚠️ getServiceTimeSlots: serviceId is null, skipping fetch');
        return [];
      }

      final url =
          '$baseUrl/services/time-slots/?date=$dateStr&service=$serviceId';

      print('📡 getServiceTimeSlots url: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('📡 getServiceTimeSlots status: ${response.statusCode}');
      print('📡 getServiceTimeSlots body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((s) => Map<String, dynamic>.from(s)).toList();
      }
      return [];
    } catch (e) {
      print('❌ getServiceTimeSlots exception: $e');
      return [];
    }
  }

  /// Legacy method kept for backward compatibility
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
        final body = jsonDecode(response.body);
        if (body is List) {
          return body
              .map((json) => _timeSlotFromJson(json as Map<String, dynamic>))
              .toList();
        } else if (body is Map && body['slots'] != null) {
          return (body['slots'] as List)
              .map((json) => _timeSlotFromJson(json as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ getAvailableTimeSlots exception: $e');
      return [];
    }
  }

  /// Parses a single slot JSON object into a TimeSlot
  /// Handles both old and new backend response fields
  TimeSlot _timeSlotFromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id']?.toString() ?? '',
      chargerId: json['charger']?.toString() ?? '',
      chargerName: json['charger_name']?.toString() ?? '',
      chargerType: json['charger_type']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isAvailable: json['is_available'] ?? true,
      blockedReason: json['blocked_reason']?.toString(),
      warning: json['warning']?.toString(),
      // ── New field: cross-service conflict flag ──────────────
      userConflict: json['user_conflict'] ?? false,
    );
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
          '❌ getCustomerBookings error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('❌ getCustomerBookings exception: $e');
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
      print('❌ getAllBookings error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('❌ getAllBookings exception: $e');
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
      print('❌ getBookingStatistics exception: $e');
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
      print('❌ getLiveStationAvailability exception: $e');
      return [];
    }
  }
}
