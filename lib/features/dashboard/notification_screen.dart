import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.parse(dateStr).toLocal();
    return DateFormat('d MMM HH:mm').format(dt);
  }

  // 🔥 ฟังก์ชันอ่านทั้งหมด
  Future<void> _markAllAsRead() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
      setState(() {}); // รีเฟรชหน้าจอ
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("อ่านทั้งหมดแล้ว")));
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  // 🔥 ฟังก์ชันลบทั้งหมด
  Future<void> _deleteAll() async {
    // ถามยืนยันก่อนลบ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: const Text("คุณต้องการลบการแจ้งเตือนทั้งหมดใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("ลบทั้งหมด", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase.from('notifications').delete().eq('user_id', userId);
      setState(() {}); // รีเฟรชหน้าจอ
    } catch (e) {
      debugPrint('Error deleting all: $e');
    }
  }

  // 🔥 ฟังก์ชันลบทีละอัน
  Future<void> _deleteSingle(int id) async {
    try {
      await supabase.from('notifications').delete().eq('id', id);
      // ไม่ต้อง setState เพราะ Dismissible ลบ UI ออกให้แล้ว
    } catch (e) {
      debugPrint('Error deleting item: $e');
      setState(() {}); // โหลดใหม่ถ้าลบพลาด
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("การแจ้งเตือน"),
        backgroundColor: const Color(0xFFA51C30),
        foregroundColor: Colors.white,
        actions: [
          // ปุ่มอ่านทั้งหมด
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "อ่านทั้งหมด",
            onPressed: _markAllAsRead,
          ),
          // ปุ่มลบทั้งหมด
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "ลบทั้งหมด",
            onPressed: _deleteAll,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "ไม่มีการแจ้งเตือน",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifs = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: notifs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = notifs[index];
              final isRead = item['is_read'] ?? false;

              // 🔥 ใช้ Dismissible เพื่อให้เลื่อนลบได้
              return Dismissible(
                key: Key(item['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteSingle(item['id']);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isRead
                        ? Colors.white
                        : Colors.white, // หรือจะเปลี่ยนสีพื้นหลังถ้ายังไม่อ่าน
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRead
                          ? Colors.grey.shade200
                          : const Color(0xFFA51C30).withOpacity(0.3),
                      width: isRead ? 1 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isRead
                          ? Colors.grey.withOpacity(0.1)
                          : const Color(0xFFA51C30).withOpacity(0.1),
                      child: Icon(
                        Icons.notifications,
                        color: isRead ? Colors.grey : const Color(0xFFA51C30),
                      ),
                    ),
                    title: Text(
                      item['title'] ?? '',
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['message'] ?? ''),
                        const SizedBox(height: 5),
                        Text(
                          _formatDate(item['created_at']),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    // จุดแดงเล็กๆ ถ้ายังไม่อ่าน
                    trailing: !isRead
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
