import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service_models.dart';
import '../../services/service_api_service.dart';

class StaffServiceBookingsScreen extends StatefulWidget {
  final String? initialFilter;

  const StaffServiceBookingsScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<StaffServiceBookingsScreen> createState() =>
      _StaffServiceBookingsScreenState();
}

class _StaffServiceBookingsScreenState extends State<StaffServiceBookingsScreen>
    with SingleTickerProviderStateMixin {
  final ServiceApiService _serviceApi = ServiceApiService();
  late TabController _tabController;

  List<ServiceBooking> _allBookings = [];
  bool _isLoading = true;

  // For mechanic assignment
  List<dynamic> _mechanics = [];

  @override
  void initState() {
    super.initState();
    // If initialFilter is 'pending' open that tab directly
    final initialIndex = widget.initialFilter == 'pending' ? 1 : 0;
    _tabController =
        TabController(length: 5, vsync: this, initialIndex: initialIndex);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _serviceApi.staffGetAllServiceBookings(),
      _serviceApi.staffGetAvailableMechanics(),
    ]);
    setState(() {
      _allBookings = results[0] as List<ServiceBooking>;
      _mechanics = results[1];
      _isLoading = false;
    });
  }

  // ── Filters ────────────────────────────────────────────────────
  List<ServiceBooking> get _all => _allBookings;
  List<ServiceBooking> get _pending =>
      _allBookings.where((b) => b.status == 'pending').toList();
  List<ServiceBooking> get _confirmed =>
      _allBookings.where((b) => b.status == 'confirmed').toList();
  List<ServiceBooking> get _inProgress =>
      _allBookings.where((b) => b.status == 'in_progress').toList();
  List<ServiceBooking> get _completed =>
      _allBookings.where((b) => b.status == 'completed').toList();

  // ── Status Update ──────────────────────────────────────────────
  Future<void> _updateStatus(ServiceBooking booking, String newStatus) async {
    final result = await _serviceApi.staffUpdateBookingStatus(
      bookingId: booking.id,
      newStatus: newStatus,
    );

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_statusLabel(newStatus)}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['data']['error'] ?? 'Failed to update status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Mechanic Assignment ────────────────────────────────────────
  void _showAssignMechanicDialog(ServiceBooking booking) {
    if (_mechanics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available mechanics at the moment'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
              'Assign Mechanic',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a mechanic for: ${booking.serviceName}',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ..._mechanics.map(
              (m) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(Icons.engineering,
                      color: Colors.green, size: 20),
                ),
                title: Text(
                  m['full_name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  m['specialization'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                trailing: Text(
                  '${m['experience_years'] ?? 0} yrs',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _assignMechanic(booking, m['id'].toString());
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _assignMechanic(
      ServiceBooking booking, String mechanicId) async {
    final result = await _serviceApi.staffAssignMechanic(
      bookingId: booking.id,
      mechanicId: mechanicId,
    );

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mechanic assigned successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['data']['error'] ?? 'Failed to assign mechanic'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Service Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: [
            Tab(text: 'All (${_all.length})'),
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Confirmed (${_confirmed.length})'),
            Tab(text: 'In Progress (${_inProgress.length})'),
            Tab(text: 'Completed (${_completed.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_all),
                  _buildList(_pending),
                  _buildList(_confirmed),
                  _buildList(_inProgress),
                  _buildList(_completed),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<ServiceBooking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No bookings found',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _StaffBookingCard(
        booking: bookings[i],
        onUpdateStatus: _updateStatus,
        onAssignMechanic: _showAssignMechanicDialog,
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Staff Booking Card
// ─────────────────────────────────────────────────────────────────

class _StaffBookingCard extends StatelessWidget {
  final ServiceBooking booking;
  final Future<void> Function(ServiceBooking, String) onUpdateStatus;
  final void Function(ServiceBooking) onAssignMechanic;

  const _StaffBookingCard({
    required this.booking,
    required this.onUpdateStatus,
    required this.onAssignMechanic,
  });

  @override
  Widget build(BuildContext context) {
    final isCarWash = booking.isCarWash;
    final themeColor =
        isCarWash ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
    final lightColor =
        isCarWash ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
        children: [
          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: lightColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCarWash ? Icons.local_car_wash : Icons.electric_car,
                        color: themeColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.serviceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            isCarWash ? 'Car Wash' : 'EV Check',
                            style: TextStyle(fontSize: 12, color: themeColor),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: booking.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booking.statusText,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: booking.statusColor),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // Customer info
                _row(Icons.person_outline, 'Customer', booking.customerName),
                const SizedBox(height: 6),
                _row(Icons.phone_outlined, 'Phone', booking.customerPhone),
                const SizedBox(height: 6),
                _row(Icons.directions_car, 'Vehicle',
                    '${booking.vehicleName} • ${booking.vehicleNumber}'),
                const SizedBox(height: 6),
                _row(Icons.calendar_today, 'Date',
                    DateFormat('EEE, MMM dd yyyy').format(booking.bookingDate)),
                const SizedBox(height: 6),
                _row(Icons.access_time, 'Time',
                    booking.preferredTime.substring(0, 5)),
                const SizedBox(height: 6),
                _row(Icons.payments_outlined, 'Amount',
                    'NPR ${booking.servicePrice.toStringAsFixed(0)}'),

                // Mechanic info (EV Check only)
                if (booking.isEvCheck) ...[
                  const SizedBox(height: 6),
                  _row(
                    Icons.engineering,
                    'Mechanic',
                    booking.mechanicName ?? 'Not assigned yet',
                    valueColor: booking.mechanicName != null
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],

                // Staff notes
                if (booking.staffNotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _row(Icons.note_outlined, 'Notes', booking.staffNotes),
                ],
              ],
            ),
          ),

          // ── Action Buttons ──────────────────────────────────
          if (booking.status != 'completed' && booking.status != 'cancelled')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Assign mechanic (EV Check only)
                      if (booking.isEvCheck && booking.status == 'pending') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onAssignMechanic(booking),
                            icon: const Icon(Icons.engineering, size: 16),
                            label: const Text('Assign'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: const BorderSide(color: Colors.teal),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],

                      // Next status button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _showStatusOptions(context, booking),
                          icon: const Icon(Icons.update, size: 16),
                          label: const Text('Update Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showStatusOptions(BuildContext context, ServiceBooking booking) {
    // Available next statuses based on current status
    final Map<String, List<Map<String, dynamic>>> options = {
      'pending': [
        {'status': 'confirmed', 'label': 'Confirm', 'color': Colors.green},
        {'status': 'cancelled', 'label': 'Cancel', 'color': Colors.red},
      ],
      'confirmed': [
        {
          'status': 'in_progress',
          'label': 'Start Service',
          'color': Colors.blue
        },
        {'status': 'cancelled', 'label': 'Cancel', 'color': Colors.red},
      ],
      'in_progress': [
        {
          'status': 'completed',
          'label': 'Mark Completed',
          'color': Colors.green
        },
      ],
    };

    final availableOptions = options[booking.status] ?? [];

    if (availableOptions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              'Update Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...availableOptions.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onUpdateStatus(booking, opt['status']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: opt['color'],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      opt['label'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
