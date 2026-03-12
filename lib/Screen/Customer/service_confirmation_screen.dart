import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service_models.dart';
import '../../models/charging_models.dart';
import '../../services/service_api_service.dart';

class ServiceConfirmationScreen extends StatefulWidget {
  final Service service;
  final Vehicle vehicle;
  final DateTime bookingDate;
  final TimeOfDay preferredTime;
  final String notes;

  const ServiceConfirmationScreen({
    super.key,
    required this.service,
    required this.vehicle,
    required this.bookingDate,
    required this.preferredTime,
    required this.notes,
  });

  @override
  State<ServiceConfirmationScreen> createState() =>
      _ServiceConfirmationScreenState();
}

class _ServiceConfirmationScreenState extends State<ServiceConfirmationScreen> {
  final ServiceApiService _serviceApi = ServiceApiService();
  bool _isLoading = false;

  bool get _isCarWash => widget.service.categoryType == 'car_wash';
  Color get _themeColor =>
      _isCarWash ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
  Color get _lightColor =>
      _isCarWash ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9);

  String get _formattedTime {
    final hour = widget.preferredTime.hourOfPeriod == 0
        ? 12
        : widget.preferredTime.hourOfPeriod;
    final period = widget.preferredTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:00 $period';
  }

  String get _formattedTimeForApi {
    final h = widget.preferredTime.hour.toString().padLeft(2, '0');
    return '$h:00:00';
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    final result = await _serviceApi.createServiceBooking(
      serviceId: widget.service.id,
      vehicleId: widget.vehicle.id,
      bookingDate: widget.bookingDate.toIso8601String().split('T')[0],
      preferredTime: _formattedTimeForApi,
      notes: widget.notes,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lightColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: _themeColor, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking Submitted!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your ${widget.service.name} booking has been submitted. '
                'Staff will confirm shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Pop back to services screen
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 3);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    } else {
      final error = result['data']['error'] ??
          result['data']['detail'] ??
          'Failed to create booking';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Confirm Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Service Summary Card ─────────────────────────
            _buildCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _lightColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isCarWash
                              ? Icons.local_car_wash
                              : Icons.electric_car,
                          color: _themeColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.service.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.service.categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                color: _themeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'NPR ${widget.service.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _themeColor,
                        ),
                      ),
                    ],
                  ),
                  if (widget.service.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      widget.service.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Booking Details Card ─────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow(
                      Icons.calendar_today,
                      'Date',
                      DateFormat('EEEE, MMM dd, yyyy')
                          .format(widget.bookingDate)),
                  const SizedBox(height: 10),
                  _infoRow(Icons.access_time, 'Time', _formattedTime),
                  const SizedBox(height: 10),
                  _infoRow(Icons.timer_outlined, 'Duration',
                      '${widget.service.durationMinutes} minutes'),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Vehicle Card ─────────────────────────────────
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _infoRow(
                      Icons.directions_car, 'Name', widget.vehicle.vehicleName),
                  const SizedBox(height: 10),
                  _infoRow(Icons.confirmation_number_outlined, 'Number',
                      widget.vehicle.vehicleNumber),
                ],
              ),
            ),

            if (widget.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.notes,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ── Price Summary ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Total',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'NPR ${widget.service.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _themeColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Text(
              '* Final charges may vary based on actual service',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 28),

            // ── Confirm Button ───────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _themeColor),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
