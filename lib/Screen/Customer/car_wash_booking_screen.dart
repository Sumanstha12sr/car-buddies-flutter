import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service_models.dart';
import '../../models/charging_models.dart';
import '../../services/service_api_service.dart';
import '../../services/charging_api_service.dart';
import 'service_confirmation_screen.dart';

class CarWashBookingScreen extends StatefulWidget {
  const CarWashBookingScreen({super.key});

  @override
  State<CarWashBookingScreen> createState() => _CarWashBookingScreenState();
}

class _CarWashBookingScreenState extends State<CarWashBookingScreen> {
  final ServiceApiService _serviceApi = ServiceApiService();
  final ChargingApiService _chargingApi = ChargingApiService();

  List<Service> _services = [];
  List<Vehicle> _vehicles = []; // ALL vehicles (EV + ICE)
  Service? _selectedService;
  Vehicle? _selectedVehicle;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isCheckingConflict = false;
  List<int> _bookedHours = []; // hours already booked for selected vehicle+date

  final List<TimeOfDay> _timeSlots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _serviceApi.getServicesByCategory('car_wash'),
      _chargingApi.getVehicles(), // ALL vehicles — ICE can do car wash too
    ]);
    setState(() {
      _services = results[0] as List<Service>;
      _vehicles = results[1] as List<Vehicle>; // no filter — all types allowed
      if (_vehicles.isNotEmpty) {
        _selectedVehicle = _vehicles.firstWhere(
          (v) => v.isDefault,
          orElse: () => _vehicles.first,
        );
      }
      _isLoading = false;
    });
    // Load booked slots for default vehicle + default date
    if (_selectedVehicle != null) {
      await _loadBookedSlots();
    }
  }

  // ── Load booked hours for selected vehicle on selected date ────
  Future<void> _loadBookedSlots() async {
    if (_selectedVehicle == null) return;
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final hours = await _serviceApi.getVehicleBookedSlots(
      vehicleId: _selectedVehicle!.id,
      date: dateStr,
    );
    if (mounted) {
      setState(() => _bookedHours = hours);
    }
  }

  // ── Called when vehicle or date changes ───────────────────────
  void _onVehicleChanged(Vehicle? v) {
    setState(() {
      _selectedVehicle = v;
      _bookedHours = [];
    });
    _loadBookedSlots();
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _bookedHours = [];
      // If selected time is now booked, reset to first available
      if (_bookedHours.contains(_selectedTime.hour)) {
        final available = _timeSlots.firstWhere(
          (t) => !_bookedHours.contains(t.hour),
          orElse: () => _timeSlots.first,
        );
        _selectedTime = available;
      }
    });
    _loadBookedSlots();
  }

  // ── Proceed with conflict validation ──────────────────────────
  Future<void> _proceed() async {
    if (_selectedService == null) {
      _showError('Please select a wash type');
      return;
    }
    if (_selectedVehicle == null) {
      _showError('Please select a vehicle');
      return;
    }

    // Check if selected time is already booked
    if (_bookedHours.contains(_selectedTime.hour)) {
      _showConflictError();
      return;
    }

    // Double-check with API before proceeding
    setState(() => _isCheckingConflict = true);
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final bookedHours = await _serviceApi.getVehicleBookedSlots(
      vehicleId: _selectedVehicle!.id,
      date: dateStr,
    );
    setState(() {
      _bookedHours = bookedHours;
      _isCheckingConflict = false;
    });

    if (bookedHours.contains(_selectedTime.hour)) {
      _showConflictError();
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceConfirmationScreen(
          service: _selectedService!,
          vehicle: _selectedVehicle!,
          bookingDate: _selectedDate,
          preferredTime: _selectedTime,
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }

  void _showConflictError() {
    final hour =
        _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Time Conflict'),
          ],
        ),
        content: Text(
          '${_selectedVehicle!.vehicleName} already has a booking '
          'at $hour:00 $period on '
          '${DateFormat('MMM dd, yyyy').format(_selectedDate)}.\n\n'
          'Please select a different time slot.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:00 $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Car Wash Booking',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Step 1: Select Wash Type ─────────────────
                  _sectionTitle('1. Select Wash Type', Icons.local_car_wash),
                  const SizedBox(height: 12),
                  _services.isEmpty
                      ? _emptyState('No wash services available')
                      : Column(
                          children: _services
                              .map((s) => _ServiceOptionCard(
                                    service: s,
                                    isSelected: _selectedService?.id == s.id,
                                    onTap: () =>
                                        setState(() => _selectedService = s),
                                  ))
                              .toList(),
                        ),

                  const SizedBox(height: 24),

                  // ── Step 2: Select Vehicle ───────────────────
                  _sectionTitle('2. Select Vehicle', Icons.directions_car),
                  const SizedBox(height: 12),
                  _vehicles.isEmpty
                      ? _emptyState('No vehicles found. Add a vehicle first.')
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: _vehicles
                                .asMap()
                                .entries
                                .map((e) => Column(
                                      children: [
                                        RadioListTile<Vehicle>(
                                          value: e.value,
                                          groupValue: _selectedVehicle,
                                          onChanged: _onVehicleChanged,
                                          title: Text(
                                            e.value.vehicleName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                          ),
                                          subtitle: Text(
                                            '${e.value.vehicleNumber} • ${e.value.vehicleTypeLabel}',
                                            style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12),
                                          ),
                                          activeColor: const Color(0xFF1565C0),
                                          secondary: e.value.isDefault
                                              ? _defaultBadge()
                                              : null,
                                        ),
                                        if (e.key < _vehicles.length - 1)
                                          Divider(
                                              height: 1,
                                              color: Colors.grey.shade100),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ),

                  const SizedBox(height: 24),

                  // ── Step 3: Select Date ──────────────────────
                  _sectionTitle('3. Select Date', Icons.calendar_today),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: Color(0xFF1565C0)),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) _onDateChanged(picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF1565C0), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, MMM dd, yyyy')
                                .format(_selectedDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const Spacer(),
                          Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Step 4: Select Time ──────────────────────
                  _sectionTitle('4. Select Time', Icons.access_time),
                  const SizedBox(height: 8),

                  // Booked slots legend
                  if (_bookedHours.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Already booked for this vehicle',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _timeSlots.map((t) {
                      final isSelected = _selectedTime.hour == t.hour;
                      final isBooked = _bookedHours.contains(t.hour);
                      return GestureDetector(
                        onTap: isBooked
                            ? () => _showError(
                                '${_formatTime(t)} is already booked for this vehicle')
                            : () => setState(() => _selectedTime = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isBooked
                                ? Colors.red.shade50
                                : isSelected
                                    ? const Color(0xFF1565C0)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isBooked
                                  ? Colors.red.shade300
                                  : isSelected
                                      ? const Color(0xFF1565C0)
                                      : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBooked)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(Icons.block,
                                      size: 12, color: Colors.red.shade400),
                                ),
                              Text(
                                _formatTime(t),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isBooked
                                      ? Colors.red.shade400
                                      : isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Step 5: Notes ────────────────────────────
                  _sectionTitle('5. Notes (Optional)', Icons.note_outlined),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any special instructions...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF1565C0), width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Proceed Button ───────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isCheckingConflict ? null : _proceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isCheckingConflict
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Continue to Confirmation',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _defaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text('Default',
          style: TextStyle(
              fontSize: 10,
              color: Color(0xFF1565C0),
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(
          child: Text(msg,
              style: TextStyle(color: Colors.grey[500], fontSize: 13))),
    );
  }
}

// ── Service Option Card ──────────────────────────────────────────

class _ServiceOptionCard extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceOptionCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1565C0)
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF1565C0) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(service.description,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  const SizedBox(height: 4),
                  Text('⏱ ${service.durationMinutes} mins',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ),
            Text(
              'NPR ${service.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
