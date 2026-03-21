import 'package:flutter/material.dart';
import '../../services/service_api_service.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  State<CustomerAnalyticsScreen> createState() =>
      _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen> {
  final ServiceApiService _serviceApi = ServiceApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await _serviceApi.getCustomerAnalytics();
      if (mounted) {
        setState(() {
          _data = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('My Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Total Spent ─────────────────────────
                        _buildTotalSpentCard(),
                        const SizedBox(height: 16),

                        // ── Booking Summary ──────────────────────
                        _buildBookingSummaryRow(),
                        const SizedBox(height: 16),

                        // ── Spending by Category ─────────────────
                        _sectionTitle('Spending by Category'),
                        const SizedBox(height: 10),
                        _buildCategoryBreakdown(),
                        const SizedBox(height: 16),

                        // ── Monthly Trend ────────────────────────
                        _sectionTitle('Monthly Spending (Last 6 Months)'),
                        const SizedBox(height: 10),
                        _buildMonthlyTrend(),
                        const SizedBox(height: 16),

                        // ── Bookings by Service ──────────────────
                        _sectionTitle('Bookings by Service'),
                        const SizedBox(height: 10),
                        _buildBookingsByService(),
                        const SizedBox(height: 16),

                        // ── Most Visited Station ─────────────────
                        if (_data!['most_visited_station'] != null) ...[
                          _sectionTitle('Most Visited Station'),
                          const SizedBox(height: 10),
                          _buildMostVisitedStation(),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Total Spent Card ───────────────────────────────────────────

  Widget _buildTotalSpentCard() {
    final total = _data!['total_spent'] ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Amount Spent',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'NPR ${_formatAmount(total)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Across all completed bookings',
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Booking Summary Row ────────────────────────────────────────

  Widget _buildBookingSummaryRow() {
    final total = _data!['total_bookings'] ?? 0;
    final completed = _data!['completed_bookings'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.book_online,
            color: Colors.blue,
            label: 'Total Bookings',
            value: '$total',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.check_circle_outline,
            color: Colors.green,
            label: 'Completed',
            value: '$completed',
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  // ── Spending by Category ───────────────────────────────────────

  Widget _buildCategoryBreakdown() {
    final spent = Map<String, dynamic>.from(_data!['spent_by_category'] ?? {});
    final total = ((_data!['total_spent']) as num?)?.toDouble() ?? 0.0;

    final categories = [
      {
        'key': 'charging',
        'label': 'EV Charging',
        'icon': Icons.ev_station,
        'color': Colors.green,
      },
      {
        'key': 'car_wash',
        'label': 'Car Wash',
        'icon': Icons.local_car_wash,
        'color': Colors.blue,
      },
      {
        'key': 'ev_check',
        'label': 'EV Check',
        'icon': Icons.electric_car,
        'color': Colors.teal,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: categories.map((cat) {
          final double amount = (spent[cat['key']] as num?)?.toDouble() ?? 0.0;
          final double pct = total > 0 ? (amount / total) : 0.0;
          final color = cat['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(cat['icon'] as IconData, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(cat['label'] as String,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      'NPR ${_formatAmount(amount)}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Monthly Trend ──────────────────────────────────────────────

  Widget _buildMonthlyTrend() {
    final trend =
        List<Map<String, dynamic>>.from(_data!['monthly_trend'] ?? []);

    if (trend.isEmpty) {
      return _emptyBox('No spending data yet');
    }

    final maxAmount = trend
        .map((m) => (m['amount'] as num?)?.toDouble() ?? 0.0)
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: trend.map((item) {
          final month = item['month'] as String;
          final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
          final double ratio = maxAmount > 0 ? (amount / maxAmount) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(month,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade100,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                      minHeight: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 72,
                  child: Text(
                    amount > 0 ? 'NPR ${_formatAmount(amount)}' : '—',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: amount > 0
                            ? Colors.green.shade700
                            : Colors.grey[400]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bookings by Service ────────────────────────────────────────

  Widget _buildBookingsByService() {
    final services =
        List<Map<String, dynamic>>.from(_data!['bookings_by_service'] ?? []);

    if (services.isEmpty) {
      return _emptyBox('No completed service bookings yet');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: services.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final name = s['name'] as String;
          final count = s['count'] as int;
          final total = (s['total'] as num?)?.toDouble() ?? 0.0;

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green.shade50,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700)),
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('$count booking${count != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: Text(
                  'NPR ${_formatAmount(total)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.green),
                ),
              ),
              if (i < services.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Most Visited Station ───────────────────────────────────────

  Widget _buildMostVisitedStation() {
    final station = _data!['most_visited_station'] as Map<String, dynamic>;
    final name = station['name'] as String;
    final count = station['count'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(Icons.ev_station, color: Colors.green.shade600, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Visited $count time${count != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.green.shade600, size: 14),
                const SizedBox(width: 4),
                Text('Favourite',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _emptyBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child:
            Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Failed to load analytics',
              style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
