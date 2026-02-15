import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

class ManagerReportScreen extends StatefulWidget {
  const ManagerReportScreen({super.key});

  @override
  State<ManagerReportScreen> createState() => _ManagerReportScreenState();
}

class _ManagerReportScreenState extends State<ManagerReportScreen> {
  final supabase = Supabase.instance.client;

  // --- UI PALETTE (Theme Colors) ---
  final Color _gradStart = const Color(0xFF8E24AA); // Purple Vibrant
  final Color _gradEnd = const Color(0xFF4A148C);   // Deep Purple
  final Color _bgColor = const Color(0xFFF5F6FA);   // Soft Gray

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _gradStart,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _gradStart),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _generateReport();
    }
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // 1. Background Header
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gradStart, _gradEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr('title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildMonthSelector(),
                              const SizedBox(height: 20),

                              _buildStatusSummary(),
                              const SizedBox(height: 20),

                              _buildTotalCard(),
                              const SizedBox(height: 25),

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
                              const SizedBox(height: 15),

                              if (_stats.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Column(
                                      children: [
                                        Icon(Icons.bar_chart_outlined, size: 60, color: Colors.grey[300]),
                                        const SizedBox(height: 10),
                                        Text(
                                          tr('no_data'),
                                          style: TextStyle(color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _stats.length,
                                  separatorBuilder: (c, i) => const SizedBox(height: 15),
                                  itemBuilder: (context, index) {
                                    String key = _stats.keys.elementAt(index);
                                    int value = _stats[key]!;
                                    return _buildStatItem(key, value);
                                  },
                                ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: _pickMonth,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gradStart.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_month, color: _gradStart),
                ),
                const SizedBox(width: 15),
                Text(
                  tr('month_label'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            Text(
              DateFormat(
                'MMMM yyyy',
                _currentLanguageCode,
              ).format(_selectedDate),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _gradStart,
              ),
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
            const Color(0xFF43A047), // Green
            Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            tr('pending'),
            _pendingCount,
            const Color(0xFFFF9800), // Orange
            Icons.hourglass_empty,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            tr('rejected'),
            _rejectedCount,
            const Color(0xFFE53935), // Red
            Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradStart, _gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _gradEnd.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
              const SizedBox(height: 8),
              Text(
                "$_totalJobs ${tr('items_unit')}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String category, int count) {
    double percentage = _totalJobs == 0 ? 0 : count / _totalJobs;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                  color: Colors.black87,
                ),
              ),
              Text(
                "$count ${tr('times_unit')}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _gradStart,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              color: _getBarColor(percentage),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${(percentage * 100).toStringAsFixed(1)}%",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(double percentage) {
    if (percentage > 0.5) return const Color(0xFFE53935); // Red
    if (percentage > 0.25) return const Color(0xFFFF9800); // Orange
    return const Color(0xFF43A047); // Green
  }
}