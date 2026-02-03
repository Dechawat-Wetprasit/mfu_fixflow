import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ 1. เพิ่ม Import นี้

class ManagerReportScreen extends StatefulWidget {
  const ManagerReportScreen({super.key});

  @override
  State<ManagerReportScreen> createState() => _ManagerReportScreenState();
}

class _ManagerReportScreenState extends State<ManagerReportScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _currentLanguageCode = 'th';

  // Stats Data
  Map<String, int> _stats = {};
  int _totalJobs = 0;
  int _completedCount = 0;
  int _pendingCount = 0;
  int _rejectedCount = 0;

  // Translations
  final Map<String, Map<String, String>> _translations = {
    'th': {
      'title': 'รายงานสรุปรายเดือน',
      'month_label': 'ประจำเดือน:',
      'total_title': 'ยอดแจ้งซ่อมทั้งหมด',
      'items_unit': 'รายการ',
      'times_unit': 'ครั้ง',
      'no_data': 'ไม่มีข้อมูลในเดือนนี้',
      'pick_help': 'เลือกเดือนที่ต้องการดูรายงาน',
      'status_summary': 'สรุปสถานะงาน',
      'completed': 'เสร็จสิ้น',
      'pending': 'รอดำเนินการ',
      'rejected': 'ไม่อนุมัติ',
      'category_header': 'แยกตามหมวดหมู่',
    },
    'en': {
      'title': 'Monthly Report',
      'month_label': 'Month:',
      'total_title': 'Total Requests',
      'items_unit': 'Items',
      'times_unit': 'Times',
      'no_data': 'No data for this month',
      'pick_help': 'Select month to view report',
      'status_summary': 'Status Summary',
      'completed': 'Completed',
      'pending': 'Pending/Active',
      'rejected': 'Rejected',
      'category_header': 'By Category',
    },
  };

  final Map<String, String> _categoryEnMap = {
    'แจ้งซ่อมทั่วไป': 'General Repair',
    'ไฟฟ้า/ประปา': 'Electric/Water',
    'เครื่องปรับอากาศ': 'Air Conditioner',
    'เฟอร์นิเจอร์/อุปกรณ์': 'Furniture/Equipment',
    'ความสะอาด': 'Cleaning',
    'อินเทอร์เน็ต': 'Internet',
    'อื่นๆ': 'Others',
  };

  String tr(String key) => _translations[_currentLanguageCode]?[key] ?? key;

  String _getCategoryDisplay(String key) {
    if (_currentLanguageCode == 'th') return key;
    return _categoryEnMap[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    // ✅ 2. เพิ่ม initializeDateFormatting ตรงนี้
    initializeDateFormatting().then((_) {
      if (mounted) {
        _loadLanguage();
        _generateReport();
      }
    });
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguageCode = prefs.getString('language_code') ?? 'th';
    });
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);

    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
      23,
      59,
      59,
    );

    try {
      final data = await supabase
          .from('tickets')
          .select('category, status')
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      Map<String, int> counts = {};
      int completed = 0;
      int pending = 0;
      int rejected = 0;

      for (var item in data) {
        String category = item['category'] ?? 'อื่นๆ';
        counts[category] = (counts[category] ?? 0) + 1;

        String status = item['status'] ?? 'pending';
        if (status == 'completed') {
          completed++;
        } else if (status == 'rejected') {
          rejected++;
        } else {
          pending++;
        }
      }

      var sortedEntries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _stats = Map.fromEntries(sortedEntries);
          _totalJobs = data.length;
          _completedCount = completed;
          _pendingCount = pending;
          _rejectedCount = rejected;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: tr('pick_help'),
      locale: Locale(_currentLanguageCode),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          tr('title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 20),

            _buildStatusSummary(),
            const SizedBox(height: 20),

            _buildTotalCard(),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr('category_header'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _stats.isEmpty
                  ? Center(
                      child: Text(
                        tr('no_data'),
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _stats.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        String key = _stats.keys.elementAt(index);
                        int value = _stats[key]!;
                        return _buildStatItem(key, value);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: _pickMonth,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('month_label'),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Row(
              children: [
                Text(
                  DateFormat(
                    'MMMM yyyy',
                    _currentLanguageCode,
                  ).format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.calendar_month, color: Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            tr('completed'),
            _completedCount,
            Colors.green,
            Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatusCard(
            tr('pending'),
            _pendingCount,
            Colors.orange,
            Icons.hourglass_empty,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatusCard(
            tr('rejected'),
            _rejectedCount,
            Colors.red,
            Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 5),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('total_title'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                "$_totalJobs ${tr('items_unit')}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String category, int count) {
    double percentage = _totalJobs == 0 ? 0 : count / _totalJobs;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getCategoryDisplay(category),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "$count ${tr('times_unit')}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              color: _getBarColor(percentage),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "${(percentage * 100).toStringAsFixed(1)}%",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(double percentage) {
    if (percentage > 0.5) return Colors.red;
    if (percentage > 0.25) return Colors.orange;
    return Colors.green;
  }
}
