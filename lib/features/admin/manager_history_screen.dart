import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManagerHistoryScreen extends StatefulWidget {
  const ManagerHistoryScreen({super.key});

  @override
  State<ManagerHistoryScreen> createState() => _ManagerHistoryScreenState();
}

class _ManagerHistoryScreenState extends State<ManagerHistoryScreen> {
  final supabase = Supabase.instance.client;

  // --- UI PALETTE (Theme Colors - same as home screen) ---
  final Color _gradStart = const Color(0xFF8E24AA); // Purple Vibrant
  final Color _gradEnd = const Color(0xFF4A148C);   // Deep Purple
  final Color _bgColor = const Color(0xFFF5F6FA);   // Soft Gray

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allTickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  bool _isLoading = true;
  String _currentLanguageCode = 'th';

  // --- 1. คำแปล UI ---
  final Map<String, Map<String, String>> _translations = {
    'th': {
      'title': 'ประวัติการทำงาน',
      'search_hint': 'ค้นหาเลขห้อง, ชื่อผู้แจ้ง...',
      'no_data': 'ไม่พบประวัติงาน',
      'status_completed': 'เสร็จสิ้น',
      'status_rejected': 'ไม่อนุมัติ',
      'category': 'หมวดหมู่',
      'desc': 'รายละเอียด',
      'reporter': 'ผู้แจ้ง',
      'phone': 'เบอร์โทร',
      'dorm_room': 'หอพัก/ห้อง',
      'date_created': 'วันที่แจ้ง',
      'date_processed': 'ดำเนินการเมื่อ',
      'by': 'โดย',
      'btn_close': 'ปิด',
    },
    'en': {
      'title': 'Job History',
      'search_hint': 'Search Room, Name...',
      'no_data': 'No History Found',
      'status_completed': 'Completed',
      'status_rejected': 'Rejected',
      'category': 'Category',
      'desc': 'Description',
      'reporter': 'Reporter',
      'phone': 'Tel',
      'dorm_room': 'Dorm/Room',
      'date_created': 'Created Date',
      'date_processed': 'Processed Date',
      'by': 'By',
      'btn_close': 'Close',
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

  String _getCategoryDisplay(String? dbValue) {
    if (dbValue == null) return '-';
    if (_currentLanguageCode == 'th') return dbValue;
    return _categoryEnMap[dbValue] ?? dbValue;
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _loadHistoryData();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentLanguageCode = prefs.getString('language_code') ?? 'th';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('tickets')
          .select()
          .or('status.eq.completed,status.eq.rejected')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allTickets = List<Map<String, dynamic>>.from(data);
          _filteredTickets = _allTickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _runFilter(String keyword) {
    List<Map<String, dynamic>> results = [];
    if (keyword.isEmpty) {
      results = _allTickets;
    } else {
      results = _allTickets.where((ticket) {
        final name = ticket['contact_name']?.toString().toLowerCase() ?? '';
        final room = ticket['room_number']?.toString().toLowerCase() ?? '';
        final searchLower = keyword.toLowerCase();
        return name.contains(searchLower) || room.contains(searchLower);
      }).toList();
    }
    setState(() {
      _filteredTickets = results;
    });
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // 1. Background Header (สีม่วง Gradient)
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

                // 3. Search Bar (Floating)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _runFilter,
                    decoration: InputDecoration(
                      hintText: tr('search_hint'),
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: _gradStart),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _runFilter('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),

                // 4. List Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredTickets.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                              itemCount: _filteredTickets.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildHistoryCard(_filteredTickets[index]);
                              },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            tr('no_data'),
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ticket) {
    bool isCompleted = ticket['status'] == 'completed';
    Color statusColor = isCompleted ? const Color(0xFF43A047) : const Color(0xFFE53935); // Green vs Red
    String statusText = isCompleted ? tr('status_completed') : tr('status_rejected');

    return GestureDetector(
      onTap: () => _showDetailSheet(ticket, isCompleted, statusColor),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // แถบสีสถานะด้านซ้าย
                Container(width: 5, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(ticket['created_at']),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getCategoryDisplay(ticket['category']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${ticket['dorm_building']} / ${ticket['room_number']}",
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // ลูกศรขวา
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[300]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Bottom Sheet Details ---
  void _showDetailSheet(Map<String, dynamic> ticket, bool isCompleted, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(isCompleted ? Icons.check : Icons.close, color: color),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? tr('status_completed') : tr('status_rejected'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      _getCategoryDisplay(ticket['category']),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ticket['image_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          ticket['image_url'],
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),
                    
                    _buildInfoRow(Icons.description, tr('desc'), ticket['description']),
                    _buildInfoRow(Icons.person, tr('reporter'), ticket['contact_name']),
                    _buildInfoRow(Icons.phone, tr('phone'), ticket['contact_phone']),
                    _buildInfoRow(Icons.home_work, tr('dorm_room'), "${ticket['dorm_building']} / ${ticket['room_number']}"),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildTimeRow(tr('date_created'), _formatDate(ticket['created_at'])),
                          if (ticket['approved_at'] != null) ...[
                            const SizedBox(height: 8),
                            _buildTimeRow(tr('date_processed'), _formatDate(ticket['approved_at'])),
                          ],
                          if (ticket['approver_name'] != null) ...[
                            const SizedBox(height: 8),
                            _buildTimeRow(tr('by'), ticket['approver_name']),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Close Button
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gradStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(tr('btn_close')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _gradStart),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  value ?? '-',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateStr).toLocal());
    } catch (e) {
      return dateStr;
    }
  }
}