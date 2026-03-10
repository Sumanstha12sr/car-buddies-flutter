import 'package:flutter/material.dart';
import '../../../models/charging_models.dart';
import '../../../services/charging_api_service.dart';
import 'vehicle_selection_screen.dart';

class ChargerSelectionScreen extends StatefulWidget {
  final ChargingStation station;

  const ChargerSelectionScreen({Key? key, required this.station})
      : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChargers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChargers() async {
    setState(() => _isLoading = true);

    final acChargers =
        await _apiService.getAvailableChargers(widget.station.id, type: 'AC');
    final dcChargers =
        await _apiService.getAvailableChargers(widget.station.id, type: 'DC');

    setState(() {
      _acChargers = acChargers;
      _dcChargers = dcChargers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.name),
        backgroundColor: Colors.green,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: charger.isAvailable
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
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      charger.chargerType == 'AC' ? Icons.flash_on : Icons.bolt,
                      color: accentColor,
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: charger.isAvailable
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      charger.isAvailable ? 'Available' : 'Occupied',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: charger.isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.power,
                'Power Output',
                '${charger.powerOutput} kW',
                accentColor,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.attach_money,
                'Price',
                'NPR ${charger.pricePerKwh}/kWh',
                accentColor,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.cable,
                'Connectors',
                charger.connectorTypesList.join(', '),
                accentColor,
              ),
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
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
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
    );
  }
}
