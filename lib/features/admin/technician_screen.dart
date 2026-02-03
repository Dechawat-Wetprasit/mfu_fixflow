import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';
import 'package:mfu_fixflow/features/admin/technician_history_screen.dart';

class TechnicianScreen extends StatefulWidget {
  const TechnicianScreen({super.key});

  @override
  State<TechnicianScreen> createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends State<TechnicianScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // ตัวแปรสำหรับ List ข้อมูลและการกรอง
  List<Map<String, dynamic>> _allTickets = []; // เก็บข้อมูลดิบทั้งหมด
  List<Map<String, dynamic>> _filteredTickets = []; // เก็บข้อมูลที่แสดงผลจริง
  
  bool _isLoading = true;
  String _currentLanguageCode = 'th';
  int _selectedIndex = 0;
  bool _isNotificationEnabled = true;
  String _selectedCategoryFilter = 'All'; // ตัวแปรเก็บค่าตัวกรองปัจจุบัน

  // ตัวแปรสถิติ
  int _newJobCount = 0;
  int _inProgressCount = 0;
  int _doneCount = 0;

  final Map<String, Map<String, String>> _translations = {
    'th': {
      'greeting_morning': 'สวัสดีตอนเช้า ☀️',
      'greeting_afternoon': 'สวัสดีตอนบ่าย 🌤️',
      'greeting_evening': 'สวัสดีตอนเย็น 🌆',
      'greeting_night': 'สวัสดีตอนค่ำ 🌙',
      'role': 'พี่ช่าง (Technician)',
      'logout_title': 'ออกจากระบบ',
      'logout_confirm': 'คุณต้องการออกจากระบบใช่หรือไม่?',
      'cancel': 'ยกเลิก',
      'confirm': 'ยืนยัน',
      'stat_new': 'งานใหม่',
      'stat_fixing': 'กำลังซ่อม',
      'stat_done': 'เสร็จวันนี้',
      'list_header': 'รายการงานซ่อม',
      'empty_title': 'เยี่ยมมาก! ไม่มีงานค้าง',
      'filter_all': 'ทั้งหมด',
      'status_wait': 'รอรับงาน',
      'status_fixing': 'กำลังซ่อม',
      'status_done': 'เสร็จสิ้น',
      'btn_accept': 'รับงาน',
      'btn_finish': 'ปิดงาน',
      'btn_close': 'ปิดหน้าต่าง',
      'btn_cancel_job': 'ยกเลิก/คืนงาน', // ใหม่
      'btn_room_history': 'ประวัติห้องนี้', // ใหม่
      'cat_label': 'หมวดหมู่',
      'desc_label': 'อาการเสีย',
      'loc_label': 'สถานที่',
      'contact_label': 'ผู้แจ้ง',
      'building': 'อาคาร',
      'room': 'ห้อง',
      'detail_title': 'รายละเอียดงานซ่อม',
      'repair_note_label': 'บันทึกการซ่อม (ทำอะไรไปบ้าง?)', // ใหม่
      'repair_note_hint': 'เช่น เปลี่ยนหลอดไฟ, ขันก๊อกน้ำ', // ใหม่
      'update_success': 'อัปเดตสถานะเรียบร้อย',
      'update_error': 'เกิดข้อผิดพลาดในการอัปเดต',
      'nav_home': 'หน้าหลัก',
      'nav_more': 'เพิ่มเติม',
      'more_menu': 'เมนูเพิ่มเติม',
      'notification': 'การแจ้งเตือน',
      'notification_on': 'เปิดใช้งาน',
      'notification_off': 'ปิดใช้งาน',
      'language': 'เปลี่ยนภาษา',
      'help': 'ช่วยเหลือ',
      'exit': 'ออก',
      'history_tooltip': 'ประวัติงาน',
      'urgent': 'ด่วนมาก!',
      'call_now': 'โทรหาผู้แจ้ง',
      'complete_dialog_title': 'ส่งงาน / ปิดงาน',
      'photo_proof': 'รูปถ่ายหลังซ่อมเสร็จ',
      'tap_to_take_photo': 'แตะเพื่อถ่ายรูป',
      'uploading': 'กำลังอัปโหลดรูป...',
      'contact_admin': 'ติดต่อผู้ดูแลระบบ',
      'admin_contact_info': 'โทร: 02-xxx-xxxx\nLine: @mfufixflow',
    },
    'en': {
      'greeting_morning': 'Good Morning ☀️',
      'greeting_afternoon': 'Good Afternoon 🌤️',
      'greeting_evening': 'Good Evening 🌆',
      'greeting_night': 'Good Night 🌙',
      'role': 'Technician',
      'logout_title': 'Logout',
      'logout_confirm': 'Do you want to logout?',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'stat_new': 'New Jobs',
      'stat_fixing': 'In Progress',
      'stat_done': 'Done Today',
      'list_header': 'Job List',
      'empty_title': 'Great! No pending jobs.',
      'filter_all': 'All',
      'status_wait': 'Waiting',
      'status_fixing': 'In Progress',
      'status_done': 'Completed',
      'btn_accept': 'Accept',
      'btn_finish': 'Complete',
      'btn_close': 'Close',
      'btn_cancel_job': 'Return Job', // ใหม่
      'btn_room_history': 'Room History', // ใหม่
      'cat_label': 'Category',
      'desc_label': 'Problem',
      'loc_label': 'Location',
      'contact_label': 'Contact',
      'building': 'Building',
      'room': 'Room',
      'detail_title': 'Job Details',
      'repair_note_label': 'Repair Note', // ใหม่
      'repair_note_hint': 'e.g. Changed light bulb', // ใหม่
      'update_success': 'Status updated successfully',
      'update_error': 'Error updating status',
      'nav_home': 'Home',
      'nav_more': 'More',
      'more_menu': 'More Menu',
      'notification': 'Notification',
      'notification_on': 'Enabled',
      'notification_off': 'Disabled',
      'language': 'Language',
      'help': 'Help',
      'exit': 'Logout',
      'history_tooltip': 'History',
      'urgent': 'URGENT!',
      'call_now': 'Call User',
      'complete_dialog_title': 'Complete Job',
      'photo_proof': 'After-Repair Photo',
      'tap_to_take_photo': 'Tap to take photo',
      'uploading': 'Uploading image...',
      'contact_admin': 'Contact Admin',
      'admin_contact_info': 'Tel: 02-xxx-xxxx\nLine: @mfufixflow',
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return tr('greeting_morning');
    if (hour >= 12 && hour < 17) return tr('greeting_afternoon');
    if (hour >= 17 && hour < 21) return tr('greeting_evening');
    return tr('greeting_night');
  }

  String _getCategoryDisplay(String key) {
    if (_currentLanguageCode == 'th') return key;
    return _categoryEnMap[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguageCode = prefs.getString('language_code') ?? 'th';
      _isNotificationEnabled = prefs.getBool('notification_enabled') ?? true;
    });
  }

