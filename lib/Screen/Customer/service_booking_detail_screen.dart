import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service_models.dart';
import '../../services/service_api_service.dart';

class ServiceBookingDetailScreen extends StatefulWidget {
  final ServiceBooking booking;

  const ServiceBookingDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<ServiceBookingDetailScreen> createState() =>
      _ServiceBookingDetailScreenState();
}

class _ServiceBookingDetailScreenState
    extends State<ServiceBookingDetailScreen> {
  final ServiceApiService _serviceApi = ServiceApiService();
  late ServiceBooking _booking;
  bool _isCancelling = false;
  bool _isSubmittingFeedback = false;

  int _rating = 5;
  final _commentController = TextEditingController();

  bool get _isCarWash => _booking.isCarWash;
  Color get _themeColor =>
      _isCarWash ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
  Color get _lightColor =>
      _isCarWash ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    final success = await _serviceApi.cancelServiceBooking(_booking.id);
    setState(() => _isCancelling = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel booking'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmittingFeedback = true);

    final result = await _serviceApi.submitFeedback(
      bookingId: _booking.id,
      rating: _rating,
      comment: _commentController.text.trim(),
    );

    setState(() => _isSubmittingFeedback = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.pop(context); // close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['data']['error'] ?? 'Failed to submit feedback'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFeedbackSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rate Your Experience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'How was your ${_booking.serviceName}?',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setSheetState(() => _rating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color:
                            star <= _rating ? Colors.amber : Colors.grey[300],
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Comment
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _themeColor, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmittingFeedback ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmittingFeedback
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit Feedback',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Booking Details',
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
            // ── Status Banner ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _booking.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: _booking.statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(_booking.status),
                      color: _booking.statusColor, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    _booking.statusText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _booking.statusColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd').format(_booking.bookingDate),
                    style: TextStyle(fontSize: 13, color: _booking.statusColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Service Details ──────────────────────────────
            _buildCard(
              title: 'Service',
              children: [
                _infoRow(Icons.miscellaneous_services, 'Service',
                    _booking.serviceName),
                _infoRow(Icons.category_outlined, 'Category',
                    _isCarWash ? 'Car Wash' : 'EV Check'),
                _infoRow(
                    Icons.calendar_today,
                    'Date',
                    DateFormat('EEEE, MMM dd, yyyy')
                        .format(_booking.bookingDate)),
                _infoRow(Icons.access_time, 'Time',
                    _booking.preferredTime.substring(0, 5)),
                _infoRow(Icons.payments_outlined, 'Cost',
                    'NPR ${_booking.estimatedCost?.toStringAsFixed(2) ?? _booking.servicePrice.toStringAsFixed(2)}'),
              ],
            ),

            const SizedBox(height: 14),

            // ── Vehicle ──────────────────────────────────────
            _buildCard(
              title: 'Vehicle',
              children: [
                _infoRow(Icons.directions_car, 'Name', _booking.vehicleName),
                _infoRow(Icons.confirmation_number_outlined, 'Number',
                    _booking.vehicleNumber),
              ],
            ),

            // ── Mechanic (EV Check only) ─────────────────────
            if (_booking.isEvCheck) ...[
              const SizedBox(height: 14),
              _buildCard(
                title: 'Assigned Mechanic',
                children: [
                  _booking.mechanicName != null
                      ? _infoRow(
                          Icons.engineering, 'Mechanic', _booking.mechanicName!)
                      : Row(
                          children: [
                            Icon(Icons.hourglass_empty,
                                size: 16, color: Colors.orange[400]),
                            const SizedBox(width: 10),
                            Text(
                              'Mechanic will be assigned soon',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.orange[600]),
                            ),
                          ],
                        ),
                ],
              ),
            ],

            // ── Staff Notes ──────────────────────────────────
            if (_booking.staffNotes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildCard(
                title: 'Staff Notes',
                children: [
                  Text(
                    _booking.staffNotes,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],

            // ── EV Health Report ─────────────────────────────
            if (_booking.hasReport) ...[
              const SizedBox(height: 14),
              _buildReportCard(_booking.report!),
            ],

            // ── Feedback ─────────────────────────────────────
            if (_booking.feedback != null) ...[
              const SizedBox(height: 14),
              _buildFeedbackCard(_booking.feedback!),
            ],

            const SizedBox(height: 24),

            // ── Action Buttons ───────────────────────────────
            if (_booking.canCancel)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isCancelling ? null : _cancelBooking,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.red, strokeWidth: 2))
                      : const Text(
                          'Cancel Booking',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),

            if (_booking.canFeedback) ...[
              if (_booking.canCancel) const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _showFeedbackSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text(
                    'Give Feedback',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────

  Widget _buildCard({required String title, required List<Widget> children}) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ...children
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: c,
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildReportCard(ServiceReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: report.conditionColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  color: report.conditionColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Vehicle Health Report',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Overall condition chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: report.conditionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: report.conditionColor),
                const SizedBox(width: 8),
                Text(
                  'Overall: ${report.conditionText}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: report.conditionColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Battery health bar
          if (report.batteryHealth != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.battery_charging_full,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Battery Health: ${report.batteryHealth}%',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: report.batteryHealth! / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  report.batteryHealth! > 70
                      ? Colors.green
                      : report.batteryHealth! > 40
                          ? Colors.orange
                          : Colors.red,
                ),
                minHeight: 8,
              ),
            ),
          ],

          if (report.issuesFound.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Issues Found',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              report.issuesFound,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
          ],

          if (report.recommendations.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Recommendations',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              report.recommendations,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(CustomerFeedback feedback) {
    return _buildCard(
      title: 'Your Feedback',
      children: [
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < feedback.rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 22,
            ),
          ),
        ),
        if (feedback.comment.isNotEmpty)
          Text(
            feedback.comment,
            style:
                TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
      ],
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
