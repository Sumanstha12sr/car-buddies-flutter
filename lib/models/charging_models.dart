import 'dart:ui';

class Vehicle {
  final String id;
  final String vehicleName;
  final String vehicleNumber;
  final String vehicleType; // 'electric', 'hybrid', 'ice'
  final double? batteryCapacity; // nullable for ICE
  final String? chargingPortType; // nullable for ICE
  final bool isDefault;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.vehicleType,
    this.batteryCapacity,
    this.chargingPortType,
    required this.isDefault,
    required this.createdAt,
  });

  bool get isEv => vehicleType == 'electric' || vehicleType == 'hybrid';
  bool get isIce => vehicleType == 'ice';

  String get vehicleTypeLabel {
    switch (vehicleType) {
      case 'electric':
        return 'Electric (EV)';
      case 'hybrid':
        return 'Hybrid';
      case 'ice':
        return 'Petrol / Diesel';
      default:
        return vehicleType;
    }
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'electric',
      batteryCapacity: json['battery_capacity'] != null
          ? double.tryParse(json['battery_capacity'].toString())
          : null,
      chargingPortType: json['charging_port_type'],
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'vehicle_name': vehicleName,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'is_default': isDefault,
    };
    if (batteryCapacity != null) map['battery_capacity'] = batteryCapacity;
    if (chargingPortType != null && chargingPortType!.isNotEmpty) {
      map['charging_port_type'] = chargingPortType;
    }
    return map;
  }
}

class ChargingStation {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? description;
  final List<String> amenities;
  final String operatingHours;
  final int totalChargers;
  final int availableChargers;
  final int acChargersCount;
  final int dcChargersCount;
  final bool isActive;

  ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.description,
    required this.amenities,
    required this.operatingHours,
    required this.totalChargers,
    required this.availableChargers,
    required this.acChargersCount,
    required this.dcChargersCount,
    required this.isActive,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      description: json['description'],
      amenities: List<String>.from(json['amenities_list'] ?? []),
      operatingHours: json['operating_hours'] ?? '24/7',
      totalChargers: json['total_chargers'] ?? 0,
      availableChargers: json['available_chargers'] ?? 0,
      acChargersCount: json['ac_chargers_count'] ?? 0,
      dcChargersCount: json['dc_chargers_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class Charger {
  final String id;
  final String stationName;
  final String chargerName;
  final String chargerType;
  final double powerOutput;
  final String connectorTypes;
  final List<String> connectorTypesList;
  final double pricePerKwh;
  final String status;
  final bool isAvailable;

  Charger({
    required this.id,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
    required this.powerOutput,
    required this.connectorTypes,
    required this.connectorTypesList,
    required this.pricePerKwh,
    required this.status,
    required this.isAvailable,
  });

  factory Charger.fromJson(Map<String, dynamic> json) {
    return Charger(
      id: json['id'] ?? '',
      stationName: json['station_name'] ?? '',
      chargerName: json['charger_name'] ?? '',
      chargerType: json['charger_type'] ?? '',
      powerOutput: double.tryParse(json['power_output'].toString()) ?? 0.0,
      connectorTypes: json['connector_types'] ?? '',
      connectorTypesList: List<String>.from(json['connector_types_list'] ?? []),
      pricePerKwh: double.tryParse(json['price_per_kwh'].toString()) ?? 0.0,
      status: json['status'] ?? 'available',
      isAvailable: json['is_available'] ?? false,
    );
  }
}

class TimeSlot {
  final String id;
  final String chargerId;
  final String chargerName;
  final String chargerType;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final String? blockedReason; // 'booked' or 'insufficient_time'
  final String? warning; // warning message if close to closing
  final bool
      userConflict; // true if customer already has a booking at this time

  TimeSlot({
    required this.id,
    required this.chargerId,
    required this.chargerName,
    required this.chargerType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.blockedReason,
    this.warning,
    this.userConflict = false, // defaults to false so nothing breaks
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      chargerId: json['charger'] ?? '',
      chargerName: json['charger_name'] ?? '',
      chargerType: json['charger_type'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isAvailable: json['is_available'] ?? true,
      blockedReason: json['blocked_reason'],
      warning: json['warning'],
      userConflict: json['user_conflict'] ?? false, // reads from API response
    );
  }
}

class ChargingBooking {
  final String id;
  final String customerName;
  final String vehicleId;
  final String vehicleNumber;
  final String vehicleName;
  final String chargerId;
  final String stationName;
  final String chargerName;
  final String chargerType;
  final String timeSlotId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final double? estimatedEnergy;
  final double? estimatedCost;
  final double? actualEnergy;
  final double? actualCost;
  final String status;
  final String? notes;
  final DateTime createdAt;

  ChargingBooking({
    required this.id,
    required this.customerName,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleName,
    required this.chargerId,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
    required this.timeSlotId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    this.estimatedEnergy,
    this.estimatedCost,
    this.actualEnergy,
    this.actualCost,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory ChargingBooking.fromJson(Map<String, dynamic> json) {
    return ChargingBooking(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? '',
      vehicleId: json['vehicle']?.toString() ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      chargerId: json['charger']?.toString() ?? '',
      stationName: json['station_name'] ?? '',
      chargerName: json['charger_name'] ?? '',
      chargerType: json['charger_type'] ?? '',
      timeSlotId: json['time_slot']?.toString() ?? '',
      bookingDate: json['booking_date'] != null
          ? DateTime.parse(json['booking_date'])
          : DateTime.now(),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      estimatedEnergy: json['estimated_energy'] != null
          ? double.tryParse(json['estimated_energy'].toString())
          : null,
      estimatedCost: json['estimated_cost'] != null
          ? double.tryParse(json['estimated_cost'].toString())
          : null,
      actualEnergy: json['actual_energy'] != null
          ? double.tryParse(json['actual_energy'].toString())
          : null,
      actualCost: json['actual_cost'] != null
          ? double.tryParse(json['actual_cost'].toString())
          : null,
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'confirmed':
        return const Color(0xFF4CAF50);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF9E9E9E);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String getStatusText() {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
