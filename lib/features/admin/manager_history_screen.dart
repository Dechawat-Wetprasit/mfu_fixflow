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

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allTickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  bool _isLoading = true;
  String _currentLanguageCode = 'th';

  // --- 1. คำแปล UI (เหมือนเดิม) ---
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

  // --- 2. 🔥 เพิ่ม: คำแปลสำหรับข้อมูลใน Database (Category Mapping) ---
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

  // 🔥 ฟังก์ชันแปลงข้อมูล Category
  String _getCategoryDisplay(String? dbValue) {
    if (dbValue == null) return '-';
    // ถ้าเป็นภาษาไทย ให้แสดงค่าเดิมจาก DB เลย
    if (_currentLanguageCode == 'th') return dbValue;
    // ถ้าเป็นภาษาอังกฤษ ให้ลองหาคำแปลใน Map ถ้าไม่มีให้ใช้ค่าเดิม
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
    setState(() {
      _currentLanguageCode = prefs.getString('language_code') ?? 'th';
    });
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

  void _showHistoryDetail(Map<String, dynamic> ticket) {
    bool isCompleted = ticket['status'] == 'completed';
    Color statusColor = isCompleted ? Colors.green : Colors.red;
    String statusText = isCompleted
        ? tr('status_completed')
        : tr('status_rejected');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.cancel,
              color: statusColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ticket['image_url'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(ticket['image_url']),
                  ),
                ),

              // 🔥 ใช้ _getCategoryDisplay แทนค่าตรงๆ
              _buildDetailRow(
                tr('category'),
                _getCategoryDisplay(ticket['category']),
              ),
              _buildDetailRow(tr('desc'), ticket['description']),
              const Divider(height: 20),

              _buildDetailRow(tr('reporter'), ticket['contact_name']),
              _buildDetailRow(tr('phone'), ticket['contact_phone']),
              _buildDetailRow(
                tr('dorm_room'),
                "${ticket['dorm_building']} / ${ticket['room_number']}",
              ),

              const Divider(height: 20),
              _buildDetailRow(
                tr('date_created'),
                _formatDate(ticket['created_at']),
              ),
              if (ticket['approved_at'] != null)
                _buildDetailRow(
                  tr('date_processed'),
                  _formatDate(ticket['approved_at']),
                ),

              if (ticket['approver_name'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "${tr('by')}: ${ticket['approver_name']}",
                    style: TextStyle(
                      color: Colors.purple[300],
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('btn_close'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.parse(dateStr).toLocal());
    } catch (e) {
      return dateStr;
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
      body: Column(
        children: [
          // --- Search Bar Area ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                hintText: tr('search_hint'),
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // --- List Area ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr('no_data'),
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredTickets.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      final ticket = _filteredTickets[index];
                      return _buildHistoryCard(ticket);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ticket) {
    bool isCompleted = ticket['status'] == 'completed';
    Color statusColor = isCompleted ? Colors.green : Colors.red;
    String statusText = isCompleted
        ? tr('status_completed')
        : tr('status_rejected');
    IconData statusIcon = isCompleted ? Icons.check_circle : Icons.cancel;

    return GestureDetector(
      onTap: () => _showHistoryDetail(ticket),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat(
                    'dd MMM, HH:mm',
                  ).format(DateTime.parse(ticket['created_at']).toLocal()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 🔥 ใช้ _getCategoryDisplay แทนค่าตรงๆ
            Text(
              _getCategoryDisplay(ticket['category']),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              ticket['description'] ?? '-',
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  "${ticket['contact_name']} (${ticket['room_number']})",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
