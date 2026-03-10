import 'package:flutter/material.dart';
import '../../../services/charging_api_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({Key? key}) : super(key: key);

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ChargingApiService _apiService = ChargingApiService();

  final _vehicleNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _batteryCapacityController = TextEditingController();
  final _chargingPortController = TextEditingController();

  String _vehicleType = 'electric';
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehicleNumberController.dispose();
    _batteryCapacityController.dispose();
    _chargingPortController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final vehicleData = {
      'vehicle_name': _vehicleNameController.text.trim(),
      'vehicle_number': _vehicleNumberController.text.trim().toUpperCase(),
      'vehicle_type': _vehicleType,
      'battery_capacity': double.parse(_batteryCapacityController.text),
      'charging_port_type': _chargingPortController.text.trim(),
      'is_default': _isDefault,
    };

    final result = await _apiService.addVehicle(vehicleData);

    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      String errorMessage = 'Failed to add vehicle';
      if (result['data'] is Map) {
        final errors = result['data'] as Map;
        if (errors.containsKey('vehicle_number')) {
          errorMessage = errors['vehicle_number'][0];
        } else if (errors.containsKey('error')) {
          errorMessage = errors['error'];
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Vehicle Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Name
            TextFormField(
              controller: _vehicleNameController,
              decoration: InputDecoration(
                labelText: 'Vehicle Name *',
                hintText: 'e.g., Tesla Model 3, BYD Atto 3',
                prefixIcon: const Icon(Icons.directions_car),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Vehicle Number
            TextFormField(
              controller: _vehicleNumberController,
              decoration: InputDecoration(
                labelText: 'Vehicle Number *',
                hintText: 'BA-1-PA-1234',
                prefixIcon: const Icon(Icons.pin),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Vehicle Type
            DropdownButtonFormField<String>(
              value: _vehicleType,
              decoration: InputDecoration(
                labelText: 'Vehicle Type *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              ],
              onChanged: (value) {
                setState(() {
                  _vehicleType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Battery Capacity
            TextFormField(
              controller: _batteryCapacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Battery Capacity (kWh) *',
                hintText: 'e.g., 75.5',
                prefixIcon: const Icon(Icons.battery_charging_full),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter battery capacity';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Charging Port Type
            TextFormField(
              controller: _chargingPortController,
              decoration: InputDecoration(
                labelText: 'Charging Port Type *',
                hintText: 'e.g., Type 2, CCS',
                prefixIcon: const Icon(Icons.power),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter charging port type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Set as Default
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Set as Default Vehicle'),
                subtitle: const Text('Use this vehicle for quick booking'),
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
