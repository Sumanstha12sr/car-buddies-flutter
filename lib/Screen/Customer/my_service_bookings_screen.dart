import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service_models.dart';
import '../../services/service_api_service.dart';
import 'service_booking_detail_screen.dart';

class MyServiceBookingsScreen extends StatefulWidget {
  const MyServiceBookingsScreen({super.key});

  @override
  State<MyServiceBookingsScreen> createState() =>
      _MyServiceBookingsScreenState();
}

class _MyServiceBookingsScreenState extends State<MyServiceBookingsScreen>
    with SingleTickerProviderStateMixin {
  final ServiceApiService _serviceApi = ServiceApiService();
  late TabController _tabController;

  List<ServiceBooking> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final bookings = await _serviceApi.getCustomerServiceBookings();
    setState(() {
      _allBookings = bookings;
      _isLoading = false;
    });
  }

  List<ServiceBooking> get _allList => _allBookings;
  List<ServiceBooking> get _carWashList =>
      _allBookings.where((b) => b.isCarWash).toList();
  List<ServiceBooking> get _evCheckList =>
      _allBookings.where((b) => b.isEvCheck).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'My Service Bookings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
            Tab(text: 'All (${_allList.length})'),
            Tab(text: 'Car Wash (${_carWashList.length})'),
            Tab(text: 'EV Check (${_evCheckList.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BookingList(bookings: _allList, onRefresh: _loadBookings),
                  _BookingList(
                      bookings: _carWashList, onRefresh: _loadBookings),
                  _BookingList(
                      bookings: _evCheckList, onRefresh: _loadBookings),
                ],
              ),
            ),
    );
  }
}

// ── Booking List ─────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<ServiceBooking> bookings;
  final VoidCallback onRefresh;

  const _BookingList({
    required this.bookings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No bookings found',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(
          booking: bookings[index],
          onRefresh: onRefresh,
        );
      },
    );
  }
}

// ── Booking Card ─────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final ServiceBooking booking;
  final VoidCallback onRefresh;

  const _BookingCard({
    required this.booking,
    required this.onRefresh,
  });

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
                // Service icon
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
                      Text(
                        booking.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.vehicleName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status chip
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
                      color: booking.statusColor,
                    ),
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
                  booking.preferredTime.substring(0, 5),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  'NPR ${booking.estimatedCost?.toStringAsFixed(0) ?? booking.servicePrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),

            // Extra indicators
            if (booking.hasReport || booking.canFeedback) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (booking.hasReport)
                    _tag(
                      Icons.description_outlined,
                      'Report Ready',
                      Colors.blue,
                    ),
                  if (booking.canFeedback) ...[
                    if (booking.hasReport) const SizedBox(width: 8),
                    _tag(
                      Icons.star_outline,
                      'Give Feedback',
                      Colors.orange,
                    ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
