import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/charging_models.dart';
import '../../services/charging_api_service.dart';
import 'charging_stations_screen.dart';
import 'my_booking_screen.dart';
import 'customer_account.dart';
import 'my_vehicles_screen.dart';
import 'services_screen.dart';
import 'car_wash_booking_screen.dart';
import 'ev_check_booking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final User user;

  const CustomerHomeScreen({super.key, required this.user});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  final GlobalKey<MyBookingsScreenState> _bookingsKey =
      GlobalKey<MyBookingsScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeTab(
          user: widget.user,
          onExploreChargers: () => setState(() => _currentIndex = 1)),
      const ChargingStationsScreen(),
      MyBookingsScreen(key: _bookingsKey),
      AccountPage(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Immediately refresh bookings when customer taps My Bookings tab
            if (index == 2) {
              _bookingsKey.currentState?.loadAll();
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.ev_station), label: 'Chargers'),
            BottomNavigationBarItem(
                icon: Icon(Icons.book_online), label: 'My Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final User user;
  final VoidCallback onExploreChargers;

  const _HomeTab({required this.user, required this.onExploreChargers});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final ChargingApiService _apiService = ChargingApiService();
  List<ChargingStation> _nearbyStations = [];
  bool _isLoadingStations = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyStations();
  }

  Future<void> _loadNearbyStations() async {
    setState(() => _isLoadingStations = true);
    final stations = await _apiService.getChargingStations();
    if (mounted) {
      setState(() {
        _nearbyStations = stations.take(3).toList();
        _isLoadingStations = false;
      });
    }
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────

  void _goToServices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServicesScreen()),
    );
  }

  void _goToCarWash() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CarWashBookingScreen()),
    );
  }

  void _goToEvCheck() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EvCheckBookingScreen()),
    );
  }

  void _showComingSoon(String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description,
                  color: Colors.purple.shade400, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is coming soon.\nWe\'re working on it!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got it',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 20),
            const SizedBox(width: 4),
            Text(
              widget.user.fullName.split(' ')[0],
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNearbyStations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search Bar ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  readOnly: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search!')),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Search charging stations...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // ── Banner ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            Icons.electric_car,
                            size: 150,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Welcome to',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hi, ${widget.user.fullName.split(' ')[0]}! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Find & book charging stations',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick Actions ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tileW = (constraints.maxWidth - 36) / 4;
                    return Row(
                      children: [
                        _buildQuickAction(
                          width: tileW,
                          icon: Icons.ev_station,
                          label: 'Find\nCharger',
                          color: Colors.green,
                          onTap: widget.onExploreChargers,
                        ),
                        const SizedBox(width: 12),
                        _buildQuickAction(
                          width: tileW,
                          icon: Icons.local_car_wash,
                          label: 'Car\nWash',
                          color: Colors.blue,
                          onTap: _goToCarWash, // ← real screen
                        ),
                        const SizedBox(width: 12),
                        _buildQuickAction(
                          width: tileW,
                          icon: Icons.electric_car,
                          label: 'EV\nCheck',
                          color: Colors.teal,
                          onTap: _goToEvCheck, // ← real screen
                        ),
                        const SizedBox(width: 12),
                        _buildQuickAction(
                          width: tileW,
                          icon: Icons.directions_car,
                          label: 'My\nVehicles',
                          color: Colors.orange,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyVehiclesScreen(),
                              ),
                            );
                            _loadNearbyStations();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── Nearby Stations ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Charging Stations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onExploreChargers,
                      child: const Text('See All',
                          style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              if (_isLoadingStations)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_nearbyStations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.ev_station,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No stations found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._nearbyStations.map((s) => _buildStationCard(s)),

              const SizedBox(height: 24),

              // ── Our Services ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Our Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: _goToServices,
                      child: const Text('See All',
                          style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Car Wash — real booking
              _buildServiceCard(
                title: 'Car Wash',
                subtitle: 'Full wash, interior & exterior cleaning',
                badge: 'Book Now',
                badgeColor: Colors.blue,
                icon: Icons.local_car_wash,
                color: Colors.blue,
                onTap: _goToCarWash,
              ),

              // EV Check — real booking
              _buildServiceCard(
                title: 'EV Check',
                subtitle: 'Battery health & vehicle diagnostic',
                badge: 'Book Now',
                badgeColor: Colors.teal,
                icon: Icons.electric_car,
                color: Colors.teal,
                onTap: _goToEvCheck,
              ),

              // Blue Book — coming soon
              _buildServiceCard(
                title: 'Blue Book Renewal',
                subtitle: 'Vehicle registration & renewal',
                badge: 'Renew Now',
                badgeColor: Colors.grey,
                icon: Icons.description,
                color: Colors.purple,
                onTap: () => _showComingSoon('Blue Book Renewal'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildQuickAction({
    required double width,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard(ChargingStation station) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: InkWell(
        onTap: widget.onExploreChargers,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.ev_station, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: station.availableChargers > 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${station.availableChargers} available',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: station.availableChargers > 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios,
                    size: 13, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
