import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TechnicianHistoryScreen extends StatefulWidget {
  const TechnicianHistoryScreen({super.key});

  @override
  State<TechnicianHistoryScreen> createState() =>
      _TechnicianHistoryScreenState();
}

class _TechnicianHistoryScreenState extends State<TechnicianHistoryScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allTickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  bool _isLoading = true;
  String _currentLanguageCode = 'th';

  final Map<String, Map<String, String>> _translations = {
    'th': {
      'title': 'ประวัติงานของฉัน',
      'search_hint': 'ค้นหาเลขห้อง, ชื่อผู้แจ้ง...',
      'no_data': 'ไม่พบประวัติงาน',
      'status_completed': 'เสร็จสิ้น',
      'category': 'หมวดหมู่',
      'desc': 'รายละเอียด',
      'loc': 'สถานที่',
      'date_finished': 'เสร็จเมื่อ',
      'building': 'อาคาร',
      'room': 'ห้อง',
      'btn_close': 'ปิด',
    },
    'en': {
      'title': 'My Job History',
      'search_hint': 'Search Room, Name...',
      'no_data': 'No History Found',
      'status_completed': 'Completed',
      'category': 'Category',
      'desc': 'Description',
      'loc': 'Location',
      'date_finished': 'Finished At',
      'building': 'Bldg',
      'room': 'Room',
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

  String _getCategoryDisplay(String key) {
    if (_currentLanguageCode == 'th') return key;
    return _categoryEnMap[key] ?? key;
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

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('tickets')
          .select()
          .eq('status', 'completed')
          .eq('technician_id', user.id)
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
    setState(() => _filteredTickets = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                hintText: tr('search_hint'),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey[300]),
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
                      return _buildHistoryCard(_filteredTickets[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ticket) {
    return Container(
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tr('status_completed'),
                      style: const TextStyle(
                        color: Colors.green,
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
          Text(
            _getCategoryDisplay(ticket['category']),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            "${tr('building')} ${ticket['dorm_building']} ${tr('room')} ${ticket['room_number']}",
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            ticket['description'] ?? '-',
            style: TextStyle(color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 15),
          if (ticket['updated_at'] != null)
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  "${tr('date_finished')}: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ticket['updated_at']).toLocal())}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
