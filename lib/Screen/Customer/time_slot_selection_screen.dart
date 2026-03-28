import 'package:flutter/material.dart';
import '../../../models/charging_models.dart';
import '../../../services/charging_api_service.dart';
import 'booking_confirmation_screen.dart';

class TimeSlotSelectionScreen extends StatefulWidget {
  final ChargingStation station;
  final Charger charger;
  final Vehicle vehicle;

  const TimeSlotSelectionScreen({
    super.key,
    required this.station,
    required this.charger,
    required this.vehicle,
  });

  @override
  State<TimeSlotSelectionScreen> createState() =>
      _TimeSlotSelectionScreenState();
}

class _TimeSlotSelectionScreenState extends State<TimeSlotSelectionScreen>
    with RouteAware {
  final ChargingApiService _apiService = ChargingApiService();

  List<TimeSlot> _timeSlots = [];
  TimeSlot? _selectedSlot;
  bool _isLoading = false;
  int _hoursNeeded = 1;
  String _chargerPower = '';
  String _vehicleBattery = '';

  DateTime _selectedDate = DateTime.now();

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadTimeSlots();
  }

  @override
  void initState() {
    super.initState();
    _loadTimeSlots();
  }

  Future<void> _loadTimeSlots() async {
    setState(() {
      _isLoading = true;
      _selectedSlot = null;
    });

    final result = await _apiService.getAvailableTimeSlotsWithMeta(
      chargerId: widget.charger.id,
      date: _selectedDate,
      vehicleId: widget.vehicle.id,
    );

    if (mounted) {
      setState(() {
        _timeSlots = result['slots'] as List<TimeSlot>;
        _hoursNeeded = result['hours_needed'] as int;
        _chargerPower = result['charger_power']?.toString() ?? '';
        _vehicleBattery = result['vehicle_battery']?.toString() ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.green,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadTimeSlots();
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _fmt(String t) {
    final p = t.split(':');
    if (p.length < 2) return t;
    return '${p[0]}:${p[1]}';
  }

  String _endTimeLabel(TimeSlot slot) {
    if (_hoursNeeded <= 1) return _fmt(slot.endTime);
    try {
      final startH = int.parse(slot.startTime.split(':')[0]);
      final endH = startH + _hoursNeeded;
      return '${endH.toString().padLeft(2, '0')}:00';
    } catch (_) {
      return _fmt(slot.endTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Select Time Slot',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Date Selector ────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selected Date',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Text(_formatDate(_selectedDate),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),

          // ── Charging Duration Info ───────────────────────────────
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.charger.chargerType == 'DC'
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.charger.chargerType == 'DC'
                      ? Colors.orange.shade200
                      : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.charger.chargerType == 'DC'
                        ? Icons.bolt
                        : Icons.flash_on,
                    color: widget.charger.chargerType == 'DC'
                        ? Colors.orange
                        : Colors.blue,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.charger.chargerType} Charger'
                          '${_chargerPower.isNotEmpty ? ' • $_chargerPower kW' : ''}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Your vehicle needs ~$_hoursNeeded '
                          'hour${_hoursNeeded > 1 ? 's' : ''} '
                          'to charge to 80%'
                          '${_vehicleBattery.isNotEmpty ? ' ($_vehicleBattery kWh)' : ''}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (_hoursNeeded > 1) ...[
                          const SizedBox(height: 3),
                          Text(
                            '⚠ Booking will block '
                            '$_hoursNeeded consecutive slots',
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.charger.chargerType == 'DC'
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Today notice ─────────────────────────────────────────
          if (_isToday(_selectedDate))
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Past slots are hidden. Showing future slots only.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.amber.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // ── Legend ───────────────────────────────────────────────
          if (!_isLoading && _timeSlots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _legendDot(Colors.green, 'Available'),
                  const SizedBox(width: 14),
                  _legendDot(Colors.red.shade300, 'Booked'),
                  const SizedBox(width: 14),
                  _legendDot(Colors.orange.shade400, 'Your booking'),
                  const SizedBox(width: 14),
                  _legendDot(Colors.grey.shade400, 'Not enough time'),
                ],
              ),
            ),

          // ── Slots List ───────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _timeSlots.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _timeSlots.length,
                        itemBuilder: (_, i) =>
                            _buildTimeSlotCard(_timeSlots[i]),
                      ),
          ),

          // ── Warning banner ───────────────────────────────────────
          if (_selectedSlot?.warning != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedSlot!.warning!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // ── Continue Button ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedSlot != null
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingConfirmationScreen(
                              station: widget.station,
                              charger: widget.charger,
                              vehicle: widget.vehicle,
                              timeSlot: _selectedSlot!,
                              bookingDate: _selectedDate,
                            ),
                          ),
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _selectedSlot != null
                      ? 'Confirm ${_fmt(_selectedSlot!.startTime)} '
                          '→ ${_endTimeLabel(_selectedSlot!)} '
                          '(~$_hoursNeeded hr${_hoursNeeded > 1 ? 's' : ''})'
                      : 'Select a Time Slot',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final isSelected = _selectedSlot?.id == slot.id;
    final isBooked = !slot.isAvailable && slot.blockedReason == 'booked';
    final isInsufficient =
        !slot.isAvailable && slot.blockedReason == 'insufficient_time';

    // ── New: user already has a booking at this time ─────────────
    final isUserConflict = slot.userConflict;
    final isUnavailable = !slot.isAvailable || isUserConflict;

    Color borderColor() {
      if (isBooked) return Colors.red.shade300;
      if (isUserConflict) return Colors.orange.shade300;
      if (isInsufficient) return Colors.grey.shade300;
      if (isSelected) return Colors.green;
      return Colors.grey.shade200;
    }

    Color bgColor() {
      if (isBooked) return Colors.red.shade50;
      if (isUserConflict) return Colors.orange.shade50;
      if (isInsufficient) return Colors.grey.shade100;
      if (isSelected) return Colors.green.shade50;
      return Colors.white;
    }

    String statusLabel() {
      if (isBooked) return 'Booked';
      if (isUserConflict) return 'You already have a booking at this time';
      if (isInsufficient) return 'Not enough time before closing';
      if (isSelected) return 'Selected ✓';
      return 'Available';
    }

    Color statusColor() {
      if (isBooked) return Colors.red.shade400;
      if (isUserConflict) return Colors.orange.shade700;
      if (isInsufficient) return Colors.grey.shade500;
      if (isSelected) return Colors.green.shade700;
      return Colors.green;
    }

    return GestureDetector(
      onTap: isUnavailable
          ? () {
              final msg = isBooked
                  ? '${_fmt(slot.startTime)} is already booked'
                  : isUserConflict
                      ? 'You already have a booking at this time'
                      : 'Not enough time for a full charge before closing';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(msg),
                backgroundColor: isBooked
                    ? Colors.red
                    : isUserConflict
                        ? Colors.orange
                        : Colors.grey,
                behavior: SnackBarBehavior.floating,
              ));
            }
          : () => setState(() => _selectedSlot = slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor(), width: isSelected ? 2 : 1),
          boxShadow: isUnavailable
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBooked
                    ? Colors.red.shade100
                    : isUserConflict
                        ? Colors.orange.shade100
                        : isInsufficient
                            ? Colors.grey.shade200
                            : isSelected
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.access_time,
                color: isBooked
                    ? Colors.red.shade400
                    : isUserConflict
                        ? Colors.orange.shade400
                        : isInsufficient
                            ? Colors.grey.shade400
                            : isSelected
                                ? Colors.green
                                : Colors.grey.shade400,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),

            // Time + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_fmt(slot.startTime)}  →  ${_endTimeLabel(slot)}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color:
                          isUnavailable ? Colors.grey.shade500 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusLabel(),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: statusColor()),
                  ),
                  if (!isUnavailable && _hoursNeeded > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Blocks $_hoursNeeded hrs of charger time',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),

            // Right icon
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green, size: 26)
            else if (isBooked)
              Icon(Icons.cancel_outlined, color: Colors.red.shade300, size: 22)
            else if (isUserConflict)
              Icon(Icons.event_busy, color: Colors.orange.shade400, size: 22)
            else if (isInsufficient)
              Icon(Icons.do_not_disturb_outlined,
                  color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _isToday(_selectedDate)
                ? 'No more slots today'
                : 'No slots available for this date',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Try selecting a different date',
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Pick Another Date'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
