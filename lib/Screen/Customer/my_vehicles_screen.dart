import 'package:flutter/material.dart';
import '../../models/charging_models.dart';
import '../../services/charging_api_service.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final ChargingApiService _apiService = ChargingApiService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    final vehicles = await _apiService.getVehicles();
    if (mounted) {
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content:
            Text('Are you sure you want to delete ${vehicle.vehicleName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.deleteVehicle(vehicle.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadVehicles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete vehicle'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _setDefaultVehicle(Vehicle vehicle) async {
    final success = await _apiService.setDefaultVehicle(vehicle.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${vehicle.vehicleName} set as default'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadVehicles();
    }
  }

  void _showAddVehicleSheet() {
    final formKey = GlobalKey<FormState>();
    final vehicleNameController = TextEditingController();
    final vehicleNumberController = TextEditingController();
    final batteryCapacityController = TextEditingController();
    final chargingPortController = TextEditingController();
    String vehicleType = 'electric';
    bool isDefault = false;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bool showEvFields =
              vehicleType == 'electric' || vehicleType == 'hybrid';

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Vehicle',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Vehicle Type (first so fields update) ────
                    DropdownButtonFormField<String>(
                      value: vehicleType,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Type *',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'electric',
                          child: Text('Electric Vehicle (EV)'),
                        ),
                        DropdownMenuItem(
                          value: 'hybrid',
                          child: Text('Hybrid Vehicle'),
                        ),
                        DropdownMenuItem(
                          value: 'ice',
                          child: Text('Petrol / Diesel (ICE)'),
                        ),
                      ],
                      onChanged: (value) {
                        setSheetState(() => vehicleType = value!);
                      },
                    ),

                    // ICE info banner
                    if (!showEvFields) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ICE vehicles can only book Car Wash services.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── Vehicle Name ─────────────────────────────
                    TextFormField(
                      controller: vehicleNameController,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Name *',
                        hintText: 'e.g., BYD Atto 3 / Toyota Corolla',
                        prefixIcon: const Icon(Icons.directions_car),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please enter vehicle name'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // ── Vehicle Number ───────────────────────────
                    TextFormField(
                      controller: vehicleNumberController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Number *',
                        hintText: 'e.g., BA-1-PA-1234',
                        prefixIcon: const Icon(Icons.pin),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please enter vehicle number'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // ── EV-only fields ───────────────────────────
                    if (showEvFields) ...[
                      TextFormField(
                        controller: batteryCapacityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Battery Capacity (kWh) *',
                          hintText: 'e.g., 60.48',
                          prefixIcon: const Icon(Icons.battery_charging_full),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter battery capacity';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: chargingPortController,
                        decoration: InputDecoration(
                          labelText: 'Charging Port Type *',
                          hintText: 'e.g., CCS2, Type 2',
                          prefixIcon: const Icon(Icons.power),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Please enter charging port type'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Set Default ──────────────────────────────
                    SwitchListTile(
                      title: const Text('Set as Default Vehicle'),
                      subtitle:
                          const Text('Use this vehicle for quick booking'),
                      value: isDefault,
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setSheetState(() => isDefault = v),
                    ),
                    const SizedBox(height: 16),

                    // ── Save Button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                setSheetState(() => isLoading = true);

                                final vehicleData = <String, dynamic>{
                                  'vehicle_name':
                                      vehicleNameController.text.trim(),
                                  'vehicle_number': vehicleNumberController.text
                                      .trim()
                                      .toUpperCase(),
                                  'vehicle_type': vehicleType,
                                  'is_default': isDefault,
                                };

                                // Only add EV fields if EV/Hybrid
                                if (showEvFields) {
                                  vehicleData['battery_capacity'] =
                                      double.parse(
                                          batteryCapacityController.text);
                                  vehicleData['charging_port_type'] =
                                      chargingPortController.text.trim();
                                }

                                final result =
                                    await _apiService.addVehicle(vehicleData);
                                setSheetState(() => isLoading = false);

                                if (result['success']) {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Vehicle added successfully!'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  _loadVehicles();
                                } else {
                                  if (!context.mounted) return;
                                  String errorMessage = 'Failed to add vehicle';
                                  if (result['data'] is Map) {
                                    final errors = result['data'] as Map;
                                    if (errors.containsKey('vehicle_number')) {
                                      errorMessage =
                                          errors['vehicle_number'][0];
                                    } else if (errors.containsKey('error')) {
                                      errorMessage = errors['error'];
                                    }
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add Vehicle',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('My Vehicles',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (_, i) => _buildVehicleCard(_vehicles[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVehicleSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No Vehicles Added',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tap the button below to add your vehicle',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddVehicleSheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Your Vehicle',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final isEv = vehicle.isEv;
    final typeColor = isEv ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: vehicle.isDefault
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ─────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEv ? Icons.electric_car : Icons.directions_car,
                    color: typeColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.vehicleName,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (vehicle.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.vehicleNumber,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // ── Detail Chips ────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.category, vehicle.vehicleTypeLabel, typeColor),
                if (isEv && vehicle.batteryCapacity != null)
                  _chip(Icons.battery_charging_full,
                      '${vehicle.batteryCapacity} kWh', Colors.blue),
                if (isEv &&
                    vehicle.chargingPortType != null &&
                    vehicle.chargingPortType!.isNotEmpty)
                  _chip(Icons.power, vehicle.chargingPortType!, Colors.purple),
                if (!isEv)
                  _chip(Icons.local_car_wash, 'Car Wash Only', Colors.orange),
              ],
            ),

            const SizedBox(height: 16),

            // ── Action Buttons ──────────────────────────────────
            Row(
              children: [
                if (!vehicle.isDefault)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _setDefaultVehicle(vehicle),
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Set Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (!vehicle.isDefault) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteVehicle(vehicle),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
