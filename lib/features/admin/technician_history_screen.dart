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
  DateTime? _selectedDate; // สำหรับตัวกรองวันที่
  String _currentLanguageCode = 'th';

  final Map<String, Map<String, String>> _translations = {
    'th': {
      'title': 'ประวัติงานของฉัน',
      'search_hint': 'ค้นหาเลขห้อง, ชื่อผู้แจ้ง...',
      'no_data': 'ไม่พบประวัติงาน',
      'status_completed': 'เสร็จสิ้น',
      'category': 'หมวดหมู่',
      'desc': 'อาการที่แจ้ง',
      'loc': 'สถานที่',
      'date_finished': 'เสร็จเมื่อ',
      'building': 'ตึก',
      'room': 'ห้อง',
      'btn_close': 'ปิดหน้าต่าง',
      'detail_title': 'รายละเอียดการซ่อม',
      'repair_note': 'บันทึกช่าง',
      'img_before': 'รูปก่อนซ่อม',
      'img_after': 'รูปหลังซ่อม',
      'contact': 'ผู้ติดต่อ',
      'filter_date': 'เลือกวันที่',
      'clear_filter': 'ล้างตัวกรอง',
    },
    'en': {
      'title': 'My Job History',
      'search_hint': 'Search Room, Name...',
      'no_data': 'No History Found',
      'status_completed': 'Completed',
      'category': 'Category',
      'desc': 'Issue',
      'loc': 'Location',
      'date_finished': 'Finished At',
      'building': 'Bldg',
      'room': 'Room',
      'btn_close': 'Close',
      'detail_title': 'Job Details',
      'repair_note': 'Technician Note',
      'img_before': 'Before Photo',
      'img_after': 'After Photo',
      'contact': 'Contact',
      'filter_date': 'Select Date',
      'clear_filter': 'Clear Filter',
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

      // ตรวจสอบ role ของผู้ใช้
      final userRole = user.userMetadata?['role'] ?? 'technician';
      final isHeadTech = userRole == 'head_technician';

      // ดึงข้อมูลรวมถึงรูปภาพและ Note
      var query = supabase
          .from('tickets')
          .select()
          .eq('status', 'completed');

      // ถ้าเป็นหัวหน้าช่าง = ดูงานทั้งหมด | ถ้าเป็นช่างทั่วไป = ดูเฉพาะของตัวเอง
      if (!isHeadTech) {
        query = query.eq('technician_id', user.id);
      }

      final data = await query.order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _allTickets = List<Map<String, dynamic>>.from(data);
          _applyFilters(); // เรียกใช้ฟังก์ชันกรองรวม
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    String keyword = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> temp = _allTickets;

    // กรองด้วยคำค้นหา
    if (keyword.isNotEmpty) {
      temp = temp.where((ticket) {
        final name = ticket['contact_name']?.toString().toLowerCase() ?? '';
        final room = ticket['room_number']?.toString().toLowerCase() ?? '';
        final desc = ticket['description']?.toString().toLowerCase() ?? '';
        return name.contains(keyword) ||
            room.contains(keyword) ||
            desc.contains(keyword);
      }).toList();
    }

    // กรองด้วยวันที่ (ถ้าเลือกไว้)
    if (_selectedDate != null) {
      temp = temp.where((ticket) {
        if (ticket['updated_at'] == null) return false;
        final finishDate = DateTime.parse(ticket['updated_at']).toLocal();
        return finishDate.year == _selectedDate!.year &&
            finishDate.month == _selectedDate!.month &&
            finishDate.day == _selectedDate!.day;
      }).toList();
    }

    setState(() => _filteredTickets = temp);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _applyFilters();
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
    _applyFilters();
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return "-";
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          tr('title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          // ปุ่มตัวกรองวันที่
          IconButton(
            icon: Icon(
              Icons.calendar_month_outlined,
              color: _selectedDate != null ? Colors.blue : Colors.grey[700],
            ),
            onPressed: _pickDate,
            tooltip: tr('filter_date'),
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.redAccent),
              onPressed: _clearDateFilter,
              tooltip: tr('clear_filter'),
            )
        ],
      ),
      body: Column(
        children: [
          // ช่องค้นหา
          Container(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => _applyFilters(),
              decoration: InputDecoration(
                hintText: tr('search_hint'),
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
              ),
            ),
          ),
          if (_selectedDate != null)
            Container(
              width: double.infinity,
              color: Colors.blue.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  "${tr('filter_date')}: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}",
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          // รายการงาน
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHistoryData,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTickets.isEmpty
                      ? ListView(
                          // ต้องใช้ ListView เพื่อให้ RefreshIndicator ทำงานได้แม้ไม่มีข้อมูล
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history_toggle_off,
                                        size: 70, color: Colors.grey[300]),
                                    const SizedBox(height: 15),
                                    Text(tr('no_data'),
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 16)),
                                  ],
                                ),
                              ),
                            )
                          ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ticket) {
    // ดึงรูปมาแสดงเป็น Thumbnail (ถ้ามี)
    final String? thumbUrl = ticket['completed_image_url'] ?? ticket['image_url'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTicketDetail(ticket), // กดเพื่อดูรายละเอียด
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(tr('status_completed'),
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(
                          DateTime.parse(ticket['created_at']).toLocal()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCategoryDisplay(ticket['category'] ?? '-'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                "${ticket['dorm_building']} / ${ticket['room_number']}",
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ticket['description'] ?? '-',
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // แสดงรูปเล็กด้านขวา (ถ้ามี)
                    if (thumbUrl != null)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(thumbUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
                if (ticket['updated_at'] != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        "${tr('date_finished')}: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(ticket['updated_at']).toLocal())}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันแสดง Popup รายละเอียดงาน
  void _showTicketDetail(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Text(tr('detail_title'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // ข้อมูลผู้แจ้ง
                  _buildDetailRow(Icons.person, tr('contact'),
                      "${ticket['contact_name']} (${ticket['contact_phone']})"),
                  _buildDetailRow(Icons.location_on, tr('loc'),
                      "${ticket['dorm_building']} / ${ticket['room_number']}"),
                  _buildDetailRow(Icons.category, tr('category'),
                      _getCategoryDisplay(ticket['category'])),
                  _buildDetailRow(
                      Icons.note, tr('desc'), ticket['description']),
                  
                  // FEATURE: วันนัดหมาย
                  if (ticket['appointment_date'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.blue),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('วันนัดหมาย:', style: TextStyle(fontSize: 12, color: Colors.blue)),
                              Text(_formatDateTime(ticket['appointment_date']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const Divider(height: 30),

                  // FEATURE: อุปกรณ์ที่เบิก
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: supabase.from('materials_tracking').select().eq('ticket_id', ticket['id']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || (snapshot.data ?? []).isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final materials = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2, color: Colors.black),
                              SizedBox(width: 8),
                              Text('อุปกรณ์ที่เบิก:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: materials.length,
                            separatorBuilder: (c, i) => Divider(color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final mat = materials[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${mat['material_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(child: Text('จำนวน: ${mat['quantity']} ${mat['unit']}', style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                                        Expanded(child: Text('หมวด: ${mat['material_category']}', style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                                      ],
                                    ),
                                    if (mat['notes'] != null && mat['notes'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('หมายเหตุ: ${mat['notes']}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 30),
                        ],
                      );
                    },
                  ),

                  // บันทึกของช่าง
                  if (ticket['repair_note'] != null &&
                      ticket['repair_note'].toString().isNotEmpty) ...[
                    Text(tr('repair_note'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(ticket['repair_note']),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // รูปภาพ (ถ้ามี)
                  if (ticket['started_image_url'] != null)
                    _buildImageSection(
                        tr('img_before'), ticket['started_image_url']),
                  if (ticket['completed_image_url'] != null)
                    _buildImageSection(
                        tr('img_after'), ticket['completed_image_url']),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(tr('btn_close')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value ?? '-',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(String title, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: Colors.grey[100],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}