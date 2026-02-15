import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // อย่าลืมลง pubspec: intl: ^0.18.0
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';
import 'package:mfu_fixflow/features/admin/technician_history_screen.dart';
import 'package:mfu_fixflow/features/admin/materials_tracking_screen.dart';

class TechnicianScreen extends StatefulWidget {
  const TechnicianScreen({super.key});

  @override
  State<TechnicianScreen> createState() => _TechnicianScreenState();
}

class _TechnicianScreenState extends State<TechnicianScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // --- Settings & State ---
  String _currentLanguageCode = 'th';
  int _selectedIndex = 0;
  bool _isNotificationEnabled = true;
  String _userRole = 'technician'; // 'technician' or 'head_technician'
  bool _isHeadTech = false;

  // --- VIBRANT PALETTE ---
  final Color _gradStart = const Color(0xFF00C6FF); 
  final Color _gradEnd = const Color(0xFF0072FF);   
  final Color _bgColor = const Color(0xFFF0F2F5);   
  
  // Status Colors
  final Color _colWait = const Color(0xFFFF9F43);   
  final Color _colFix = const Color(0xFF0ABDE3);    
  final Color _colDone = const Color(0xFF1DD1A1);   
  final Color _colUrgent = const Color(0xFFEE5253); 

  // --- Translations ---
  final Map<String, Map<String, String>> _translations = {
    'th': {
      'greeting': 'สวัสดี,',
      'role': 'ช่างเทคนิค',
      'role_head': 'หัวหน้าช่างเทคนิค',
      'reassign': 'มอบหมายให้ช่างอื่น',
      'reassign_confirm': 'ยืนยันมอบหมาย?',
      'reassign_success': 'มอบหมายเรียบร้อย',
      'stat_new': 'งานใหม่',
      'stat_fixing': 'กำลังทำ',
      'stat_done': 'ยอดสะสม',
      'list_header': 'รายการงานซ่อม',
      'empty_title': 'เยี่ยมมาก! เคลียร์งานหมดแล้ว',
      'status_wait': 'รอรับงาน',
      'status_fixing': 'กำลังซ่อม',
      'btn_accept': 'รับงาน',
      'btn_finish': 'ปิดงาน',
      'btn_close': 'ปิด',
      'btn_cancel_job': 'ยกเลิก',
      'btn_room_history': 'ประวัติห้อง',
      'cat_label': 'หมวดหมู่',
      'desc_label': 'อาการ',
      'loc_label': 'จุดซ่อม',
      'contact_label': 'ผู้แจ้ง',
      'detail_title': 'รายละเอียดงาน',
      'btn_view_detail': 'ดูรายละเอียด',
      'repair_note_label': 'ผลการซ่อม',
      'repair_note_hint': 'ระบุสิ่งที่แก้ไข...',
      'update_success': 'บันทึกข้อมูลเรียบร้อย',
      'update_error': 'เกิดข้อผิดพลาด โปรดลองใหม่',
      'nav_home': 'หน้าหลัก',
      'nav_more': 'เมนู',
      'notification': 'ศูนย์แจ้งเตือน',
      'language': 'ภาษา (Language)',
      'help': 'ศูนย์ช่วยเหลือ',
      'logout_title': 'ออกจากระบบ',
      'logout_confirm': 'ยืนยันการออกจากระบบ?',
      'cancel': 'ยกเลิก',
      'exit': 'ออก',
      'history_tooltip': 'ประวัติ',
      'summary_tooltip': 'สรุปผลงาน',
      'urgent': 'ด่วน',
      'tap_to_take_photo': 'ถ่ายรูป',
      'uploading': 'กำลังบันทึก...',
      'contact_admin': 'ติดต่อ Admin',
      'admin_contact_info': 'โทร: 02-xxx-xxxx',
      'confirm': 'ยืนยันปิดงาน',
      'summary_title': 'สรุปผลงานของคุณ',
      'sum_daily': 'วันนี้',
      'sum_weekly': 'สัปดาห์นี้',
      'sum_monthly': 'เดือนนี้',
      'sum_total': 'รวมทั้งหมด',
      'menu_history': 'ประวัติงาน',
      'menu_summary': 'สรุปยอดงาน',
      'btn_before_photo': 'ถ่ายรูปก่อนซ่อม',
      'photo_required': 'กรุณาถ่ายรูปผลงานก่อนปิดงาน',
      'tab_news': 'ข่าวสาร',
      'tab_noti': 'แจ้งเตือน',
      'noti_empty': 'ไม่มีข้อมูลใหม่',
      'noti_new_job': 'มีงานใหม่เข้ามา!',
      'noti_completed': 'คุณปิดงานไปแล้ว',
      'appt_label': 'เวลานัดหมาย',
      'appt_btn': 'นัดหมาย / เปลี่ยนเวลา',
      'appt_success': 'บันทึกเวลานัดหมายแล้ว',
      'no_appt': 'ยังไม่ได้นัดหมาย',
      'coming_soon_title': 'Coming soon',
      'coming_soon_msg': 'ฟีเจอร์นี้จะเปิดใช้งานเร็วๆ นี้',
      'ok': 'ตกลง',
      'more_menu': 'เมนูเพิ่มเติม',
      'notification_on': 'เปิดใช้งาน',
      'notification_off': 'ปิดใช้งาน',
      'materials_summary': 'สรุปเบิกของ',
      'materials_summary_desc': 'ดูสรุปการเบิกอุปกรณ์',
      'materials_list': 'รายการอุปกรณ์ที่เบิก',
      'material_name': 'ชื่ออุปกรณ์',
      'material_quantity': 'จำนวน',
      'material_date': 'วันที่เบิก',
      'material_technician': 'ช่างท่านนี้',
      'no_materials': 'ยังไม่มีการเบิกอุปกรณ์',
      'total_materials': 'รวมทั้งสิ้น',
      'technicians_list': 'รายชื่อช่างเทคนิค',
      'technicians_desc': 'ดูรายละเอียดช่างและงานที่ติด',
      'tech_active_jobs': 'งานติดอยู่',
      'tech_completed_jobs': 'งานเสร็จแล้ว',
      'tech_rating': 'คะแนนเฉลี่ย',
      'tech_feedback': 'ความเห็นผู้ใช้',
      'no_feedback': 'ยังไม่มีความเห็นจากผู้ใช้',
      'no_active_jobs': 'ไม่มีงานติดอยู่',
      'star': 'ดาว',
      'job_room': 'ห้อง',
      'job_category': 'หมวดหมู่',
      'job_status': 'สถานะ',
    },
    'en': {
      'greeting': 'Hello,',
      'role': 'Technician',
      'role_head': 'Head Technician',
      'reassign': 'Reassign',
      'reassign_confirm': 'Reassign job?',
      'reassign_success': 'Reassigned successfully',
      'stat_new': 'New',
      'stat_fixing': 'Active',
      'stat_done': 'Total Done',
      'list_header': 'Your Tasks',
      'empty_title': 'All Clear! Great Job.',
      'status_wait': 'Pending',
      'status_fixing': 'Ongoing',
      'btn_accept': 'Accept',
      'btn_finish': 'Complete',
      'btn_close': 'Close',
      'btn_cancel_job': 'Cancel',
      'btn_room_history': 'History',
      'cat_label': 'Category',
      'desc_label': 'Issue',
      'loc_label': 'Location',
      'contact_label': 'Contact',
      'detail_title': 'Task Details',
      'btn_view_detail': 'View Details',
      'repair_note_label': 'Resolution Note',
      'repair_note_hint': 'What did you fix...',
      'update_success': 'Saved successfully',
      'update_error': 'Error occurred',
      'nav_home': 'Home',
      'nav_more': 'Menu',
      'notification': 'Notification Center',
      'language': 'Language',
      'help': 'Help Center',
      'logout_title': 'Logout',
      'logout_confirm': 'Are you sure?',
      'cancel': 'Cancel',
      'exit': 'Exit',
      'history_tooltip': 'History',
      'summary_tooltip': 'Performance',
      'urgent': 'URGENT',
      'tap_to_take_photo': 'Take Photo',
      'uploading': 'Saving...',
      'contact_admin': 'Contact Admin',
      'admin_contact_info': 'Tel: 02-xxx-xxxx',
      'confirm': 'Confirm Completion',
      'summary_title': 'Performance Summary',
      'sum_daily': 'Today',
      'sum_weekly': 'This Week',
      'sum_monthly': 'This Month',
      'sum_total': 'All Time',
      'menu_history': 'Job History',
      'menu_summary': 'Performance',
      'btn_before_photo': 'Before Photo',
      'photo_required': 'Photo evidence is required',
      'tab_news': 'News',
      'tab_noti': 'Activity',
      'noti_empty': 'No new data',
      'noti_new_job': 'New Job Available!',
      'noti_completed': 'Job Completed',
      'appt_label': 'Appointment',
      'appt_btn': 'Schedule / Reschedule',
      'appt_success': 'Appointment saved',
      'no_appt': 'No appointment set',
      'coming_soon_title': 'Coming soon',
      'coming_soon_msg': 'This feature will be available soon',
      'ok': 'OK',
      'more_menu': 'More Menu',
      'notification_on': 'Enabled',
      'notification_off': 'Disabled',
      'materials_summary': 'Materials Summary',
      'materials_summary_desc': 'View materials withdrawal summary',
      'materials_list': 'Materials List',
      'material_name': 'Material Name',
      'material_quantity': 'Quantity',
      'material_date': 'Withdrawal Date',
      'material_technician': 'Technician',
      'no_materials': 'No materials withdrawn yet',
      'total_materials': 'Total',
      'technicians_list': 'Technicians List',
      'technicians_desc': 'View technician details and assignments',
      'tech_active_jobs': 'Active Jobs',
      'tech_completed_jobs': 'Completed Jobs',
      'tech_rating': 'Average Rating',
      'tech_feedback': 'User Feedback',
      'no_feedback': 'No user feedback yet',
      'no_active_jobs': 'No active jobs',
      'star': 'stars',
      'job_room': 'Room',
      'job_category': 'Category',
      'job_status': 'Status',
    },
  };

  final Map<String, String> _categoryEnMap = {
    'แจ้งซ่อมทั่วไป': 'General',
    'ไฟฟ้า/ประปา': 'Electric/Water',
    'เครื่องปรับอากาศ': 'Air Con',
    'เฟอร์นิเจอร์/อุปกรณ์': 'Furniture',
    'ความสะอาด': 'Cleaning',
    'อินเทอร์เน็ต': 'Internet',
    'อื่นๆ': 'Others',
  };

  String tr(String key) => _translations[_currentLanguageCode]?[key] ?? key;

  String _getCategoryDisplay(String key) {
    if (_currentLanguageCode == 'th') return key;
    return _categoryEnMap[key] ?? key;
  }

  // Helper for Date Formatting
  String _formatDateTime(String? isoString) {
    if (isoString == null) return tr('no_appt');
    final dt = DateTime.parse(isoString).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt); // e.g., 25/12/2023 14:30
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = supabase.auth.currentUser;
    final role = user?.userMetadata?['role'] as String? ?? 'technician';
    setState(() {
      _currentLanguageCode = prefs.getString('language_code') ?? 'th';
      _isNotificationEnabled = prefs.getBool('notification_enabled') ?? true;
      _userRole = role;
      _isHeadTech = role == 'head_technician';
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

  void _showNotification(String message, {bool isError = false}) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(color: isError ? _colUrgent : _colDone, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Row(children: [Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 24), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)))]),
        ),
        behavior: SnackBarBehavior.floating, backgroundColor: Colors.transparent, elevation: 0, margin: const EdgeInsets.all(20), duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _reassignJob(dynamic ticketId, String currentTechName) async {
    try {
      final techs = await supabase.from('profiles').select().eq('role', 'technician');
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('reassign')),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.separated(
              itemCount: techs.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final tech = techs[index];
                return ListTile(
                  title: Text(tech['full_name'] ?? 'Unknown'),
                  leading: CircleAvatar(backgroundColor: _colFix.withOpacity(0.2), child: Text((index + 1).toString())),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmReassign(ticketId, tech['id'], tech['full_name']);
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel')))],
        ),
      );
    } catch (e) {
      _showNotification('Error: $e', isError: true);
    }
  }

  Future<void> _confirmReassign(String ticketId, String newTechId, String newTechName) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('reassign_confirm')),
        content: Text(newTechName),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await supabase.from('tickets').update({
                  'technician_id': newTechId,
                  'technician_name': newTechName,
                  'status': 'approved',
                  'started_image_url': null,
                  'repair_note': null,
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', ticketId);
                _showNotification(tr('reassign_success'));
              } catch (e) {
                _showNotification('Error: $e', isError: true);
              }
            },
            child: Text(tr('confirm')),
          ),
        ],
      ),
    );
  }

  // --- Logic: Updates ---
  Future<bool> _updateStatus(dynamic ticketId, String newStatus, String? studentId, {String? imageUrl, String? beforeImageUrl, String? repairNote, bool isUnAccepting = false}) async {
    final techUser = supabase.auth.currentUser;
    final Map<String, dynamic> updateData = {'status': newStatus};
    if (newStatus == 'in_progress' && techUser != null) {
      updateData['technician_id'] = techUser.id;
      updateData['technician_name'] = techUser.userMetadata?['full_name'] ?? 'Technician';
    }
    if (isUnAccepting) {
      updateData['technician_id'] = null;
      updateData['technician_name'] = null;
    }
    if (newStatus == 'completed') {
      updateData['updated_at'] = DateTime.now().toIso8601String(); 
      if (imageUrl != null) updateData['completed_image_url'] = imageUrl;
      if (repairNote != null) updateData['repair_note'] = repairNote;
    }
    if (beforeImageUrl != null) { updateData.remove('status'); updateData['started_image_url'] = beforeImageUrl; }
    try {
      await supabase.from('tickets').update(updateData).eq('id', ticketId);
      
      // ✅ เพิ่มบันทึกลง room_logs เมื่อซ่อมเสร็จ
      if (newStatus == 'completed') {
        final ticket = await supabase.from('tickets').select().eq('id', ticketId).single();
        final roomNumber = ticket['room_number'] ?? '';
        final dorm = ticket['dorm_building'] ?? '';
        final fullRoomNumber = "$dorm$roomNumber";
        
        await supabase.from('room_logs').insert({
          'room_number': fullRoomNumber,
          'title': ticket['category'] ?? 'ซ่อมบำรุง',
          'status': 'เสร็จ',
          'performed_by': techUser?.userMetadata?['full_name'] ?? 'ช่างเทคนิค',
          'log_date': DateTime.now().toIso8601String(),
        });
      }
      
      _showNotification(tr('update_success')); 
      return true;
    } catch (e) {
      debugPrint("Error: $e");
      _showNotification(tr('update_error'), isError: true);
      return false;
    }
  }

  // FEATURE: Handle Appointment
  Future<void> _handleAppointment(String ticketId) async {
    final now = DateTime.now();
    // 1. Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: _gradEnd)), child: child!);
      },
    );
    if (pickedDate == null) return;

    // 2. Pick Time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: _gradEnd)), child: child!);
      },
    );
    if (pickedTime == null) return;

    // 3. Combine & Save
    final DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    
    try {
      await supabase.from('tickets').update({'appointment_date': finalDateTime.toIso8601String()}).eq('id', ticketId);
      _showNotification(tr('appt_success'));
      Navigator.pop(context); // Close detail dialog to refresh
    } catch (e) {
      _showNotification(tr('update_error'), isError: true);
    }
  }

  // --- UI Main Build ---
  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('tickets').stream(primaryKey: ['id']).order('created_at', ascending: false), 
      builder: (context, snapshot) {
        
        List<Map<String, dynamic>> allTickets = snapshot.data ?? [];
        int newJobCount = 0;
        int fixingCount = 0;
        int totalDoneCount = 0;
        int doneDaily = 0;
        int doneWeekly = 0;
        int doneMonthly = 0;
        
        List<Map<String, dynamic>> activeList = []; 
        List<Map<String, dynamic>> notificationList = []; 
        final now = DateTime.now();

        for (var t in allTickets) {
          String status = t['status'] ?? '';
          String? assignedTechId = t['technician_id'];
          bool isMine = assignedTechId == myId;
          
          // Head tech sees all, regular tech sees only theirs
          bool shouldInclude = _isHeadTech || isMine;

          // Stats (only for own jobs if technician, all if head_tech)
          if (status == 'approved' && (_isHeadTech || assignedTechId == null || isMine)) {
            newJobCount++;
            notificationList.add(t); 
          }
          if (status == 'in_progress' && shouldInclude) fixingCount++;
          
          if (status == 'completed' && shouldInclude) {
             totalDoneCount++; 
             final doneTimeStr = t['updated_at'] ?? t['created_at'];
             if (doneTimeStr != null) {
               final doneDate = DateTime.parse(doneTimeStr).toLocal();
               if (doneDate.day == now.day && doneDate.month == now.month && doneDate.year == now.year) doneDaily++;
               if (doneDate.month == now.month && doneDate.year == now.year) doneMonthly++;
               final diff = now.difference(doneDate).inDays;
               if (diff < 7) doneWeekly++;
               if (notificationList.length < 10) notificationList.add(t);
             }
          }

          if (status == 'completed' || status == 'rejected' || status == 'pending') continue;
          // Head tech sees all active jobs, regular tech sees only assigned ones
          if (!_isHeadTech && assignedTechId != null && !isMine) continue;
          activeList.add(t);
        }

        activeList.sort((a, b) {
          bool urgentA = (a['description'] ?? '').toString().contains('ด่วน');
          bool urgentB = (b['description'] ?? '').toString().contains('ด่วน');
          if (urgentA && !urgentB) return -1;
          if (!urgentA && urgentB) return 1;
          bool myJobA = a['technician_id'] == myId;
          bool myJobB = b['technician_id'] == myId;
          if (myJobA && !myJobB) return -1;
          if (!myJobA && myJobB) return 1;
          return 0; 
        });

        return Scaffold(
          backgroundColor: _bgColor,
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_gradStart, _gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: _gradEnd.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    // Profile & Notifications
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.person, color: _gradEnd, size: 30))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tr('greeting'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              Text(supabase.auth.currentUser?.userMetadata?['full_name'] ?? tr('role'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(_isHeadTech ? tr('role_head') : tr('role'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () => _showNotificationSheet(notificationList),
                              icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 28),
                              style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                            ),
                            if (newJobCount > 0)
                              Positioned(
                                right: 8, top: 8,
                                child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: Text(newJobCount > 9 ? '9+' : '$newJobCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                              )
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Stats
                    Row(
                      children: [
                        _buildStatCard(newJobCount, tr('stat_new'), Colors.white, _colWait),
                        const SizedBox(width: 10),
                        _buildStatCard(fixingCount, tr('stat_fixing'), Colors.white, _colFix),
                        const SizedBox(width: 10),
                        _buildStatCard(totalDoneCount, tr('stat_done'), Colors.white, _colDone),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianHistoryScreen())), icon: Icon(Icons.history, color: _gradEnd), label: Text(tr('menu_history'), style: TextStyle(color: _gradEnd, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton.icon(onPressed: () => _showPerformanceSheet(doneDaily, doneWeekly, doneMonthly, totalDoneCount), icon: Icon(Icons.bar_chart, color: _colFix), label: Text(tr('menu_summary'), style: TextStyle(color: _colFix, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                    if (_isHeadTech) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(onPressed: () => _showMaterialsSummarySheet(), icon: const Icon(Icons.inventory_2, color: Color(0xFFFF9800)), label: Text(tr('materials_summary'), style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton.icon(onPressed: () => _showTechniciansListSheet(), icon: const Icon(Icons.supervised_user_circle, color: Color(0xFF009688)), label: Text(tr('technicians_list'), style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                        ],
                      ),
                    ]
                  ],
                ),
              ),

              // 2. List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async { await Future.delayed(const Duration(seconds: 1)); setState(() {}); },
                  color: _gradEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(children: [Text(tr('list_header'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), const Spacer(), if (activeList.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), child: Text("${activeList.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))]),
                        const SizedBox(height: 15),
                        Expanded(child: !snapshot.hasData ? Center(child: CircularProgressIndicator(color: _gradEnd)) : activeList.isEmpty ? _buildEmptyState() : ListView.separated(padding: const EdgeInsets.only(bottom: 20), itemCount: activeList.length, separatorBuilder: (c, i) => const SizedBox(height: 15), itemBuilder: (context, index) => _buildVibrantJobCard(activeList[index], myId))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
            child: BottomNavigationBar(currentIndex: _selectedIndex, onTap: (index) { if (index == 1) {
              _showMoreMenu();
            } else {
              setState(() => _selectedIndex = index);
            } }, backgroundColor: Colors.white, elevation: 0, selectedItemColor: _gradEnd, unselectedItemColor: Colors.grey[400], showUnselectedLabels: true, items: [BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: tr('nav_home')), BottomNavigationBarItem(icon: const Icon(Icons.grid_view_rounded), label: tr('nav_more'))]),
          ),
        );
      },
    );
  }

  // --- Widgets ---

  void _showNotificationSheet(List<Map<String, dynamic>> jobNotis) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: _gradEnd,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _gradEnd.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.campaign_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(tr('tab_news')),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_active_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(tr('tab_noti')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: TabBarView(children: [_buildNewsTab(), _buildJobNotiTab(jobNotis)])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
        .from('announcements')
        .select()
        .or('target_group.eq.all,target_group.eq.technician')
        .order('created_at', ascending: false)
        .limit(10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _gradEnd));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyStateInSheet();
        final news = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          itemCount: news.length,
          itemBuilder: (context, index) {
            final item = news[index];
            final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['created_at']));
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(left: BorderSide(color: Colors.blue.shade400, width: 4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.article_rounded, color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'ประกาศ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  date,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['content'] ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildJobNotiTab(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _buildEmptyStateInSheet();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isNew = item['status'] == 'approved';
        final statusColor = isNew ? Colors.orange : Colors.green;
        final statusBgColor = isNew ? Colors.orange.shade50 : Colors.green.shade50;
        final statusText = isNew ? tr('noti_new_job') : tr('noti_completed');
        final categoryText = item['category'] ?? 'ซ่อมแซม';
        final locationText = "${item['dorm_building'] ?? ''} ${item['room_number'] ?? ''}".trim();
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isNew ? 3 : 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  isNew ? Colors.orange.shade50 : Colors.green.shade50,
                  isNew ? Colors.orange.shade100 : Colors.green.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(left: BorderSide(color: statusColor.shade400, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(8)),
                        child: Icon(
                          isNew ? Icons.notifications_active_rounded : Icons.task_alt_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: statusColor.shade700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              categoryText,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(6)),
                          child: const Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            locationText,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () { Navigator.pop(context); if (isNew) _showJobDetailDialog(item, false); },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tr('btn_view_detail'),
                            style: TextStyle(fontSize: 12, color: statusColor.shade700, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: statusColor.shade700),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateInSheet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.inbox_rounded, size: 60, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              tr('noti_empty'),
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ไม่มีข้อมูลในขณะนี้',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showPerformanceSheet(int daily, int weekly, int monthly, int total) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) {
      return Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 20),
        Text(tr('summary_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        Row(children: [_buildSummaryItem(tr('sum_daily'), daily, Colors.orange.shade100, Colors.orange), const SizedBox(width: 15), _buildSummaryItem(tr('sum_weekly'), weekly, Colors.blue.shade100, Colors.blue)]),
        const SizedBox(height: 15),
        Row(children: [_buildSummaryItem(tr('sum_monthly'), monthly, Colors.purple.shade100, Colors.purple), const SizedBox(width: 15), _buildSummaryItem(tr('sum_total'), total, Colors.green.shade100, Colors.green)]),
        const SizedBox(height: 20),
      ]));
    });
  }

  Widget _buildSummaryItem(String label, int count, Color bg, Color text) {
    return Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bg.withOpacity(0.5), borderRadius: BorderRadius.circular(20)), child: Column(children: [Text("$count", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: text)), Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: text.withOpacity(0.8)))])));
  }

  Widget _buildStatCard(int count, String label, Color bg, Color accent) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))]), child: Column(children: [Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent)), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600))])));
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]), const SizedBox(height: 15), Text(tr('empty_title'), style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500))]));
  }

  Widget _buildVibrantJobCard(Map<String, dynamic> ticket, String? myId) {
    String status = ticket['status'] ?? '';
    bool isMine = ticket['technician_id'] == myId;
    bool isUrgent = (ticket['description'] ?? '').toString().contains('ด่วน');
    Color themeColor = status == 'approved' ? _colWait : _colFix;
    String statusText = status == 'approved' ? tr('status_wait') : tr('status_fixing');
    IconData statusIcon = status == 'approved' ? Icons.hourglass_empty_rounded : Icons.handyman_rounded;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () => _showJobDetailDialog(ticket, isMine), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(statusIcon, color: themeColor, size: 26)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(_getCategoryDisplay(ticket['category'] ?? '-'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87), maxLines: 1)), if (isUrgent) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _colUrgent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(tr('urgent'), style: TextStyle(color: _colUrgent, fontSize: 10, fontWeight: FontWeight.bold)))]), const SizedBox(height: 4), Row(children: [Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Expanded(child: Text("${ticket['dorm_building']} / ${ticket['room_number']}", style: TextStyle(fontSize: 14, color: Colors.grey[600]), maxLines: 1))]),]))]),
        const SizedBox(height: 15), Divider(height: 1, color: Colors.grey[200]), const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(statusText, style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold))), Row(children: [Text(isMine ? "จัดการงาน" : "ดูรายละเอียด", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _gradEnd)), const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 16, color: _gradEnd)])])
      ])))),
    );
  }

  // --- Dialogs & Functions ---

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _handlePhotoUpload(dynamic ticketId, {bool isBefore = false}) async {
    final xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (xfile == null) return;
    if(mounted) _showNotification(tr('uploading'), isError: false);
    final fileName = 'job_${ticketId}_${isBefore ? "before" : "after"}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await supabase.storage.from('job_evidence').upload(fileName, File(xfile.path));
      final url = supabase.storage.from('job_evidence').getPublicUrl(fileName);
      if (isBefore) await _updateStatus(ticketId, 'in_progress', null, beforeImageUrl: url);
    } catch(e) { debugPrint("Error: $e"); }
  }

  void _showJobDetailDialog(Map<String, dynamic> ticket, bool isMine) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) {
      return DraggableScrollableSheet(initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (_, controller) {
        return SingleChildScrollView(controller: controller, padding: const EdgeInsets.fromLTRB(24, 10, 24, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 25),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(tr('detail_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), tooltip: tr('btn_close'))]), const SizedBox(height: 20),
          if (ticket['image_url'] != null) ...[ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(ticket['image_url'], width: double.infinity, height: 200, fit: BoxFit.cover)), const SizedBox(height: 15)],
          if (ticket['started_image_url'] != null) ...[const Text("รูปก่อนซ่อม (Before):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(ticket['started_image_url'], width: double.infinity, height: 200, fit: BoxFit.cover)), const SizedBox(height: 15)],
          
          // FEATURE: Appointment Info
          if (ticket['appointment_date'] != null) ...[
            Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)), child: Row(children: [const Icon(Icons.event, color: Colors.blue), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('appt_label'), style: const TextStyle(fontSize: 12, color: Colors.blue)), Text(_formatDateTime(ticket['appointment_date']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16))])])),
          ],

          _buildDetailRow(Icons.category_outlined, tr('cat_label'), _getCategoryDisplay(ticket['category'])), _buildDetailRow(Icons.notes_outlined, tr('desc_label'), ticket['description']),
          Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.place_outlined, size: 22, color: _gradEnd), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('loc_label'), style: const TextStyle(fontSize: 12, color: Colors.grey)), Row(children: [Expanded(child: Text("${ticket['dorm_building']} / ${ticket['room_number']}", style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)))])]))])),
          Container(margin: const EdgeInsets.symmetric(vertical: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(15)), child: Row(children: [const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.grey)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('contact_label'), style: const TextStyle(fontSize: 12, color: Colors.grey)), Text("${ticket['contact_name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])), IconButton(onPressed: () => _makePhoneCall(ticket['contact_phone'] ?? ''), icon: const Icon(Icons.phone), color: Colors.green)])),
          const SizedBox(height: 25),

          // FEATURE: Materials Section (สำหรับหัวหน้าช่าง)
          if (_isHeadTech) ...[
            const Divider(height: 30),
            const Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.black87),
                SizedBox(width: 8),
                Text('อุปกรณ์ที่เบิก:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase.from('materials_tracking').select().eq('ticket_id', ticket['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('ยังไม่มีการบันทึกอุปกรณ์', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                  );
                }
                final materials = snapshot.data!;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: materials.length,
                  separatorBuilder: (c, i) => Divider(color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final mat = materials[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
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
                          if (mat['notes'] != null && mat['notes'].isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('หมายเหตุ: ${mat['notes']}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 25),
          ],
          
          if (ticket['status'] == 'approved') SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _updateStatus(ticket['id'], 'in_progress', ticket['user_id']); }, icon: const Icon(Icons.handyman_rounded), label: Text(tr('btn_accept')), style: ElevatedButton.styleFrom(backgroundColor: _gradEnd, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
          
          if (ticket['status'] == 'in_progress') ...[
            // FEATURE: Appointment Button
            if (isMine) SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _handleAppointment(ticket['id']), icon: const Icon(Icons.calendar_month), label: Text(tr('appt_btn')), style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade700, padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.blue.shade700)))),
            if (isMine) const SizedBox(height: 12),

            // FEATURE: Materials Tracking Button
            if (isMine) SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => MaterialsTrackingScreen(ticketId: ticket['id'], ticketRoom: "${ticket['dorm_building']} ${ticket['room_number']}"))); }, icon: const Icon(Icons.inventory_2), label: Text('เบิกอุปกรณ์'), style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade700, padding: const EdgeInsets.symmetric(vertical: 12), side: BorderSide(color: Colors.orange.shade700)))),
            if (isMine) const SizedBox(height: 12),

            // Reassign button for head_tech
            if (_isHeadTech) SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); _reassignJob(ticket['id'], ticket['technician_name'] ?? 'Unassigned'); }, icon: const Icon(Icons.swap_calls), label: Text(tr('reassign')), style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Colors.teal)))),
            if (_isHeadTech) const SizedBox(height: 12),

            if (isMine && ticket['started_image_url'] == null) SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _handlePhotoUpload(ticket['id'], isBefore: true), icon: const Icon(Icons.camera_alt), label: Text(tr('btn_before_photo')), style: OutlinedButton.styleFrom(foregroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Colors.purple)))),
            if (isMine) const SizedBox(height: 12),
            if (isMine) SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showCompleteDialog(ticket); }, icon: const Icon(Icons.check_circle_outline), label: Text(tr('btn_finish')), style: ElevatedButton.styleFrom(backgroundColor: _colDone, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            if (isMine) const SizedBox(height: 12),
            if (isMine) SizedBox(width: double.infinity, child: TextButton(onPressed: () { Navigator.pop(context); _updateStatus(ticket['id'], 'approved', ticket['user_id'], isUnAccepting: true); }, child: Text(tr('btn_cancel_job'), style: TextStyle(color: _colUrgent)))),
            if (!isMine && !_isHeadTech) Center(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [Icon(Icons.warning_amber, color: Colors.grey[500], size: 18), Text('งานนี้กำลังดำเนินการโดยช่างท่านอื่น', style: TextStyle(color: Colors.grey[500]))])),    
          ],
          const SizedBox(height: 20),
        ]));
      });
    });
  }

  void _showCompleteDialog(Map<String, dynamic> ticket) {
    File? image;
    TextEditingController noteCtrl = TextEditingController();
    bool uploading = false;
    showDialog(context: context, barrierDismissible: false, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), contentPadding: const EdgeInsets.all(24), title: Text(tr('btn_finish'), style: const TextStyle(fontWeight: FontWeight.bold)), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [GestureDetector(onTap: () async { final xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50); if (xfile != null) setDialogState(() => image = File(xfile.path)); }, child: Container(height: 160, width: double.infinity, decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)), child: image == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]), Text(tr('tap_to_take_photo'), style: const TextStyle(color: Colors.grey))]) : ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(image!, fit: BoxFit.cover)))), const SizedBox(height: 16), TextField(controller: noteCtrl, decoration: InputDecoration(labelText: tr('repair_note_label'), hintText: tr('repair_note_hint'), border: const OutlineInputBorder(), filled: true, fillColor: Colors.white), maxLines: 2), if (uploading) ...[const SizedBox(height: 16), LinearProgressIndicator(color: _gradEnd), const SizedBox(height: 8), Text(tr('uploading'))]])), actions: [if(!uploading) TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey))), ElevatedButton(onPressed: uploading ? null : () async { if (image == null) { _showNotification(tr('photo_required'), isError: true); return; } setDialogState(() => uploading = true); final fileName = 'job_${DateTime.now().millisecondsSinceEpoch}.jpg'; await supabase.storage.from('job_evidence').upload(fileName, image!); final url = supabase.storage.from('job_evidence').getPublicUrl(fileName); if (mounted) Navigator.pop(context); await _updateStatus(ticket['id'], 'completed', ticket['user_id'], imageUrl: url, repairNote: noteCtrl.text); }, style: ElevatedButton.styleFrom(backgroundColor: _gradEnd, foregroundColor: Colors.white), child: Text(tr('confirm')))])));
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 22, color: _gradEnd), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value ?? "-", style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500))]))]));
  }

  Future<void> _showRoomHistory(String building, String room) async {
    final history = await supabase.from('tickets').select().eq('dorm_building', building).eq('room_number', room).eq('status', 'completed').order('created_at', ascending: false).limit(10); 
    if (!mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (c) => DraggableScrollableSheet(initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.9, expand: false, builder: (context, scrollController) { return Container(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20), Text("${tr('btn_room_history')}: $building $room", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Divider(), if (history.isEmpty) const Expanded(child: Center(child: Text("ยังไม่มีประวัติการซ่อม", style: TextStyle(color: Colors.grey)))), if (history.isNotEmpty) Expanded(child: ListView.separated(controller: scrollController, itemCount: history.length, separatorBuilder: (c, i) => Divider(color: Colors.grey[200]), itemBuilder: (context, index) { final item = history[index]; final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(item['created_at'])); return ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: _bgColor, child: const Icon(Icons.history, color: Colors.grey)), title: Text(item['category'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${item['description']} (${item['repair_note'] ?? '-'})"), trailing: Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12))); }))])); }));
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final sheetHeight = MediaQuery.of(context).size.height * 0.6;
          return Container(
            height: sheetHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gradStart, _gradEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.grid_view_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('more_menu'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentLanguageCode == 'th'
                                  ? 'ตั้งค่าและการช่วยเหลือ'
                                  : 'Settings and support',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildMoreMenuTile(
                        icon: Icons.notifications_outlined,
                        title: tr('notification'),
                        subtitle: _isNotificationEnabled ? tr('notification_on') : tr('notification_off'),
                        trailing: Switch.adaptive(
                          value: _isNotificationEnabled,
                          activeColor: _gradEnd,
                          onChanged: (val) {
                            setModalState(() => _isNotificationEnabled = val);
                            setState(() => _isNotificationEnabled = val);
                            _saveNotification(val);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildMoreMenuTile(
                        icon: Icons.language,
                        title: tr('language'),
                        subtitle: _currentLanguageCode == 'th' ? 'ไทย (TH)' : 'English (EN)',
                        onTap: () => _showLanguageSelectorWithRefresh(context, () => setModalState(() {})),
                      ),
                      const SizedBox(height: 10),
                      _buildMoreMenuTile(
                        icon: Icons.help_outline,
                        title: tr('help'),
                        onTap: () => _showHelpDialog(),
                      ),
                      const SizedBox(height: 10),
                      _buildMoreMenuTile(
                        icon: Icons.logout,
                        title: tr('logout_title'),
                        color: _colUrgent,
                        onTap: () {
                          Navigator.pop(context);
                          _handleLogout();
                        },
                      ),
                      const SizedBox(height: 20),
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

  Future<void> _showMaterialsSummarySheet() async {
    try {
      final materials = await supabase
          .from('materials_tracking')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      // Fetch technician names for each material
      Map<String, String> technicianNames = {};
      for (var material in materials) {
        final technician_id = material['technician_id'];
        if (technician_id != null && !technicianNames.containsKey(technician_id)) {
          try {
            final tech = await supabase
                .from('profiles')
                .select('full_name')
                .eq('id', technician_id)
                .single();
            technicianNames[technician_id] = tech['full_name'] ?? 'Unknown';
          } catch (e) {
            technicianNames[technician_id] = 'Unknown';
          }
        }
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          // Group materials by name for summary
          Map<String, int> materialSummary = {};
          for (var item in materials) {
            String name = item['material_name'] ?? 'Unknown';
            int quantity = (item['quantity'] ?? 0) as int;
            materialSummary[name] = (materialSummary[name] ?? 0) + quantity;
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, controller) {
              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
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
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('materials_summary'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          tooltip: tr('btn_close'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Summary Statistics
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              color: Colors.orange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('total_materials'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${materials.length} ${tr('materials_list')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      tr('materials_list'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (materials.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_rounded,
                                size: 60,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr('no_materials'),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: materials.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.grey[200],
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = materials[index];
                          final date = DateFormat('dd/MM/yyyy HH:mm').format(
                            DateTime.parse(item['created_at']),
                          );
                          final ticket = item['ticket_id'];
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['material_name'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${tr('material_technician')}: ${technicianNames[item['technician_id']] ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _gradEnd.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${item['quantity'] ?? 0}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _gradEnd,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if (item['notes'] != null &&
                                    item['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['notes'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      _showNotification('Error: $e', isError: true);
    }
  }

  Future<void> _showTechniciansListSheet() async {
    try {
      // Fetch all technicians
      final technicians = await supabase
          .from('profiles')
          .select()
          .eq('role', 'technician')
          .order('full_name', ascending: true);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, controller) {
              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
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
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('technicians_list'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          tooltip: tr('btn_close'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (technicians.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 60,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'ไม่มีข้อมูลช่างเทคนิค',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: technicians.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.grey[200],
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final tech = technicians[index];
                          final techId = tech['id'] as String;
                          
                          return FutureBuilder<Map<String, dynamic>>(
                            future: _getTechnicianStats(techId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final stats = snapshot.data!;
                              final activeJobs = stats['activeJobs'] as int;
                              final completedJobs = stats['completedJobs'] as int;
                              final avgRating = stats['avgRating'] as double;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showTechnicianDetailSheet(tech, stats);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: _gradEnd.withOpacity(0.2),
                                              child: Text(
                                                (tech['full_name'] as String?)
                                                        ?.substring(0, 1)
                                                        .toUpperCase() ?? 'T',
                                                style: TextStyle(
                                                  color: _gradEnd,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tech['full_name'] ?? 'Unknown',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        size: 14,
                                                        color: Colors.amber[700],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        avgRating.toStringAsFixed(1),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: activeJobs > 0
                                                              ? Colors
                                                                  .orange[100]
                                                              : Colors
                                                                  .green[100],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          activeJobs > 0
                                                              ? '$activeJobs ${tr('tech_active_jobs')}'
                                                              : 'ว่างงาน',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: activeJobs >
                                                                    0
                                                                ? Colors
                                                                    .orange[700]
                                                                : Colors
                                                                    .green[700],
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.grey[400],
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '✓ ${tr('tech_completed_jobs')}: $completedJobs',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      _showNotification('Error: $e', isError: true);
    }
  }

  Future<Map<String, dynamic>> _getTechnicianStats(String techId) async {
    try {
      // Get all tickets for this technician
      final allTickets = await supabase
          .from('tickets')
          .select()
          .eq('technician_id', techId);

      int activeJobs = 0;
      int completedJobs = 0;
      double totalRating = 0;
      int ratedJobs = 0;

      for (var ticket in allTickets) {
        final status = ticket['status'] as String? ?? '';
        if (status == 'approved' || status == 'in_progress') {
          activeJobs++;
        }
        if (status == 'completed') {
          completedJobs++;
          final rating = ticket['rating'];
          if (rating != null && rating > 0) {
            totalRating += (rating as num).toDouble();
            ratedJobs++;
          }
        }
      }

      final avgRating =
          ratedJobs > 0 ? totalRating / ratedJobs : 0.0;

      return {
        'activeJobs': activeJobs,
        'completedJobs': completedJobs,
        'avgRating': avgRating,
        'ratedJobs': ratedJobs,
        'allTickets': allTickets,
      };
    } catch (e) {
      debugPrint('Error getting technician stats: $e');
      return {
        'activeJobs': 0,
        'completedJobs': 0,
        'avgRating': 0.0,
        'ratedJobs': 0,
        'allTickets': [],
      };
    }
  }

  Future<void> _showTechnicianDetailSheet(
      Map<String, dynamic> technician,
      Map<String, dynamic> stats) async {
    try {
      final techId = technician['id'] as String;
      
      // Get active and completed jobs
      final activeJobsData = await supabase
          .from('tickets')
          .select()
          .eq('technician_id', techId)
          .inFilter('status', ['approved', 'in_progress'])
          .order('created_at', ascending: false);

      final completedJobsData = await supabase
          .from('tickets')
          .select()
          .eq('technician_id', techId)
          .eq('status', 'completed')
          .order('updated_at', ascending: false)
          .limit(5);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, controller) {
              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
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
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                technician['full_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${techId.substring(0, 8)}...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          tooltip: tr('btn_close'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.shade100),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      (stats['avgRating'] as double).toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(stats['ratedJobs'] as int)} ratings',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.assignment, color: Colors.orange.shade700, size: 20),
                                const SizedBox(height: 8),
                                Text(
                                  '${stats['activeJobs'] as int}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                const SizedBox(height: 8),
                                Text(
                                  '${stats['completedJobs'] as int}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Done',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    // Active Jobs Section
                    Text(
                      '${tr('tech_active_jobs')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (activeJobsData.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            tr('no_active_jobs'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeJobsData.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.grey[200],
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final job = activeJobsData[index];
                          final status = job['status'] as String? ?? '';
                          final statusColor = status == 'approved'
                              ? Colors.orange
                              : Colors.blue;
                          final statusText = status == 'approved'
                              ? tr('status_wait')
                              : tr('status_fixing');

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['category'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${job['dorm_building'] ?? ''} ${job['room_number'] ?? ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 25),
                    // Recent Completed Jobs & Feedback
                    Text(
                      '✓ ${tr('tech_completed_jobs')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (completedJobsData.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'ยังไม่มีงานที่เสร็จแล้ว',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: completedJobsData.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.grey[200],
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final job = completedJobsData[index];
                          final rating = job['rating'] ?? 0;
                          final comment = (job['rating_comment'] ?? '')
                              .toString()
                              .trim();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['category'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${job['dorm_building'] ?? ''} ${job['room_number'] ?? ''}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (rating > 0)
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            Icons.star,
                                            size: 14,
                                            color: i < rating
                                                ? Colors.amber.shade700
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.blue.shade100,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('tech_feedback'),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6),
                                    child: Text(
                                      tr('no_feedback'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      _showNotification('Error: $e', isError: true);
    }
  }

  void _showLanguageSelectorWithRefresh(BuildContext parentContext, VoidCallback onLanguageChanged) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (context, modalSetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gradStart, _gradEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.language, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('language'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentLanguageCode == 'th'
                                  ? 'เลือกภาษาในการใช้งาน'
                                  : 'Select app language',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  label: "ไทย (TH)",
                  value: "th",
                  setModalState: (fn) {
                    modalSetState(fn);
                    onLanguageChanged();
                  },
                  dialogContext: c,
                ),
                const SizedBox(height: 10),
                _buildLanguageOption(
                  label: "English (EN)",
                  value: "en",
                  setModalState: (fn) {
                    modalSetState(fn);
                    onLanguageChanged();
                  },
                  dialogContext: c,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final themeColor = color ?? _gradEnd;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: themeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String value,
    required void Function(VoidCallback fn) setModalState,
    required BuildContext dialogContext,
  }) {
    final isSelected = _currentLanguageCode == value;
    return InkWell(
      onTap: () {
        setState(() => _currentLanguageCode = value);
        _saveLanguage(value);
        setModalState(() {});
        Navigator.pop(dialogContext);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _gradEnd.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _gradEnd : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: isSelected ? _gradEnd : Colors.grey[400],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _gradEnd : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Widget? trailing, Color? color, VoidCallback? onTap}) { final themeColor = color ?? Colors.blueGrey; return ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: themeColor, size: 20)), title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: themeColor)), trailing: trailing ?? const Icon(Icons.chevron_right, size: 20, color: Colors.grey), onTap: onTap); }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_gradStart, _gradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.hourglass_empty_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('coming_soon_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('coming_soon_msg'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(c),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gradEnd,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(tr('ok')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_gradStart, _gradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('logout_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('logout_confirm'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(c, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(tr('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colUrgent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(tr('logout_title')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm == true) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}