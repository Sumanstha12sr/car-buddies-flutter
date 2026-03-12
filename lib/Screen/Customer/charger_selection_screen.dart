import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/charging_models.dart';
import '../../../services/charging_api_service.dart';
import 'vehicle_selection_screen.dart';

class ChargerSelectionScreen extends StatefulWidget {
  final ChargingStation station;

  const ChargerSelectionScreen({super.key, required this.station});

  @override
  State<ChargerSelectionScreen> createState() => _ChargerSelectionScreenState();
}

class _ChargerSelectionScreenState extends State<ChargerSelectionScreen>
    with SingleTickerProviderStateMixin {
  final ChargingApiService _apiService = ChargingApiService();
  late TabController _tabController;

  List<Charger> _acChargers = [];
  List<Charger> _dcChargers = [];
  bool _isLoading = true;

  Timer? _refreshTimer;
  int _secondsUntilRefresh = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChargers();
    _startPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChargers() async {
    setState(() => _isLoading = true);
    final acChargers =
        await _apiService.getAvailableChargers(widget.station.id, type: 'AC');
    final dcChargers =
        await _apiService.getAvailableChargers(widget.station.id, type: 'DC');

    // Also fetch ALL chargers (including occupied) so we can show
    // occupied ones in the list too
    final allAC =
        await _apiService.getAllChargers(widget.station.id, type: 'AC');
    final allDC =
        await _apiService.getAllChargers(widget.station.id, type: 'DC');

    if (mounted) {
      setState(() {
        _acChargers = allAC.isNotEmpty ? allAC : acChargers;
        _dcChargers = allDC.isNotEmpty ? allDC : dcChargers;
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadChargers();
      setState(() => _secondsUntilRefresh = 30);
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_secondsUntilRefresh > 0) _secondsUntilRefresh--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.name),
        backgroundColor: Colors.green,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: GestureDetector(
                onTap: _loadChargers,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on),
                  const SizedBox(width: 8),
                  Text('AC (${_acChargers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt),
                  const SizedBox(width: 8),
                  Text('DC (${_dcChargers.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChargerList(_acChargers, Colors.blue),
                _buildChargerList(_dcChargers, Colors.orange),
              ],
            ),
    );
  }

  Widget _buildChargerList(List<Charger> chargers, Color accentColor) {
    if (chargers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ev_station_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Chargers Available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chargers.length,
      itemBuilder: (context, index) {
        return _buildChargerCard(chargers[index], accentColor);
      },
    );
  }

  Widget _buildChargerCard(Charger charger, Color accentColor) {
    final isAvailable = charger.isAvailable && charger.status == 'available';
    final isOccupied = charger.status == 'occupied';
    final isMaintenance = charger.status == 'maintenance';

    // Pick color based on live status
    Color statusColor = Colors.green;
    String statusText = 'Available';
    IconData statusIcon = Icons.check_circle;

    if (isOccupied) {
      statusColor = Colors.orange;
      statusText = 'In Use';
      statusIcon = Icons.electric_bolt;
    } else if (isMaintenance) {
      statusColor = Colors.grey;
      statusText = 'Maintenance';
      statusIcon = Icons.build;
    } else if (!isAvailable) {
      statusColor = Colors.red;
      statusText = 'Unavailable';
      statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isAvailable ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isAvailable
            ? BorderSide(color: accentColor.withOpacity(0.3), width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isAvailable
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleSelectionScreen(
                      station: widget.station,
                      charger: charger,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? accentColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      charger.chargerType == 'AC' ? Icons.flash_on : Icons.bolt,
                      color: isAvailable ? accentColor : Colors.grey,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          charger.chargerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${charger.chargerType} Charger',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Charger details
              _buildInfoRow(
                Icons.power,
                'Power Output',
                '${charger.powerOutput} kW',
                isAvailable ? accentColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.attach_money,
                'Price',
                'NPR ${charger.pricePerKwh}/kWh',
                isAvailable ? accentColor : Colors.grey,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.cable,
                'Connectors',
                charger.connectorTypesList.join(', '),
                isAvailable ? accentColor : Colors.grey,
              ),

              // Unavailable message
              if (!isAvailable) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    isOccupied
                        ? '⚡ This charger is currently in use'
                        : isMaintenance
                            ? '🔧 This charger is under maintenance'
                            : '❌ This charger is not available',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
