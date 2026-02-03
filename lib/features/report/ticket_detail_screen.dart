import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TicketDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final String languageCode;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
    this.languageCode = 'th',
  });

  // 🔥 เพิ่มคำแปลสถานะ Rejected และ Step การปฏิเสธงาน
  final Map<String, Map<String, String>> _translations = const {
    'th': {
      'title': 'รายละเอียดงานซ่อม',
      'category': 'หมวดหมู่',
      'location': 'สถานที่',
      'room': 'ห้อง',
      'time': 'เวลาแจ้ง',
      'desc': 'รายละเอียด',
      'status_title': 'สถานะดำเนินการ',
      'step_reported': 'แจ้งซ่อมแล้ว',
      'step_reported_desc': 'ระบบได้รับข้อมูลเรียบร้อย',
      'step_progress': 'กำลังดำเนินการ',
      'step_progress_desc': 'ช่างกำลังตรวจสอบ/แก้ไข',
      'step_done': 'เสร็จสิ้น',
      'step_done_desc': 'การซ่อมเสร็จสมบูรณ์',
      'step_rejected': 'คำขอถูกปฏิเสธ', // 🔥 เพิ่ม
      'step_rejected_desc': 'งานซ่อมนี้ไม่ผ่านการอนุมัติ', // 🔥 เพิ่ม
      'status_pending': 'รอเจ้าหน้าที่',
      'status_approved': 'รับเรื่องแล้ว',
      'status_repairing': 'กำลังซ่อม',
      'status_completed': 'เสร็จสิ้น',
      'status_rejected': 'ไม่อนุมัติ', // 🔥 เพิ่ม
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
    },
    'en': {
      'title': 'Ticket Details',
      'category': 'Category',
      'location': 'Location',
      'room': 'Room',
      'time': 'Time Reported',
      'desc': 'Description',
      'status_title': 'Status Timeline',
      'step_reported': 'Reported',
      'step_reported_desc': 'System received your request',
      'step_progress': 'In Progress',
      'step_progress_desc': 'Technician is working',
      'step_done': 'Completed',
      'step_done_desc': 'Repair is finished',
      'step_rejected': 'Request Rejected', // 🔥 Added
      'step_rejected_desc': 'This request was not approved', // 🔥 Added
      'status_pending': 'Pending',
      'status_approved': 'Approved',
      'status_repairing': 'In Progress',
      'status_completed': 'Completed',
      'status_rejected': 'Rejected', // 🔥 Added
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
    },
  };

  String tr(String key) => _translations[languageCode]?[key] ?? key;

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

  // 🔥 เพิ่มสีแดงสำหรับ Rejected
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.purple;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red; // 🔥 สีแดง
      default:
        return Colors.orange;
    }
  }

  // 🔥 เพิ่มข้อความสถานะ Rejected
  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return tr('status_approved');
      case 'in_progress':
        return tr('status_repairing');
      case 'completed':
        return tr('status_completed');
      case 'rejected':
        return tr('status_rejected'); // 🔥 ข้อความไม่อนุมัติ
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
    final status = ticket['status'] as String? ?? 'pending';
    final rawCategory = ticket['category'] as String? ?? 'ทั่วไป';
    final category = _getDisplayCategory(rawCategory);
    final description = ticket['description'] as String? ?? '-';
    final roomNumber = ticket['room_number'] as String? ?? tr('unspecified');
    final createdAt = ticket['created_at'] as String?;
    final id = ticket['id'];

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

            // 🔥 Timeline Section (ปรับปรุงให้รองรับ Rejected)
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
                    // 🔥 กรณีถูกปฏิเสธ: แสดง Step สีแดง
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
            const SizedBox(height: 40),
          ],
        ),
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

  // 🔥 ปรับ Timeline ให้รับสีและไอคอนได้
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
}
