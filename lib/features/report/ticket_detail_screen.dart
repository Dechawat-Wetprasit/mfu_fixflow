import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final String languageCode;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
    this.languageCode = 'th',
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final supabase = Supabase.instance.client;
  late Map<String, dynamic> _ticket;

  // FEATURE: เพิ่มคำแปลสถานะ Rejected และ Step การปฏิเสธงาน
  final Map<String, Map<String, String>> _translations = const {
    'th': {
      'title': 'รายละเอียดงานซ่อม',
      'category': 'หมวดหมู่',
      'location': 'สถานที่',
      'room': 'ห้อง',
      'time': 'เวลาแจ้ง',
      'desc': 'รายละเอียด',
      'cancel': 'ยกเลิก',
      'status_title': 'สถานะดำเนินการ',
      'step_reported': 'แจ้งซ่อมแล้ว',
      'step_reported_desc': 'ระบบได้รับข้อมูลเรียบร้อย',
      'step_progress': 'กำลังดำเนินการ',
      'step_progress_desc': 'ช่างกำลังตรวจสอบ/แก้ไข',
      'step_done': 'เสร็จสิ้น',
      'step_done_desc': 'การซ่อมเสร็จสมบูรณ์',
      'step_rejected': 'คำขอถูกปฏิเสธ', // FEATURE: Added
      'step_rejected_desc': 'งานซ่อมนี้ไม่ผ่านการอนุมัติ', // FEATURE: Added
      'status_pending': 'รอเจ้าหน้าที่',
      'status_approved': 'รับเรื่องแล้ว',
      'status_repairing': 'กำลังซ่อม',
      'status_completed': 'เสร็จสิ้น',
      'status_rejected': 'ไม่อนุมัติ', // FEATURE: Added
      'id': 'Ticket ID',
      'general': 'ทั่วไป',
      'unspecified': 'ไม่ระบุ',
      'cat_general': 'แจ้งซ่อมทั่วไป',
      'cat_water': 'ประปา',
      'cat_electric': 'ไฟฟ้า',
      'cat_ac': 'แอร์',
      'cat_furniture': 'เฟอร์นิเจอร์',
      'cat_internet': 'อินเทอร์เน็ต',
      'cat_other': 'อื่นๆ',
      'appointment': 'นัดหมายจากช่าง',
      'appointment_date': 'วันที่นัดหมาย',
      'appointment_time': 'เวลา',
      'no_appointment': 'ยังไม่มีการนัดหมาย',
      'assigned_to': 'ผู้รับผิดชอบ',
      'manager': 'ผู้จัดการหอพัก',
      'technician': 'ช่าง',
      'no_manager': 'ยังไม่มีการแต่งตั้ง',
      'no_technician': 'ยังไม่มีการแต่งตั้ง',
      'rating_title': 'ให้คะแนนงานซ่อม',
      'rating_hint': 'บอกประสบการณ์สั้นๆ (ไม่บังคับ)',
      'rating_submit': 'ส่งคะแนน',
      'rating_required': 'กรุณาให้คะแนนก่อน',
      'rating_thanks': 'ขอบคุณสำหรับคะแนนของคุณ',
      'rated': 'ให้คะแนนแล้ว',
      'cancel_job': 'ยกเลิกงาน',
      'cancel_confirm': 'ยืนยันการยกเลิก',
      'cancel_confirm_msg': 'คุณแน่ใจว่าต้องการยกเลิกงานนี้? (สามารถยกเลิกได้เฉพาะงานที่รอเจ้าหน้าที่เท่านั้น)',
    },
    'en': {
      'title': 'Ticket Details',
      'category': 'Category',
      'location': 'Location',
      'room': 'Room',
      'time': 'Time Reported',
      'desc': 'Description',
      'cancel': 'Cancel',
      'status_title': 'Status Timeline',
      'step_reported': 'Reported',
      'step_reported_desc': 'System received your request',
      'step_progress': 'In Progress',
      'step_progress_desc': 'Technician is working',
      'step_done': 'Completed',
      'step_done_desc': 'Repair is finished',
      'step_rejected': 'Request Rejected', // FEATURE: Added
      'step_rejected_desc': 'This request was not approved', // FEATURE: Added
      'status_pending': 'Pending',
      'status_approved': 'Approved',
      'status_repairing': 'In Progress',
      'status_completed': 'Completed',
      'status_rejected': 'Rejected', // FEATURE: Added
      'id': 'Ticket ID',
      'general': 'General',
      'unspecified': 'Unspecified',
      'cat_general': 'General Repair',
      'cat_water': 'Plumbing',
      'cat_electric': 'Electrical',
      'cat_ac': 'Air Conditioner',
      'cat_furniture': 'Furniture',
      'cat_internet': 'Internet',
      'cat_other': 'Other',
      'appointment': 'Technician Appointment',
      'appointment_date': 'Appointment Date',
      'appointment_time': 'Time',
      'no_appointment': 'No appointment scheduled yet',
      'assigned_to': 'Assigned To',
      'manager': 'Dorm Manager',
      'technician': 'Technician',
      'no_manager': 'Not assigned yet',
      'no_technician': 'Not assigned yet',
      'rating_title': 'Rate this repair',
      'rating_hint': 'Share a short note (optional)',
      'rating_submit': 'Submit rating',
      'rating_required': 'Please select a rating',
      'rating_thanks': 'Thanks for your rating',
      'rated': 'Rated',      'cancel_job': 'Cancel Job',
      'cancel_confirm': 'Confirm Cancellation',
      'cancel_confirm_msg': 'Are you sure you want to cancel this job? (Only pending jobs can be cancelled)',    },
  };

  @override
  void initState() {
    super.initState();
    _ticket = Map<String, dynamic>.from(widget.ticket);
  }

  String tr(String key) => _translations[widget.languageCode]?[key] ?? key;

  String _getDisplayCategory(String? rawCategory) {
    if (rawCategory == null) return tr('cat_general');
    if (rawCategory == 'แจ้งซ่อมทั่วไป' || rawCategory.contains('General')) {
      return tr('cat_general');
    }
    if (rawCategory.contains('ประปา') ||
        rawCategory.contains('Water') ||
        rawCategory.contains('Plumbing')) {
      return tr('cat_water');
    }
    if (rawCategory.contains('ไฟฟ้า') || rawCategory.contains('Electric')) {
      return tr('cat_electric');
    }
    if (rawCategory.contains('แอร์') || rawCategory.contains('Air')) {
      return tr('cat_ac');
    }
    if (rawCategory.contains('เฟอร์นิเจอร์') ||
        rawCategory.contains('Furniture')) {
      return tr('cat_furniture');
    }
    if (rawCategory.contains('เน็ต') || rawCategory.contains('Internet')) {
      return tr('cat_internet');
    }
    return tr(rawCategory);
  }

  // FEATURE: เพิ่มสีแดงสำหรับ Rejected
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.purple;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red; // Red color for rejected status
      default:
        return Colors.orange;
    }
  }

  // FEATURE: เพิ่มข้อความสถานะ Rejected
  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return tr('status_approved');
      case 'in_progress':
        return tr('status_repairing');
      case 'completed':
        return tr('status_completed');
      case 'rejected':
        return tr('status_rejected'); // Rejected status message
      default:
        return tr('status_pending');
    }
  }

  IconData _getCategoryIcon(String? category) {
    if (category == null) return Icons.build;
    if (category.contains('ประปา') || category.contains('Water')) {
      return Icons.water_drop;
    }
    if (category.contains('ไฟฟ้า') || category.contains('Electric')) {
      return Icons.bolt;
    }
    if (category.contains('แอร์') || category.contains('Air')) {
      return Icons.ac_unit;
    }
    if (category.contains('เฟอร์นิเจอร์') || category.contains('Furniture')) {
      return Icons.chair;
    }
    if (category.contains('เน็ต') || category.contains('Internet')) {
      return Icons.wifi;
    }
    return Icons.build;
  }

  @override
  Widget build(BuildContext context) {
    final status = _ticket['status'] as String? ?? 'pending';
    final rawCategory = _ticket['category'] as String? ?? 'ทั่วไป';
    final category = _getDisplayCategory(rawCategory);
    final description = _ticket['description'] as String? ?? '-';
    final roomNumber = _ticket['room_number'] as String? ?? tr('unspecified');
    final createdAt = _ticket['created_at'] as String?;
    final id = _ticket['id'];

    final Color color = _getStatusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          tr('title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(rawCategory),
                      size: 50,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${tr('id')}: #${(id ?? 0).toString().padLeft(6, '0')}",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Information Section
            Text(
              tr('title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.category_outlined,
                    tr('category'),
                    category,
                  ),
                  const Divider(height: 1),
                  _buildDetailRow(
                    Icons.room_outlined,
                    tr('location'),
                    "${tr('room')} $roomNumber",
                  ),
                  const Divider(height: 1),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    tr('time'),
                    _formatDate(createdAt),
                  ),
                  const Divider(height: 1),
                  _buildDetailRow(
                    Icons.description_outlined,
                    tr('desc'),
                    description,
                    isMultiLine: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Assigned Staff Section
            Text(
              tr('assigned_to'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildStaffRow(
                    Icons.person_outline,
                    tr('manager'),
                    _ticket['manager_name'] as String?,
                  ),
                  const Divider(height: 20),
                  _buildStaffRow(
                    Icons.engineering,
                    tr('technician'),
                    _ticket['technician_name'] as String?,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Appointment Section (if status is approved or in_progress)
            if (status == 'approved' || status == 'in_progress' || status == 'completed')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('appointment'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: _buildAppointmentSection(_ticket),
                  ),
                  const SizedBox(height: 25),
                ],
              ),

            // FEATURE: Timeline Section (ปรับปรุงให้รองรับ Rejected)
            Text(
              tr('status_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  _buildTimelineStep(
                    tr('step_reported'),
                    tr('step_reported_desc'),
                    true, // Always active
                    true,
                    Colors.green,
                  ),
                  if (status == 'rejected') ...[
                    // FEATURE: กรณีถูกปฏิเสธ: แสดง Step สีแดง
                    _buildTimelineStep(
                      tr('step_rejected'),
                      tr('step_rejected_desc'),
                      true,
                      false, // No line after this
                      Colors.red, // สีแดง
                      icon: Icons.cancel,
                    ),
                  ] else ...[
                    // กรณีปกติ
                    _buildTimelineStep(
                      tr('step_progress'),
                      tr('step_progress_desc'),
                      status == 'in_progress' || status == 'completed',
                      true,
                      Colors.blue,
                    ),
                    _buildTimelineStep(
                      tr('step_done'),
                      tr('step_done_desc'),
                      status == 'completed',
                      false,
                      Colors.green,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 25),

            if (status == 'completed')
              _buildRatingSection(),

            // Cancel button for pending jobs
            if (status == 'pending')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showCancelConfirmDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cancel_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tr('cancel_job'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  int _parseRating(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return 0;
  }

  Widget _buildRatingSection() {
    final rating = _parseRating(_ticket['rating']);
    final comment = _ticket['rating_comment']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                tr('rating_title'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rating > 0)
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  size: 18,
                  color: index < rating ? Colors.amber : Colors.grey[300],
                ),
              ),
            )
          else
            Text(
              tr('rating_required'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: rating > 0
                ? OutlinedButton(
                    onPressed: null,
                    child: Text(tr('rated')),
                  )
                : ElevatedButton(
                    onPressed: _showRatingSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                    ),
                    child: Text(tr('rating_submit')),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 48,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                tr('cancel_confirm'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                tr('cancel_confirm_msg'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              
              // Buttons Row
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.grey[50],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        tr('cancel'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Confirm Cancel Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _cancelTicket();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            tr('cancel_job'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
  }

  Future<void> _cancelTicket() async {
    try {
      final ticketId = _ticket['id'];

      // Delete the ticket
      await supabase.from('tickets').delete().eq('id', ticketId);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          Navigator.pop(context);
          return false;
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon with Animation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              
              // Success Message
              Text(
                'ยกเลิกสำเร็จ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'งานซ่อมนี้ถูกยกเลิกแล้ว',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRatingSheet() async {
    int rating = _parseRating(_ticket['rating']);
    final commentController = TextEditingController(
      text: _ticket['rating_comment']?.toString() ?? '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('rating_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setModalState(() => rating = index + 1),
                    icon: Icon(
                      Icons.star,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: tr('rating_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('rating_required'))),
                      );
                      return;
                    }
                    await supabase.from('tickets').update({
                      'rating': rating,
                      'rating_comment': commentController.text.trim(),
                      'rated_at': DateTime.now().toIso8601String(),
                    }).eq('id', _ticket['id']);

                    if (!mounted) return;
                    setState(() {
                      _ticket['rating'] = rating;
                      _ticket['rating_comment'] = commentController.text.trim();
                      _ticket['rated_at'] = DateTime.now().toIso8601String();
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('rating_thanks'))),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(tr('rating_submit')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffRow(
    IconData icon,
    String label,
    String? value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value != null && value.isNotEmpty ? value : tr('no_manager'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value != null && value.isNotEmpty ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[400], size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: isMultiLine ? 10 : 1,
                  overflow: isMultiLine
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FEATURE: ปรับ Timeline ให้รับสีและไอคอนได้
  Widget _buildTimelineStep(
    String title,
    String subtitle,
    bool isActive,
    bool hasLine,
    Color activeColor, {
    IconData icon = Icons.check,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? activeColor : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: isActive
                  ? Icon(icon, size: 14, color: Colors.white)
                  : null,
            ),
            if (hasLine)
              Container(
                width: 2,
                height: 40,
                color: isActive ? activeColor : Colors.grey[300]!,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isActive ? Colors.black : Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy, HH:mm น.').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildAppointmentSection(Map<String, dynamic> ticket) {
    final appointmentDate = ticket['appointment_date'] as String?;
    final appointmentTime = ticket['appointment_time'] as String?;

    // ถ้าไม่มีข้อมูลนัดหมาย
    if (appointmentDate == null || appointmentDate.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 15),
          Text(
            tr('no_appointment'),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr('appointment_date'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateOnly(appointmentDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (appointmentTime != null && appointmentTime.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tr('appointment_time'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appointmentTime,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatDateOnly(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy', widget.languageCode).format(date);
    } catch (e) {
      return dateStr;
    }
  }
}