  Future<void> _saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }

  Future<void> _saveNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', enabled);
  }

  // --- Core Logic: Load & Sort & Filter ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. ดึงข้อมูล (ไม่เอา Pending, Rejected)
      final response = await supabase
          .from('tickets')
          .select()
          .neq('status', 'pending')
          .neq('status', 'rejected')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> rawData = List<Map<String, dynamic>>.from(response);

      // แยกข้อมูลเพื่อนับสถิติ
      int newJob = 0;
      int fixing = 0;
      int done = 0;
      List<Map<String, dynamic>> activeJobs = [];

      for (var ticket in rawData) {
        if (ticket['status'] == 'approved') newJob++;
        if (ticket['status'] == 'in_progress') fixing++;
        if (ticket['status'] == 'completed') done++;

        // เอาเฉพาะงานที่ "ยังไม่เสร็จ" มาโชว์ใน List หน้าหลัก
        if (ticket['status'] != 'completed') {
          activeJobs.add(ticket);
        }
      }

      // 2. Sorting (เรียงลำดับความสำคัญ)
      activeJobs.sort((a, b) {
        // เช็คความด่วน
        bool isUrgentA = (a['description'] ?? '').toString().contains('ด่วน');
        bool isUrgentB = (b['description'] ?? '').toString().contains('ด่วน');

        // กฏที่ 1: งานด่วนมาก่อนเสมอ
        if (isUrgentA && !isUrgentB) return -1;
        if (!isUrgentA && isUrgentB) return 1;

        // กฏที่ 2: งานที่ "กำลังซ่อม" (In Progress) มาก่อนงานใหม่ (Approved)
        bool isFixingA = a['status'] == 'in_progress';
        bool isFixingB = b['status'] == 'in_progress';
        if (isFixingA && !isFixingB) return -1;
        if (!isFixingA && isFixingB) return 1;

        // กฏที่ 3: นอกนั้นเรียงตามเวลา (ใหม่สุดอยู่บน)
        return 0;
      });

      if (mounted) {
        setState(() {
          _allTickets = activeJobs; // เก็บ Master List
          _newJobCount = newJob;
          _inProgressCount = fixing;
          _doneCount = done;
          _isLoading = false;
        });
        _applyFilter(); // เรียกตัวกรอง
      }
    } catch (e) {
      debugPrint("Error loading: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันกรองข้อมูลตาม Chip ที่เลือก
  void _applyFilter() {
    setState(() {
      if (_selectedCategoryFilter == 'All') {
        _filteredTickets = List.from(_allTickets);
      } else {
        _filteredTickets = _allTickets
            .where((t) => t['category'] == _selectedCategoryFilter)
            .toList();
      }
    });
  }

  Future<void> _updateStatus(
    dynamic ticketId,
    String newStatus,
    String? studentId, {
    String? imageUrl,
    String? repairNote, // เพิ่มตัวแปรรับ Note
    bool isUnAccepting = false, // เพิ่มตัวแปรเช็คการคืนงาน
  }) async {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final techUser = supabase.auth.currentUser;
    final techName = techUser?.userMetadata?['full_name'] ?? "พี่ช่าง";

    // Logic การแจ้งเตือน
    if (studentId != null && !isUnAccepting) {
      String title = '';
      String msg = '';
      if (newStatus == 'in_progress') {
        title = '🛠️ ช่างรับงานแล้ว ($timeStr)';
        msg = 'ช่าง "$techName" กำลังเข้าดำเนินการซ่อม';
      } else if (newStatus == 'completed') {
        title = '✅ งานซ่อมเสร็จสิ้น';
        msg = 'การซ่อมเสร็จเรียบร้อยแล้ว ขอบคุณครับ';
      }

      if (title.isNotEmpty) {
        await supabase.from('notifications').insert({
          'user_id': studentId,
          'title': title,
          'message': msg,
          'is_read': false,
        });
      }
    }

    try {
      final Map<String, dynamic> updateData = {'status': newStatus};
      
      // กรณีรับงาน
      if (newStatus == 'in_progress' && techUser != null) {
        updateData['technician_id'] = techUser.id;
      }
      // กรณีคืนงาน (Un-accept)
      if (isUnAccepting) {
        updateData['technician_id'] = null;
      }
      // กรณีปิดงาน
      if (newStatus == 'completed') {
        if (imageUrl != null) updateData['completed_image_url'] = imageUrl;
        if (repairNote != null) updateData['repair_note'] = repairNote;
      }

      await supabase.from('tickets').update(updateData).eq('id', ticketId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${tr('update_success')} ✅"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData(); // โหลดใหม่เพื่อจัดเรียง
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("${tr('update_error')}: $e"), backgroundColor: Colors.red),
        );
      }
      _loadData();
    }
  }

  // --- ฟังก์ชันโทรออกจริง ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      if (mounted) {
         showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("📞 เบอร์โทรศัพท์"),
            content: Text(phoneNumber),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text("ปิด")),
            ],
          ),
        );
      }
    }
  }

  // --- ฟังก์ชันอัปโหลดรูปภาพ ---
  Future<String?> _uploadEvidenceImage(File imageFile) async {
    try {
      final fileName = 'job_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$fileName'; // อัปโหลดลง root หรือตาม policy
      await supabase.storage.from('job_evidence').upload(path, imageFile);
      return supabase.storage.from('job_evidence').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }

  // --- UI Components: Filter Section ---
  Widget _buildFilterSection() {
    // หา Category ทั้งหมดที่มีเพื่อสร้าง Chips
    Set<String> categories = {'All'};
    for (var t in _allTickets) {
      if (t['category'] != null) categories.add(t['category']);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: categories.map((cat) {
          bool isSelected = _selectedCategoryFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getCategoryDisplay(cat == 'All' ? tr('filter_all') : cat)),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _selectedCategoryFilter = cat;
                  _applyFilter();
                });
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue[800] : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white,
              side: isSelected ? const BorderSide(color: Colors.blue) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Dialog: Room History ---
  Future<void> _showRoomHistory(String building, String room) async {
    // ดึงประวัติ 5 รายการล่าสุด
    final history = await supabase
        .from('tickets')
        .select()
        .eq('dorm_building', building)
        .eq('room_number', room)
        .eq('status', 'completed')
        .order('created_at', ascending: false)
        .limit(5);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${tr('btn_room_history')}: $building $room", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("ไม่พบประวัติการซ่อม")),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(item['created_at']));
                  return ListTile(
                    leading: const Icon(Icons.history, color: Colors.grey),
                    title: Text(item['category'] ?? '-'),
                    subtitle: Text("${item['description']}\n(ซ่อมโดย: ${item['repair_note'] ?? '-'})"),
                    trailing: Text(date, style: const TextStyle(fontSize: 12)),
                    isThreeLine: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialog: Complete Job (with Note) ---
  void _showCompleteDialog(dynamic ticketId, String? studentId) {
    File? selectedImage;
    bool isUploading = false;
    TextEditingController noteController = TextEditingController(); // รับ Note

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(tr('complete_dialog_title')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final XFile? photo = await _picker.pickImage(
                        source: ImageSource.camera, 
                        imageQuality: 50,
                      );
                      if (photo != null) {
                        setDialogState(() {
                          selectedImage = File(photo.path);
                        });
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[400]!),
                        image: selectedImage != null 
                          ? DecorationImage(
                              image: FileImage(selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      ),
                      child: selectedImage == null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text(tr('tap_to_take_photo'), style: const TextStyle(color: Colors.grey)),
                            ],
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // ช่องกรอก Note
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: tr('repair_note_label'),
                      hintText: tr('repair_note_hint'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 15),
                    const LinearProgressIndicator(),
                    Text(tr('uploading'), style: const TextStyle(fontSize: 12)),
                  ]
                ],
              ),
            ),
            actions: [
              if (!isUploading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey)),
                ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("กรุณาถ่ายรูปยืนยันงานซ่อม")),
                    );
                    return;
                  }

                  setDialogState(() => isUploading = true);
                  
                  final imageUrl = await _uploadEvidenceImage(selectedImage!);
                  
                  if (imageUrl != null) {
                    if (mounted) Navigator.pop(context);
                    await _updateStatus(ticketId, 'completed', studentId, imageUrl: imageUrl, repairNote: noteController.text);
                  } else {
                    setDialogState(() => isUploading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: Text(tr('confirm')),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Dialog: Job Detail (With History & Un-accept) ---
  void _showJobDetailDialog(Map<String, dynamic> ticket) {
    final studentId = ticket['user_id'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  
                  // Header พร้อมปุ่มดูประวัติ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tr('detail_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      OutlinedButton.icon(
                        onPressed: () => _showRoomHistory(ticket['dorm_building'], ticket['room_number']),
                        icon: const Icon(Icons.history_edu, size: 18),
                        label: Text(tr('btn_room_history'), style: const TextStyle(fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (ticket['image_url'] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        ticket['image_url'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildDetailRow(Icons.category, tr('cat_label'), _getCategoryDisplay(ticket['category'] ?? '-')),
                  _buildDetailRow(Icons.description, tr('desc_label'), ticket['description']),
                  _buildDetailRow(Icons.location_on, tr('loc_label'), "${tr('building')} ${ticket['dorm_building']} ${tr('room')} ${ticket['room_number']}"),
                  _buildDetailRow(Icons.person, tr('contact_label'), "${ticket['contact_name']} (${ticket['contact_phone']})"),
                  
                  const SizedBox(height: 30),
                  
                  if (ticket['status'] == 'approved')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateStatus(ticket['id'], 'in_progress', studentId);
                        },
                        icon: const Icon(Icons.handyman),
                        label: Text(tr('btn_accept')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  
                  if (ticket['status'] == 'in_progress') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCompleteDialog(ticket['id'], studentId);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: Text(tr('btn_finish')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ปุ่มคืนงาน (สีส้ม)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _updateStatus(ticket['id'], 'approved', studentId, isUnAccepting: true);
                        },
                        icon: const Icon(Icons.undo),
                        label: Text(tr('btn_cancel_job')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange[800],
                          side: BorderSide(color: Colors.orange[800]!),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr('btn_close'), style: const TextStyle(color: Colors.grey)),
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

  // --- Helper Widgets ---
  Widget _buildDetailRow(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value ?? "-", style: const TextStyle(fontSize: 15, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('logout_title')),
        content: Text(tr('logout_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(tr('exit')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('contact_admin')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            Text(tr('admin_contact_info'), textAlign: TextAlign.center),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
      ),
    );
  }

  Future<void> _showMoreMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15), width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
                Text(tr('more_menu'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildMenuItem(
                        Icons.notifications_outlined, tr('notification'),
                        _isNotificationEnabled ? tr('notification_on') : tr('notification_off'),
                        trailing: Switch(
                          value: _isNotificationEnabled,
                          activeThumbColor: Colors.purple,
                          onChanged: (val) {
                            setModalState(() => _isNotificationEnabled = val);
                            setState(() => _isNotificationEnabled = val);
                            _saveNotification(val);
                          },
                        ),
                        onTap: () {},
                      ),
                      _buildMenuItem(Icons.language, tr('language'), _currentLanguageCode == 'th' ? "ไทย" : "English", onTap: () => _showLanguageSelector(context)),
                      _buildMenuItem(Icons.help_outline, tr('help'), null, onTap: () => _showHelpDialog()),
                      const Divider(),
                      _buildMenuItem(Icons.logout, tr('logout_title'), null, color: Colors.red, onTap: () { Navigator.pop(context); _handleLogout(); }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLanguageSelector(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (c) => AlertDialog(
        title: Text(tr('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text("ไทย (TH)"), leading: Radio(value: "th", groupValue: _currentLanguageCode, onChanged: (val) { setState(() => _currentLanguageCode = val as String); _saveLanguage(val as String); Navigator.pop(c); }), onTap: () { setState(() => _currentLanguageCode = "th"); _saveLanguage("th"); Navigator.pop(c); }),
            ListTile(title: const Text("English (EN)"), leading: Radio(value: "en", groupValue: _currentLanguageCode, onChanged: (val) { setState(() => _currentLanguageCode = val as String); _saveLanguage(val as String); Navigator.pop(c); }), onTap: () { setState(() => _currentLanguageCode = "en"); _saveLanguage("en"); Navigator.pop(c); }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String? subtitle, {Widget? trailing, Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (color ?? Colors.purple).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color ?? Colors.purple)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.blueAccent,
        child: Stack(
          children: [
            Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.engineering, color: Colors.white)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getGreeting(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            Text(supabase.auth.currentUser?.userMetadata?['full_name'] ?? tr('role'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    // Stats Box
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatusItem(_newJobCount, tr('stat_new'), Colors.orange),
                          Container(width: 1, height: 40, color: Colors.grey[200]),
                          _buildStatusItem(_inProgressCount, tr('stat_fixing'), Colors.blue),
                          Container(width: 1, height: 40, color: Colors.grey[200]),
                          _buildStatusItem(_doneCount, tr('stat_done'), Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Filter Section (ใหม่)
                    _buildFilterSection(),

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tr('list_header'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        IconButton(icon: const Icon(Icons.refresh, color: Colors.blue), onPressed: _loadData),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // List View
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredTickets.isEmpty // ใช้ List ที่กรองแล้ว
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredTickets.length,
                              itemBuilder: (context, index) {
                                return _buildJobCard(_filteredTickets[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: const AlwaysStoppedAnimation(1.0),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianHistoryScreen())),
          backgroundColor: Colors.blue, elevation: 4, shape: const CircleBorder(),
          tooltip: tr('history_tooltip'),
          child: const Icon(Icons.history, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white, surfaceTintColor: Colors.white, shape: const CircularNotchedRectangle(), notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AnimatedNavButton(icon: Icons.home_rounded, label: tr('nav_home'), isSelected: _selectedIndex == 0, onTap: () { setState(() => _selectedIndex = 0); _loadData(); }),
              const SizedBox(width: 40),
              _AnimatedNavButton(icon: Icons.grid_view_rounded, label: tr('nav_more'), isSelected: _selectedIndex == 1, onTap: () { setState(() => _selectedIndex = 1); _showMoreMenu(); Future.delayed(const Duration(milliseconds: 300), () { if (mounted) setState(() => _selectedIndex = 0); }); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(int count, String label, Color color) {
    return Column(children: [Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500))]);
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]), const SizedBox(height: 15), Text(tr('empty_title'), style: TextStyle(fontSize: 16, color: Colors.grey[500]))]));
  }

  Widget _buildJobCard(Map<String, dynamic> ticket) {
    String status = ticket['status'] ?? '';
    Color statusColor = Colors.grey;
    String statusText = status;
    IconData icon = Icons.help_outline;

    if (status == 'approved') {
      statusColor = Colors.orange; statusText = tr('status_wait'); icon = Icons.notifications_active;
    } else if (status == 'in_progress') {
      statusColor = Colors.blue; statusText = tr('status_fixing'); icon = Icons.build;
    }

    bool isUrgent = (ticket['description'] ?? '').toString().contains('ด่วน') || (ticket['description'] ?? '').toString().contains('ไฟไหม้') || (ticket['description'] ?? '').toString().contains('รั่ว');

    return Card(
      margin: const EdgeInsets.only(bottom: 12), elevation: 2, shadowColor: Colors.black12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15), onTap: () => _showJobDetailDialog(ticket),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: statusColor, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          if (isUrgent) Container(margin: const EdgeInsets.only(right: 5), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: Text(tr('urgent'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(child: Text(_getCategoryDisplay(ticket['category'] ?? '-'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 4),
                        Text("${tr('building')} ${ticket['dorm_building']} ${tr('room')} ${ticket['room_number']}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        const SizedBox(height: 2),
                        Text("${tr('desc_label')}: ${ticket['description'] ?? '-'}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      InkWell(onTap: () => _makePhoneCall(ticket['contact_phone'] ?? 'Unknown'), child: const CircleAvatar(radius: 12, backgroundColor: Colors.green, child: Icon(Icons.phone, size: 14, color: Colors.white))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedNavButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;
  const _AnimatedNavButton({required this.icon, required this.isSelected, required this.onTap, this.label});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? Colors.purple.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 26, color: isSelected ? Colors.purple : Colors.grey), if (isSelected && label != null) ...[const SizedBox(width: 8), Text(label!, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12))]]),
      ),
    );
  }
}