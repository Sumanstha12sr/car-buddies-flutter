import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/charging_models.dart';
import '../../../services/charging_api_service.dart';
import 'charger_selection_screen.dart';

class ChargingStationsScreen extends StatefulWidget {
  const ChargingStationsScreen({super.key});

  @override
  State<ChargingStationsScreen> createState() => _ChargingStationsScreenState();
}

class _ChargingStationsScreenState extends State<ChargingStationsScreen> {
  final ChargingApiService _apiService = ChargingApiService();

  List<ChargingStation> _stations = [];
  // Live availability map: station_id -> availability data
  Map<String, Map<String, dynamic>> _liveData = {};

  bool _isLoading = true;
  Timer? _refreshTimer;
  int _secondsUntilRefresh = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadStations();
    _startPolling();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Initial station load ──────────────────────────────────────────────────
  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    final stations = await _apiService.getChargingStations();
    if (mounted) {
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
      // Fetch live data immediately after stations load
      await _fetchLiveAvailability();
    }
  }

  // ── Fetch live availability from backend ──────────────────────────────────
  Future<void> _fetchLiveAvailability() async {
    final liveList = await _apiService.getLiveStationAvailability();
    if (mounted) {
      final Map<String, Map<String, dynamic>> newData = {};
      for (final item in liveList) {
        newData[item['station_id']] = Map<String, dynamic>.from(item);
      }
      setState(() => _liveData = newData);
    }
  }

  // ── Start 30-second polling ───────────────────────────────────────────────
  void _startPolling() {
    // Refresh live data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchLiveAvailability();
      setState(() => _secondsUntilRefresh = 30);
    });

    // Countdown timer — ticks every second for the UI indicator
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_secondsUntilRefresh > 0) _secondsUntilRefresh--;
        });
      }
    });
  }

  // ── Manual refresh ────────────────────────────────────────────────────────
  Future<void> _manualRefresh() async {
    await _loadStations();
    setState(() => _secondsUntilRefresh = 30);
  }

  // ── Get live available count for a station ────────────────────────────────
  int _getAvailableCount(String stationId) {
    return _liveData[stationId]?['available_chargers'] ??
        _stations
            .firstWhere((s) => s.id == stationId, orElse: () => _stations.first)
            .availableChargers;
  }

  int _getTotalCount(String stationId) {
    return _liveData[stationId]?['total_chargers'] ??
        _stations
            .firstWhere((s) => s.id == stationId, orElse: () => _stations.first)
            .totalChargers;
  }

  int _getOccupiedCount(String stationId) {
    return _liveData[stationId]?['occupied_chargers'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging Stations'),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          // Live refresh indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: GestureDetector(
                onTap: _manualRefresh,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_secondsUntilRefresh}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _manualRefresh,
                  child: Column(
                    children: [
                      // Live status banner
                      _buildLiveBanner(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _stations.length,
                          itemBuilder: (context, index) {
                            return _buildStationCard(_stations[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ── Live status banner at top ─────────────────────────────────────────────
  Widget _buildLiveBanner() {
    final totalAvailable = _liveData.values
        .fold<int>(0, (sum, d) => sum + (d['available_chargers'] as int? ?? 0));
    final totalChargers = _liveData.values
        .fold<int>(0, (sum, d) => sum + (d['total_chargers'] as int? ?? 0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.green.shade50,
      child: Row(
        children: [
          // Pulsing green dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Live',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$totalAvailable of $totalChargers chargers available',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            'Refreshes in ${_secondsUntilRefresh}s',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ev_station, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Charging Stations Available',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _manualRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(ChargingStation station) {
    final available = _getAvailableCount(station.id);
    final total = _getTotalCount(station.id);
    final occupied = _getOccupiedCount(station.id);
    final isFull = available == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChargerSelectionScreen(station: station),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Station name + availability badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFull
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.ev_station,
                      color: isFull ? Colors.red : Colors.green,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              station.operatingHours,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Live availability badge
                  _buildAvailabilityBadge(available, total),
                ],
              ),

              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      station.address,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Live charger status row
              _buildLiveStatusRow(available, occupied, total, station.id),

              // Amenities
              if (station.amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: station.amenities.take(3).map((a) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black87),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Full station warning
              if (isFull) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Text(
                        'All chargers currently occupied',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Live availability badge ───────────────────────────────────────────────
  Widget _buildAvailabilityBadge(int available, int total) {
    final isFull = available == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isFull
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFull
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '$available/$total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isFull ? Colors.red : Colors.green,
            ),
          ),
          Text(
            'Free',
            style: TextStyle(
              fontSize: 11,
              color: isFull ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ── Live charger breakdown row ────────────────────────────────────────────
  Widget _buildLiveStatusRow(
      int available, int occupied, int total, String stationId) {
    final maintenance = total - available - occupied;
    return Row(
      children: [
        _buildStatusChip(
          icon: Icons.check_circle,
          label: 'Available',
          count: available,
          color: Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStatusChip(
          icon: Icons.electric_bolt,
          label: 'In Use',
          count: occupied,
          color: Colors.orange,
        ),
        if (maintenance > 0) ...[
          const SizedBox(width: 8),
          _buildStatusChip(
            icon: Icons.build,
            label: 'Maintenance',
            count: maintenance,
            color: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
