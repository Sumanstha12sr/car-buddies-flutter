import 'dart:ui';

// ==================== SERVICE CATEGORY ====================

class ServiceCategory {
  final int id;
  final String name;
  final String displayName;
  final String description;
  final bool isActive;
  final List<Service> services;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.isActive,
    required this.services,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['name'] == 'car_wash' ? 'Car Wash' : 'EV Check',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
      services: (json['services'] as List<dynamic>? ?? [])
          .map((s) => Service.fromJson(s))
          .toList(),
    );
  }
}

// ==================== SERVICE ====================

class Service {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String categoryName;
  final String categoryType;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.categoryName,
    required this.categoryType,
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      durationMinutes: json['duration_minutes'] ?? 0,
      categoryName: json['category_name'] ?? '',
      categoryType: json['category_type'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}

// ==================== SERVICE REPORT ====================

class ServiceReport {
  final String id;
  final String issuesFound;
  final String recommendations;
  final String overallCondition;
  final int? batteryHealth;
  final DateTime createdAt;

  ServiceReport({
    required this.id,
    required this.issuesFound,
    required this.recommendations,
    required this.overallCondition,
    this.batteryHealth,
    required this.createdAt,
  });

  factory ServiceReport.fromJson(Map<String, dynamic> json) {
    return ServiceReport(
      id: json['id'] ?? '',
      issuesFound: json['issues_found'] ?? '',
      recommendations: json['recommendations'] ?? '',
      overallCondition: json['overall_condition'] ?? 'good',
      batteryHealth: json['battery_health'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Color get conditionColor {
    switch (overallCondition) {
      case 'excellent':
        return const Color(0xFF2E7D32);
      case 'good':
        return const Color(0xFF4CAF50);
      case 'fair':
        return const Color(0xFFFF9800);
      case 'poor':
        return const Color(0xFFFF5722);
      case 'critical':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get conditionText =>
      overallCondition[0].toUpperCase() + overallCondition.substring(1);
}

// ==================== CUSTOMER FEEDBACK ====================

class CustomerFeedback {
  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;

  CustomerFeedback({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory CustomerFeedback.fromJson(Map<String, dynamic> json) {
    return CustomerFeedback(
      id: json['id'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

// ==================== SERVICE BOOKING ====================

class ServiceBooking {
  final String id;
  final String status;
  final DateTime bookingDate;
  final String preferredTime;
  final double? estimatedCost;
  final String notes;
  final String staffNotes;
  final DateTime createdAt;

  // Service info
  final String serviceName;
  final double servicePrice;
  final int serviceDuration;
  final String categoryType;

  // Customer info
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  // Vehicle info
  final String vehicleName;
  final String vehicleNumber;

  // Mechanic info
  final String? mechanicName;

  // Nested
  final ServiceReport? report;
  final CustomerFeedback? feedback;

  ServiceBooking({
    required this.id,
    required this.status,
    required this.bookingDate,
    required this.preferredTime,
    this.estimatedCost,
    required this.notes,
    required this.staffNotes,
    required this.createdAt,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    required this.categoryType,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.vehicleName,
    required this.vehicleNumber,
    this.mechanicName,
    this.report,
    this.feedback,
  });

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    return ServiceBooking(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      bookingDate: json['booking_date'] != null
          ? DateTime.parse(json['booking_date'])
          : DateTime.now(),
      preferredTime: json['preferred_time'] ?? '',
      estimatedCost: json['estimated_cost'] != null
          ? double.tryParse(json['estimated_cost'].toString())
          : null,
      notes: json['notes'] ?? '',
      staffNotes: json['staff_notes'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      serviceName: json['service_name'] ?? '',
      servicePrice: double.tryParse(json['service_price'].toString()) ?? 0.0,
      serviceDuration: json['service_duration'] ?? 0,
      categoryType: json['category_type'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? '',
      mechanicName: json['mechanic_name'],
      report: json['report'] != null
          ? ServiceReport.fromJson(json['report'])
          : null,
      feedback: json['feedback'] != null
          ? CustomerFeedback.fromJson(json['feedback'])
          : null,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────
  bool get isCarWash => categoryType == 'car_wash';
  bool get isEvCheck => categoryType == 'ev_check';
  bool get canCancel => status == 'pending' || status == 'confirmed';
  bool get canFeedback => status == 'completed' && feedback == null;
  bool get hasReport => report != null;

  Color get statusColor {
    switch (status) {
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

  String get statusText {
    return status
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
