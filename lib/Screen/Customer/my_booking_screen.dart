import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/charging_models.dart';
import '../../models/service_models.dart';
import '../../services/charging_api_service.dart';
import '../../services/service_api_service.dart';
import 'service_booking_detail_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => MyBookingsScreenState();
}

class MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final ChargingApiService _chargingApi = ChargingApiService();
  final ServiceApiService _serviceApi = ServiceApiService();

  late TabController _tabController;

  List<ChargingBooking> _chargingBookings = [];
  bool _isLoadingCharging = true;

  List<ServiceBooking> _serviceBookings = [];
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Public so customer_home_screen can call it when tab switches
  Future<void> loadAll() async {
    _loadChargingBookings();
    _loadServiceBookings();
  }

  Future<void> _loadChargingBookings() async {
    setState(() => _isLoadingCharging = true);
    final bookings = await _chargingApi.getCustomerBookings();
    if (mounted) {
      setState(() {
        _chargingBookings = bookings;
        _isLoadingCharging = false;
      });
    }
  }

  Future<void> _loadServiceBookings() async {
    setState(() => _isLoadingServices = true);
    final bookings = await _serviceApi.getCustomerServiceBookings();
    if (mounted) {
      setState(() {
        _serviceBookings = bookings;
        _isLoadingServices = false;
      });
    }
  }

  List<ChargingBooking> _filterCharging(String filter) {
    switch (filter) {
      case 'active':
        return _chargingBookings
            .where((b) =>
                b.status == 'pending' ||
                b.status == 'confirmed' ||
                b.status == 'in_progress')
            .toList();
      case 'completed':
        return _chargingBookings.where((b) => b.status == 'completed').toList();
      case 'cancelled':
        return _chargingBookings.where((b) => b.status == 'cancelled').toList();
      default:
        return _chargingBookings;
    }
  }

  Future<void> _cancelChargingBooking(ChargingBooking booking) async {
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

    if (confirm == true) {
      final success = await _chargingApi.cancelBooking(booking.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadChargingBookings();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.ev_station, size: 16),
                  const SizedBox(width: 6),
                  Text('Charging (${_chargingBookings.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.miscellaneous_services, size: 16),
                  const SizedBox(width: 6),
                  Text('Services (${_serviceBookings.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Charging ──────────────────────────────────
          _ChargingTab(
            bookings: _chargingBookings,
            isLoading: _isLoadingCharging,
            onRefresh: _loadChargingBookings,
            filterBookings: _filterCharging,
            onCancel: _cancelChargingBooking,
          ),

          // ── Tab 2: Services ──────────────────────────────────
          _ServicesTab(
            bookings: _serviceBookings,
            isLoading: _isLoadingServices,
            onRefresh: _loadServiceBookings,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Charging Tab
// ─────────────────────────────────────────────────────────────────

class _ChargingTab extends StatefulWidget {
  final List<ChargingBooking> bookings;
  final bool isLoading;
  final VoidCallback onRefresh;
  final List<ChargingBooking> Function(String) filterBookings;
  final Future<void> Function(ChargingBooking) onCancel;

  const _ChargingTab({
    required this.bookings,
    required this.isLoading,
    required this.onRefresh,
    required this.filterBookings,
    required this.onCancel,
  });

  @override
  State<_ChargingTab> createState() => _ChargingTabState();
}

class _ChargingTabState extends State<_ChargingTab>
    with SingleTickerProviderStateMixin {
  late TabController _inner;

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _inner,
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: [
              Tab(text: 'Active (${widget.filterBookings('active').length})'),
              Tab(text: 'Done (${widget.filterBookings('completed').length})'),
              Tab(
                  text:
                      'Cancelled (${widget.filterBookings('cancelled').length})'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: TabBarView(
              controller: _inner,
              children: [
                _buildList(widget.filterBookings('active')),
                _buildList(widget.filterBookings('completed')),
                _buildList(widget.filterBookings('cancelled')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<ChargingBooking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ev_station, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No bookings found',
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _ChargingCard(
        booking: bookings[i],
        onCancel: () => widget.onCancel(bookings[i]),
      ),
    );
  }
}

class _ChargingCard extends StatelessWidget {
  final ChargingBooking booking;
  final VoidCallback onCancel;

  const _ChargingCard({required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: booking.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.ev_station,
                      color: booking.getStatusColor(), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.stationName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      Text('${booking.chargerName} (${booking.chargerType})',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: booking.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.getStatusText(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: booking.getStatusColor()),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _row(Icons.directions_car, booking.vehicleName,
                booking.vehicleNumber),
            const SizedBox(height: 6),
            _row(
                Icons.calendar_today,
                DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                '${booking.startTime} - ${booking.endTime}'),
            if (booking.estimatedCost != null) ...[
              const SizedBox(height: 6),
              _row(Icons.payments_outlined, 'Estimated Cost',
                  'NPR ${booking.estimatedCost!.toStringAsFixed(2)}'),
            ],
            if (booking.status == 'pending' ||
                booking.status == 'confirmed') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Cancel Booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Services Tab
// ─────────────────────────────────────────────────────────────────

class _ServicesTab extends StatefulWidget {
  final List<ServiceBooking> bookings;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _ServicesTab({
    required this.bookings,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab>
    with SingleTickerProviderStateMixin {
  late TabController _inner;

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  List<ServiceBooking> get _active => widget.bookings
      .where((b) =>
          b.status == 'pending' ||
          b.status == 'confirmed' ||
          b.status == 'in_progress')
      .toList();

  List<ServiceBooking> get _completed =>
      widget.bookings.where((b) => b.status == 'completed').toList();

  List<ServiceBooking> get _cancelled =>
      widget.bookings.where((b) => b.status == 'cancelled').toList();

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _inner,
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            tabs: [
              Tab(text: 'Active (${_active.length})'),
              Tab(text: 'Done (${_completed.length})'),
              Tab(text: 'Cancelled (${_cancelled.length})'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: TabBarView(
              controller: _inner,
              children: [
                _buildList(_active),
                _buildList(_completed),
                _buildList(_cancelled),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<ServiceBooking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.miscellaneous_services,
                size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No bookings found',
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            const SizedBox(height: 6),
            Text('Pull down to refresh',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, i) => _ServiceCard(
        booking: bookings[i],
        onRefresh: widget.onRefresh,
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceBooking booking;
  final VoidCallback onRefresh;

  const _ServiceCard({required this.booking, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isCarWash = booking.isCarWash;
    final themeColor =
        isCarWash ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
    final lightColor =
        isCarWash ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceBookingDetailScreen(booking: booking),
          ),
        );
        onRefresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(booking.vehicleName,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(
                  DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 14),
                Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(
                  booking.preferredTime.length >= 5
                      ? booking.preferredTime.substring(0, 5)
                      : booking.preferredTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  'NPR ${(booking.estimatedCost != null ? booking.estimatedCost! : booking.servicePrice).toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: themeColor),
                ),
              ],
            ),
            if (booking.hasReport || booking.canFeedback) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (booking.hasReport)
                    _tag(Icons.description_outlined, 'Report Ready',
                        Colors.blue),
                  if (booking.canFeedback) ...[
                    if (booking.hasReport) const SizedBox(width: 8),
                    _tag(Icons.star_outline, 'Give Feedback', Colors.orange),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
