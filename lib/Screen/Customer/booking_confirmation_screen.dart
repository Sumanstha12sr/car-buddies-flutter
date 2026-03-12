import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/charging_models.dart';
import '../../services/charging_api_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final ChargingStation station;
  final Charger charger;
  final Vehicle vehicle;
  final TimeSlot timeSlot;
  final DateTime bookingDate;

  const BookingConfirmationScreen({
    super.key,
    required this.station,
    required this.charger,
    required this.vehicle,
    required this.timeSlot,
    required this.bookingDate,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final ChargingApiService _apiService = ChargingApiService();
  final _notesController = TextEditingController();
  double _estimatedEnergy = 0;
  double _estimatedCost = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateEstimate();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _calculateEstimate() {
    _estimatedEnergy = widget.vehicle.batteryCapacity * 0.5;
    _estimatedCost = _estimatedEnergy * widget.charger.pricePerKwh;
    setState(() {});
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    // ── Updated to use named parameters ──────────────────────────
    final result = await _apiService.createBooking(
      chargerId: widget.charger.id,
      vehicleId: widget.vehicle.id,
      timeSlotId: widget.timeSlot.id,
      bookingDate: widget.timeSlot.date.toIso8601String().split('T')[0],
      estimatedEnergy: _estimatedEnergy,
      notes: _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          title: const Text('Booking Confirmed!'),
          content: const Text(
            'Your charging slot has been booked successfully. '
            'Please wait for staff confirmation.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                int count = 0;
                Navigator.of(context).popUntil((_) => count++ >= 4);
              },
              child: const Text('Go to Home'),
            ),
            ElevatedButton(
              onPressed: () {
                int count = 0;
                Navigator.of(context).popUntil((_) => count++ >= 4);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'View Bookings',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      String errorMessage = 'Failed to create booking';
      if (result['data'] is Map) {
        errorMessage = result['data']['error'] ??
            result['data']['detail'] ??
            result['data']['non_field_errors']?.toString() ??
            errorMessage;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Info
            _buildSectionCard(
              icon: Icons.ev_station,
              title: 'Charging Station',
              color: Colors.green,
              children: [
                _buildInfoRow('Station', widget.station.name),
                _buildInfoRow('Address', widget.station.address),
              ],
            ),

            const SizedBox(height: 16),

            // Charger Info
            _buildSectionCard(
              icon: widget.charger.chargerType == 'AC'
                  ? Icons.flash_on
                  : Icons.bolt,
              title: 'Charger Details',
              color: widget.charger.chargerType == 'AC'
                  ? Colors.blue
                  : Colors.orange,
              children: [
                _buildInfoRow('Charger', widget.charger.chargerName),
                _buildInfoRow('Type', '${widget.charger.chargerType} Charger'),
                _buildInfoRow(
                    'Power Output', '${widget.charger.powerOutput} kW'),
                _buildInfoRow('Price', 'NPR ${widget.charger.pricePerKwh}/kWh'),
              ],
            ),

            const SizedBox(height: 16),

            // Vehicle Info
            _buildSectionCard(
              icon: Icons.directions_car,
              title: 'Vehicle',
              color: Colors.purple,
              children: [
                _buildInfoRow('Name', widget.vehicle.vehicleName),
                _buildInfoRow('Number', widget.vehicle.vehicleNumber),
                _buildInfoRow(
                    'Battery', '${widget.vehicle.batteryCapacity} kWh'),
              ],
            ),

            const SizedBox(height: 16),

            // Time Slot Info
            _buildSectionCard(
              icon: Icons.access_time,
              title: 'Time Slot',
              color: Colors.teal,
              children: [
                _buildInfoRow(
                  'Date',
                  DateFormat('EEEE, MMM dd, yyyy').format(widget.timeSlot.date),
                ),
                _buildInfoRow(
                  'Time',
                  '${widget.timeSlot.startTime} - ${widget.timeSlot.endTime}',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cost Estimate
            Card(
              elevation: 4,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.green),
                        SizedBox(width: 12),
                        Text(
                          'Estimated Cost',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Estimated Energy',
                      '${_estimatedEnergy.toStringAsFixed(2)} kWh',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Cost',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'NPR ${_estimatedCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any special instructions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              '* Final charges may vary based on actual energy consumed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
