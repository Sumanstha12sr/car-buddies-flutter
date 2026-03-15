import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/charging_api_service.dart';
import '../../services/service_api_service.dart';
import '../Auth/login_screen.dart';
import 'staff_bookings_screen.dart';
import 'staff_service_bookings_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  final ChargingApiService _chargingApi = ChargingApiService();
  final ServiceApiService _serviceApi = ServiceApiService();

  // Charging stats
  int _chargingTotal = 0;
  int _chargingPending = 0;
  int _chargingConfirmed = 0;
  int _chargingToday = 0;

  // Service stats
  int _serviceTotal = 0;
  int _servicePending = 0;
  int _serviceInProgress = 0;
  int _serviceToday = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      // Load both in parallel
      final results = await Future.wait([
        _chargingApi.getAllBookings(),
        _serviceApi.staffGetServiceStatistics(),
      ]);

      final chargingBookings = results[0] as List;
      final serviceStats = results[1] as Map<String, dynamic>? ?? {};

      final today = DateTime.now();

      setState(() {
        // Charging stats
        _chargingTotal = chargingBookings.length;
        _chargingPending =
            chargingBookings.where((b) => b.status == 'pending').length;
        _chargingConfirmed =
            chargingBookings.where((b) => b.status == 'confirmed').length;
        _chargingToday = chargingBookings
            .where((b) =>
                b.bookingDate.year == today.year &&
                b.bookingDate.month == today.month &&
                b.bookingDate.day == today.day)
            .length;

        // Service stats from API
        _serviceTotal = serviceStats['total'] ?? 0;
        _servicePending = serviceStats['pending'] ?? 0;
        _serviceInProgress = serviceStats['in_progress'] ?? 0;
        _serviceToday = serviceStats['today'] ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Staff Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ApiService().logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Card ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        Text('Staff Member',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text('Staff Member',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Charging Stats ───────────────────────────────
              _sectionTitle(
                  'EV Charging Bookings', Icons.ev_station, Colors.green),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _statCard('Total', _chargingTotal.toString(),
                            Icons.book_online, Colors.blue),
                        _statCard('Pending', _chargingPending.toString(),
                            Icons.pending_actions, Colors.orange),
                        _statCard('Confirmed', _chargingConfirmed.toString(),
                            Icons.check_circle, Colors.green),
                        _statCard("Today's", _chargingToday.toString(),
                            Icons.today, Colors.purple),
                      ],
                    ),

              const SizedBox(height: 24),

              // ── Service Stats ────────────────────────────────
              _sectionTitle('Service Bookings', Icons.miscellaneous_services,
                  Colors.teal),
              const SizedBox(height: 12),

              _isLoading
                  ? const SizedBox()
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _statCard('Total', _serviceTotal.toString(),
                            Icons.miscellaneous_services, Colors.teal),
                        _statCard('Pending', _servicePending.toString(),
                            Icons.pending_actions, Colors.orange),
                        _statCard('In Progress', _serviceInProgress.toString(),
                            Icons.autorenew, Colors.blue),
                        _statCard("Today's", _serviceToday.toString(),
                            Icons.today, Colors.purple),
                      ],
                    ),

              const SizedBox(height: 24),

              // ── Quick Actions ────────────────────────────────
              const Text(
                'Quick Actions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),

              // Manage Charging Bookings
              _actionCard(
                icon: Icons.ev_station,
                title: 'Manage Charging Bookings',
                subtitle: '$_chargingPending charging bookings pending',
                color: Colors.green,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StaffBookingsScreen()),
                  );
                  _loadStatistics();
                },
              ),

              const SizedBox(height: 12),

              // Manage Service Bookings
              _actionCard(
                icon: Icons.miscellaneous_services,
                title: 'Manage Service Bookings',
                subtitle: '$_servicePending service bookings pending',
                color: Colors.teal,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StaffServiceBookingsScreen()),
                  );
                  _loadStatistics();
                },
              ),

              const SizedBox(height: 12),

              // Pending Service Bookings shortcut
              _actionCard(
                icon: Icons.pending_actions,
                title: 'Pending Service Bookings',
                subtitle: '$_servicePending bookings waiting for confirmation',
                color: Colors.orange,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StaffServiceBookingsScreen(
                          initialFilter: 'pending'),
                    ),
                  );
                  _loadStatistics();
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              Text(title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
