import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/charging_models.dart';
import '../../services/charging_api_service.dart';

class StaffBookingDetailScreen extends StatefulWidget {
  final ChargingBooking booking;

  const StaffBookingDetailScreen({Key? key, required this.booking})
      : super(key: key);

  @override
  State<StaffBookingDetailScreen> createState() =>
      _StaffBookingDetailScreenState();
}

class _StaffBookingDetailScreenState extends State<StaffBookingDetailScreen> {
  final ChargingApiService _apiService = ChargingApiService();
  late ChargingBooking _booking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);

    final result =
        await _apiService.updateBookingStatus(_booking.id, newStatus);

    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      Navigator.pop(context, true); // Return true to indicate update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Booking status updated to ${newStatus.replaceAll('_', ' ')}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update booking status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showStatusDialog() async {
    final statuses = [
      if (_booking.status == 'pending') 'confirmed',
      if (_booking.status == 'confirmed') 'in_progress',
      if (_booking.status == 'in_progress') 'completed',
      if (_booking.status != 'cancelled' && _booking.status != 'completed')
        'cancelled',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return ListTile(
              title: Text(status
                  .split('_')
                  .map((s) => s[0].toUpperCase() + s.substring(1))
                  .join(' ')),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      _updateStatus(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.green,
        actions: [
          if (_booking.status != 'completed' && _booking.status != 'cancelled')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _isLoading ? null : _showStatusDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _booking.getStatusColor(),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _booking.getStatusText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer Info
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Customer Information',
                    color: Colors.blue,
                    children: [
                      _buildInfoRow('Customer Name', _booking.customerName),
                      _buildInfoRow('Vehicle', _booking.vehicleName),
                      _buildInfoRow('Vehicle Number', _booking.vehicleNumber),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Station & Charger Info
                  _buildInfoCard(
                    icon: Icons.ev_station,
                    title: 'Charging Details',
                    color: Colors.green,
                    children: [
                      _buildInfoRow('Station', _booking.stationName),
                      _buildInfoRow('Charger', _booking.chargerName),
                      _buildInfoRow('Type', '${_booking.chargerType} Charger'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Time Info
                  _buildInfoCard(
                    icon: Icons.access_time,
                    title: 'Booking Time',
                    color: Colors.orange,
                    children: [
                      _buildInfoRow(
                        'Date',
                        DateFormat('EEEE, MMM dd, yyyy')
                            .format(_booking.bookingDate),
                      ),
                      _buildInfoRow(
                        'Time Slot',
                        '${_booking.startTime} - ${_booking.endTime}',
                      ),
                      _buildInfoRow(
                        'Booked On',
                        DateFormat('MMM dd, yyyy HH:mm')
                            .format(_booking.createdAt),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Cost Info
                  _buildInfoCard(
                    icon: Icons.payment,
                    title: 'Payment Details',
                    color: Colors.purple,
                    children: [
                      if (_booking.estimatedEnergy != null)
                        _buildInfoRow(
                          'Estimated Energy',
                          '${_booking.estimatedEnergy!.toStringAsFixed(2)} kWh',
                        ),
                      if (_booking.estimatedCost != null)
                        _buildInfoRow(
                          'Estimated Cost',
                          'NPR ${_booking.estimatedCost!.toStringAsFixed(2)}',
                        ),
                      if (_booking.actualEnergy != null)
                        _buildInfoRow(
                          'Actual Energy',
                          '${_booking.actualEnergy!.toStringAsFixed(2)} kWh',
                        ),
                      if (_booking.actualCost != null)
                        _buildInfoRow(
                          'Actual Cost',
                          'NPR ${_booking.actualCost!.toStringAsFixed(2)}',
                        ),
                    ],
                  ),

                  if (_booking.notes != null && _booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.notes,
                      title: 'Customer Notes',
                      color: Colors.teal,
                      children: [
                        Text(
                          _booking.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_booking.status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _updateStatus('confirmed'),
                            icon: const Icon(Icons.check_circle,
                                color: Colors.white),
                            label: const Text('Confirm',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _updateStatus('cancelled'),
                            icon: const Icon(Icons.cancel, size: 20),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_booking.status == 'confirmed') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _updateStatus('in_progress'),
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: const Text('Start Charging',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  if (_booking.status == 'in_progress') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _updateStatus('completed'),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Complete Charging',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
