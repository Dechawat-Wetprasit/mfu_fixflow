import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_fixflow/features/report/report_screen.dart';
import 'package:mfu_fixflow/features/report/ticket_detail_screen.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  String _displayName = "Loading...";
  String _roomNumber = "";
  OverlayEntry? _topBannerEntry;
  AnimationController? _topBannerController;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return tr('greeting_morning');
    } else if (hour >= 12 && hour < 17) {
      return tr('greeting_afternoon');
    } else if (hour >= 17 && hour < 21) {
      return tr('greeting_evening');
    } else {
      return tr('greeting_night');
    }
  }

  late AnimationController _animationController;
  int _selectedIndex = 0;

  String _currentLanguageCode = 'th';

  final Map<String, Map<String, String>> _translations = {
    'th': {
      'hello': 'HELLO',
      'guest': 'ผู้เยี่ยมชม (Guest)',
      'login': 'เข้าสู่ระบบ',
      'logout_confirm_title': 'ยืนยัน',
      'logout_confirm_msg': 'ต้องการออกจากระบบใช่หรือไม่?',
      'cancel': 'ยกเลิก',
      'exit': 'ออก',
      'greeting_morning': 'สวัสดีตอนเช้า',
      'greeting_afternoon': 'สวัสดีตอนบ่าย',
      'greeting_evening': 'สวัสดีตอนเย็น',
      'greeting_night': 'สวัสดีตอนค่ำ',
      // Status Translation
      'pending': 'รอดำเนินการ',
      'repairing': 'กำลังซ่อม',
      'completed': 'เสร็จสิ้น',
      'rejected': 'ไม่อนุมัติ',
      'status_approved': 'รับเรื่องแล้ว',
      'latest_jobs': 'งานซ่อมล่าสุด',
      'no_jobs': 'ยังไม่มีรายการแจ้งซ่อมเร็วๆ นี้',
      'login_alert': 'กรุณาเข้าสู่ระบบเพื่อดูรายการ',
      'main_menu': 'เมนูหลัก (Main Menu)',
      'news': 'ประกาศ (News)',
      'no_news': 'ยังไม่มีประกาศข่าวสาร',
      'menu_repair': 'แจ้งซ่อม',
      'menu_room_log': 'ประวัติห้อง',
      'menu_contact': 'ติดต่อ จนท.',
      'menu_rules': 'กฎหอพัก',
      'nav_home': 'หน้าหลัก',
      'nav_more': 'เพิ่มเติม',
      'more_menu': 'เมนูเพิ่มเติม',
      'profile_info': 'ข้อมูลส่วนตัว',
      'profile_desc': 'ดูและแก้ไขข้อมูลผู้แจ้ง',
      'notification': 'การแจ้งเตือน',
      'notification_on': 'เปิดใช้งาน',
      'notification_off': 'ปิดใช้งาน',
      'language': 'เปลี่ยนภาษา',
      'help': 'ช่วยเหลือ & สนับสนุน',
      'logout': 'ออกจากระบบ',
      'save_success': 'บันทึกข้อมูลเรียบร้อย',
      'save': 'บันทึก',
      'contact_staff': 'ติดต่อเจ้าหน้าที่',
      'coming_soon_title': 'Coming soon',
      'coming_soon_msg': 'ฟีเจอร์นี้จะเปิดใช้งานเร็วๆ นี้',

      'ok': 'ตกลง',
      'dorm_hint': 'หอพัก / ห้อง',
      'phone_hint': 'เบอร์โทรศัพท์',
      'name_hint': 'ชื่อ-นามสกุล',
      'no_logs': 'ไม่พบประวัติการซ่อมบำรุงของห้องนี้',
      'cat_general': 'แจ้งซ่อมทั่วไป',
      'cat_water': 'ประปา (น้ำรั่ว/ไม่ไหล)',
      'cat_electric': 'ไฟฟ้า (หลอดขาด/ไฟดับ)',
      'cat_ac': 'เครื่องปรับอากาศ',
      'cat_furniture': 'เฟอร์นิเจอร์/อุปกรณ์',
      'cat_internet': 'อินเทอร์เน็ต/Wifi',
      'cat_other': 'อื่นๆ',
      'my_technician': 'ช่างของฉัน',
      'no_technician': 'ยังไม่มีช่างรับงาน',
      'tech_active': 'งานกำลังดำเนินการ',
      'tech_completed': 'งานเสร็จแล้ว',
      'rate_now': 'ให้คะแนน',
      'rated': 'ให้คะแนนแล้ว',
      'rating_title': 'ให้คะแนนงานซ่อม',
      'rating_hint': 'บอกประสบการณ์สั้นๆ (ไม่บังคับ)',
      'rating_submit': 'ส่งคะแนน',
      'rating_required': 'กรุณาให้คะแนนก่อน',
      'rating_thanks': 'ขอบคุณสำหรับคะแนนของคุณ',
      'view_detail': 'ดูรายละเอียด',
      'mark_all_read': 'อ่านทั้งหมด',
      'no_notification': 'ไม่มีการแจ้งเตือน',
      'noti_system_update': 'ระบบจะแจ้งเตือนเมื่อมีการอัปเดตงานซ่อม',
      'loading': 'กำลังโหลด...',
    },
    'en': {
      'hello': 'HELLO',
      'guest': 'Guest',
      'login': 'Login',
      'logout_confirm_title': 'Confirm',
      'logout_confirm_msg': 'Do you want to logout?',
      'cancel': 'Cancel',
      'exit': 'Logout',
      'greeting_morning': 'Good Morning',
      'greeting_afternoon': 'Good Afternoon',
      'greeting_evening': 'Good Evening',
      'greeting_night': 'Good Night',
      // Status Translation
      'pending': 'Pending',
      'repairing': 'In Progress',
      'completed': 'Completed',
      'rejected': 'Rejected',
      'status_approved': 'Approved',
      'latest_jobs': 'Recent Tickets',
      'no_jobs': 'No recent tickets found',
      'login_alert': 'Please login to view tickets',
      'main_menu': 'Main Menu',
      'news': 'News',
      'no_news': 'No announcements yet',
      'menu_repair': 'Report',
      'menu_room_log': 'Room Log',
      'menu_contact': 'Contact',
      'menu_rules': 'Rules',
      'nav_home': 'Home',
      'nav_more': 'More',
      'more_menu': 'More Menu',
      'profile_info': 'Profile Info',
      'profile_desc': 'View and edit profile',
      'notification': 'Notification',
      'notification_on': 'Enabled',
      'notification_off': 'Disabled',
      'language': 'Language',
      'help': 'Help & Support',
      'logout': 'Logout',
      'save_success': 'Saved successfully',
      'save': 'Save',
      'contact_staff': 'Contact Staff',
      'coming_soon_title': 'Coming soon',
      'coming_soon_msg': 'This feature will be available soon',
      'contact_msg':
          'If you have issues,\nContact 053-916-xxx\nor Line: @mfu_fixflow',
      'ok': 'OK',
      'dorm_hint': 'Dorm / Room',
      'phone_hint': 'Phone Number',
      'name_hint': 'Full Name',
      'no_logs': 'No maintenance logs found for this room',
      'cat_general': 'General Repair',
      'cat_water': 'Plumbing',
      'cat_electric': 'Electrical',
      'cat_ac': 'Air Conditioner',
      'cat_furniture': 'Furniture',
      'cat_internet': 'Internet',
      'cat_other': 'Other',
      'my_technician': 'My Technician',
      'no_technician': 'No technician assigned yet',
      'tech_active': 'Work in progress',
      'tech_completed': 'Work completed',
      'rate_now': 'Rate now',
      'rated': 'Rated',
      'rating_title': 'Rate this repair',
      'rating_hint': 'Share a short note (optional)',
      'rating_submit': 'Submit rating',
      'rating_required': 'Please select a rating',
      'rating_thanks': 'Thanks for your rating',
      'view_detail': 'View details',
      'mark_all_read': 'Mark all as read',
      'no_notification': 'No notifications',
      'noti_system_update': 'You will be notified for ticket updates',
      'loading': 'Loading...',
    },
  };

  String tr(String key) => _translations[_currentLanguageCode]?[key] ?? key;

  String _getDisplayCategory(String? rawCategory) {
    if (rawCategory == null) return tr('cat_general');
    if (rawCategory == 'แจ้งซ่อมทั่วไป') return tr('cat_general');
    if (rawCategory.contains('ประปา')) return tr('cat_water');
    if (rawCategory.contains('ไฟฟ้า')) return tr('cat_electric');
    if (rawCategory.contains('แอร์') || rawCategory.contains('ปรับอากาศ')) {
      return tr('cat_ac');
    }
    if (rawCategory.contains('เฟอร์นิเจอร์')) return tr('cat_furniture');
    if (rawCategory.contains('เน็ต') || rawCategory.contains('Wifi')) {
      return tr('cat_internet');
    }
    if (_translations['th']!.containsKey(rawCategory)) return tr(rawCategory);
    return rawCategory;
  }

  bool get _isLoggedIn => supabase.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initialLoad();
  }

  void _initialLoad() async {
    await _loadLanguage();
    await _loadUserProfile();
    _animationController.forward();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language_code');
    if (savedLang != null) setState(() => _currentLanguageCode = savedLang);
  }

  Future<void> _saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
  }

  @override
  void dispose() {
    _topBannerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showNotificationBottomSheet() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DefaultTabController(
        length: 2,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          height: MediaQuery.of(context).size.height * 0.75,
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
              const SizedBox(height: 16),
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: const Color(0xFFA51C30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      text: 'ข่าวสาร',
                      icon: Icon(Icons.campaign_rounded),
                    ),
                    Tab(
                      text: 'แจ้งเตือน',
                      icon: Icon(Icons.notifications_active_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    _buildNewsTab(),
                    _buildNotificationTab(userId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('announcements')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFA51C30)),
          );
        }

        final allNews = snapshot.data ?? [];
        final announcements = allNews.where((news) {
          final target = news['target_group'];
          return target == 'all' || target == 'student';
        }).toList();

        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 50, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(
                  'ไม่มีประกาศ',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: announcements.length,
          separatorBuilder: (c, i) => Divider(color: Colors.grey[200]),
          itemBuilder: (context, index) {
            final item = announcements[index];
            final date = _formatDateString(item['created_at']);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFA51C30).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.article, color: Color(0xFFA51C30)),
              ),
              title: Text(
                item['title'] ?? 'ประกาศ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                item['content'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationTab(String userId) {
    return Column(
      children: [
        // Header with buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _markAllAsRead(userId),
              child: Text(
                tr('mark_all_read'),
                style: const TextStyle(color: Color(0xFFA51C30)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Notification List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('notifications')
                .stream(primaryKey: ['id'])
                .eq('user_id', userId)
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              // Debug: Display connection status
              debugPrint('[Notification] Stream State: ${snapshot.connectionState}');
              debugPrint('[Notification] User ID: $userId');
              debugPrint('[Notification] Has Data: ${snapshot.hasData}');
              debugPrint('[Notification] Data Count: ${snapshot.data?.length ?? 0}');
              
              if (snapshot.hasError) {
                debugPrint('[Error] Notification Error: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.red),
                      const SizedBox(height: 10),
                      Text(
                        'เกิดข้อผิดพลาด: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFA51C30)),
                      const SizedBox(height: 16),
                      Text(tr('loading')),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data ?? [];
              debugPrint('[Notifications] Total: ${notifications.length} items');

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text(
                        tr('no_notification'),
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        tr('noti_system_update'),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (c, i) => Divider(color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final noti = notifications[index];
                  final isRead = noti['is_read'] ?? false;
                  final createdAt = DateTime.parse(noti['created_at']);
                  final timeAgo = _formatDate(createdAt);

                  return Dismissible(
                    key: Key(noti['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteNotification(noti['id']),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        if (!isRead) {
                          _markAsRead(noti['id']);
                        }
                      },
                      tileColor: isRead ? Colors.transparent : const Color(0xFFFFF3F3),
                      leading: CircleAvatar(
                        backgroundColor: isRead ? Colors.green.shade50 : Colors.orange.shade50,
                        child: Icon(
                          isRead ? Icons.check_circle_outline : Icons.new_releases_outlined,
                          color: isRead ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              noti['title'] ?? 'แจ้งเตือน',
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFA51C30),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            noti['message'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays} วันที่แล้ว';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      return DateFormat('dd MMM').format(DateTime.parse(dateStr).toLocal());
    } catch (e) {
      return "-";
    }
  }

  // ไม่ต้องใช้ _loadData() แล้ว เพราะใช้ StreamBuilder แทน

  // Format room number for display with space between dorm and room (e.g. "F 302")
  String _getDisplayRoomNumber() {
    if (_roomNumber.isEmpty) return _roomNumber;
    
    // Find the first digit position
    int digitStart = 0;
    while (digitStart < _roomNumber.length && !_roomNumber[digitStart].contains(RegExp(r'[0-9]'))) {
      digitStart++;
    }
    
    // If no digits found, return as is
    if (digitStart == 0 || digitStart == _roomNumber.length) {
      return _roomNumber;
    }
    
    // Split dorm and room number with space
    return "${_roomNumber.substring(0, digitStart)} ${_roomNumber.substring(digitStart)}";
  }

  Future<void> _loadUserProfile() async {
    if (!_isLoggedIn) {
      if (mounted) setState(() => _displayName = tr('guest'));
      return;
    }
    final user = supabase.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    String? fullName = prefs.getString('saved_name');
    String? savedDorm = prefs.getString('saved_dorm');
    String? savedRoom = prefs.getString('saved_room');

    if (fullName == null || fullName.isEmpty) {
      fullName =
          user?.userMetadata?['full_name'] ??
          user?.userMetadata?['name'] ??
          user?.email?.split('@')[0] ??
          "User";
    }

    // Combine dorm + room number (e.g. "F302")
    String finalRoomNumber = "";
    if (savedDorm != null && savedDorm.isNotEmpty && savedRoom != null && savedRoom.isNotEmpty) {
      finalRoomNumber = "$savedDorm$savedRoom";
    } else if (savedDorm != null && savedDorm.isNotEmpty) {
      finalRoomNumber = savedDorm;
    }

    if (mounted) {
      setState(() {
        _displayName = fullName!.split(' ')[0];
        _roomNumber = finalRoomNumber;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadUserProfile();
    _animationController.forward(from: 0.0);
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA51C30), Color(0xFF7C1523)],
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
                            tr('logout_confirm_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('logout_confirm_msg'),
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
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(tr('exit')),
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

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('login')),
        content: Text(tr('login_alert')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ).then((_) => _refreshAll());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA51C30),
              foregroundColor: Colors.white,
            ),
            child: Text(tr('login')),
          ),
        ],
      ),
    );
  }

  // Helper สีสถานะ
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.purple;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Helper ข้อความสถานะ
  String _getStatusText(String? status) {
    switch (status) {
      case 'approved':
        return tr('approved');
      case 'in_progress':
        return tr('repairing');
      case 'completed':
        return tr('completed');
      case 'rejected':
        return tr('rejected');
      default:
        return tr('pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guest Mode: แสดง UI แบบไม่ใช้ realtime
    if (!_isLoggedIn) {
      return _buildGuestScaffold();
    }

    // Logged In Mode: ใช้ StreamBuilder สำหรับ realtime updates
    final userId = supabase.auth.currentUser!.id;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('tickets')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false),
      builder: (context, ticketSnapshot) {
        final myTickets = ticketSnapshot.data ?? [];

        // คำนวณ Status Counts
        int pending = 0, inProgress = 0, completed = 0;
        for (var t in myTickets) {
          final status = t['status'];
          if (status == 'pending' || status == 'approved') {
            pending++;
          } else if (status == 'in_progress') {
            inProgress++;
          } else if (status == 'completed') {
            completed++;
          }
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('announcements')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false)
              .limit(10),
          builder: (context, newsSnapshot) {
            // Filter announcements for students only
            final allNews = newsSnapshot.data ?? [];
            final announcements = allNews.where((news) {
              final target = news['target_group'];
              return target == 'all' || target == 'student';
            }).take(5).toList();

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('notifications')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', userId),
              builder: (context, notiSnapshot) {
                final allNotifications = notiSnapshot.data ?? [];
                final unreadNotifications = allNotifications.where((n) => n['is_read'] == false).length;

                return _buildMainScaffold(
                  myTickets,
                  announcements,
                  unreadNotifications,
                  pending,
                  inProgress,
                  completed,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGuestScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: const Color(0xFFA51C30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8E1021),
                      Color(0xFFA51C30),
                      Color(0xFFFBEAEC),
                      Color(0xFFF5F6FA),
                    ],
                    stops: [0.0, 0.25, 0.65, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -80,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildGuestContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMainScaffold(
    List<Map<String, dynamic>> myTickets,
    List<Map<String, dynamic>> announcements,
    int unreadNotifications,
    int pending,
    int inProgress,
    int completed,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: const Color(0xFFA51C30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8E1021),
                      Color(0xFFA51C30),
                      Color(0xFFFBEAEC),
                      Color(0xFFF5F6FA),
                    ],
                    stops: [0.0, 0.25, 0.65, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -80,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildMainContent(
                  myTickets,
                  announcements,
                  unreadNotifications,
                  pending,
                  inProgress,
                  completed,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildGuestContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFFA51C30),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _showLoginDialog,
                  icon: const Icon(
                    Icons.notifications_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 70),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text(tr('login_alert'))),
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Main Menu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(tr('main_menu')),
                const SizedBox(height: 12),
                _buildQuickMenuGrid(context, const []),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        // News
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(tr('news')),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('announcements')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: false)
                      .limit(10),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allNews = snapshot.data ?? [];
                    final guestAnnouncements = allNews.where((news) {
                      final target = news['target_group'];
                      return target == 'all' || target == 'student';
                    }).take(5).toList();

                    if (guestAnnouncements.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            tr('no_news'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: guestAnnouncements.length,
                      itemBuilder: (context, index) =>
                          _buildNewsCard(guestAnnouncements[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMainContent(
    List<Map<String, dynamic>> myTickets,
    List<Map<String, dynamic>> announcements,
    int unreadNotifications,
    int pending,
    int inProgress,
    int completed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Text(
                        _displayName.isNotEmpty
                            ? _displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Color(0xFFA51C30),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (_roomNumber.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              _getDisplayRoomNumber(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _showNotificationBottomSheet(),
                      icon: const Icon(
                        Icons.notifications_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            unreadNotifications > 99 ? '99+' : unreadNotifications.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Status Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeTransition(
            opacity: _animationController,
            child: _buildStatusCardWithData(pending, inProgress, completed),
          ),
        ),
        const SizedBox(height: 20),
        // Latest Jobs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(tr('latest_jobs')),
                      IconButton(
                        onPressed: _refreshAll,
                        icon: const Icon(Icons.refresh, color: Colors.grey, size: 22),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecentTicketListWithData(myTickets),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        // Main Menu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(tr('main_menu')),
                  const SizedBox(height: 12),
                  _buildQuickMenuGrid(context, myTickets),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        // News Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(tr('news')),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 140,
                    child: announcements.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                tr('no_news'),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: announcements.length,
                            itemBuilder: (context, index) =>
                                _buildNewsCard(announcements[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildStatusCardWithData(int pending, int inProgress, int completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusItem(pending.toString(), tr('pending'), Colors.orange),
          Container(width: 1, height: 46, color: Colors.grey[200]),
          _buildStatusItem(inProgress.toString(), tr('repairing'), Colors.blue),
          Container(width: 1, height: 46, color: Colors.grey[200]),
          _buildStatusItem(completed.toString(), tr('completed'), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String count, String label, Color color) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        width: 22,
        height: 3,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ],
  );

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
      child: FloatingActionButton(
        onPressed: () {
          if (_isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ).then((_) => _refreshAll());
          } else {
            _showLoginDialog();
          }
        },
        backgroundColor: const Color(0xFFA51C30),
        elevation: 4,
        child: const Icon(Icons.add_a_photo, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _AnimatedNavButton(
              icon: Icons.home_rounded,
              label: tr('nav_home'),
              isSelected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                _refreshAll();
              },
            ),
            _AnimatedNavButton(
              icon: Icons.grid_view_rounded,
              label: tr('nav_more'),
              isSelected: _selectedIndex == 1,
              onTap: () => _showMoreMenu(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1022), Color(0xFFA51C30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA51C30).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      "Announcement",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateString(news['created_at']),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                news['title'] ?? 'No Title',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                news['content'] ?? '-',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMenuGrid(
    BuildContext context,
    List<Map<String, dynamic>> myTickets,
  ) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,
    mainAxisSpacing: 10,
    crossAxisSpacing: 12,
    childAspectRatio: 0.9,
    children: [
      _buildMenuButton(
        Icons.build_circle,
        tr('menu_repair'),
        const Color(0xFFA51C30),
        () {
          if (!_isLoggedIn) {
            _showLoginDialog();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReportScreen(languageCode: _currentLanguageCode),
              ),
            ).then((_) => _refreshAll());
          }
        },
      ),
      _buildMenuButton(
        Icons.history_edu_rounded,
        tr('menu_room_log'),
        Colors.brown,
        () => _showRoomLog(),
      ),
      _buildMenuButton(
        Icons.engineering,
        tr('my_technician'),
        const Color(0xFF2E7D32),
        () {
          if (!_isLoggedIn) {
            _showLoginDialog();
          } else {
            _showMyTechnicianSheet(myTickets);
          }
        },
      ),
      _buildMenuButton(
        Icons.menu_book,
        tr('menu_rules'),
        Colors.purple,
        () => _showRulesDialog(context),
      ),
    ],
  );

  Widget _buildMenuButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.18),
                      color.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 5),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTicketListWithData(List<Map<String, dynamic>> myTickets) {
    if (myTickets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(
            tr('no_jobs'),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 5),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: myTickets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final ticket = myTickets[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset((1 - value) * 50, 0),
                child: child,
              ),
            ),
            child: _buildHorizontalTicketCard(ticket),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalTicketCard(Map<String, dynamic> ticket) {
    return Container(
      width: 280,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(
                  ticket: ticket,
                  languageCode: _currentLanguageCode,
                ),
              ),
            ).then((_) => _refreshAll()),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getStatusColor(ticket['status']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.build_rounded,
                          color: _getStatusColor(ticket['status']),
                          size: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(ticket['status']).withOpacity(0.15),
                              _getStatusColor(ticket['status']).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(ticket['status']).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getStatusColor(ticket['status']),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(ticket['status']),
                              style: TextStyle(
                                color: _getStatusColor(ticket['status']),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDisplayCategory(ticket['category']),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ticket['description'] ?? '-',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateString(ticket['created_at']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFEEF1), Color(0xFFF7F4F8)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE7D5DA)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1AA51C30),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFA51C30),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2933),
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );

  int _parseRating(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic>? _findActiveTicket(List<Map<String, dynamic>> tickets) {
    for (final ticket in tickets) {
      final status = ticket['status'] as String?;
      final techName = ticket['technician_name'] as String?;
      if (techName != null && techName.isNotEmpty) {
        if (status == 'approved' || status == 'in_progress') {
          return ticket;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _findLatestCompletedTicket(List<Map<String, dynamic>> tickets) {
    for (final ticket in tickets) {
      final status = ticket['status'] as String?;
      final techName = ticket['technician_name'] as String?;
      if (techName != null && techName.isNotEmpty && status == 'completed') {
        return ticket;
      }
    }
    return null;
  }

  Widget _buildMyTechnicianCard(List<Map<String, dynamic>> myTickets) {
    final activeTicket = _findActiveTicket(myTickets);
    final completedTicket = activeTicket == null
        ? _findLatestCompletedTicket(myTickets)
        : null;

    final ticket = activeTicket ?? completedTicket;
    if (ticket == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFA51C30).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.engineering, color: Color(0xFFA51C30)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('my_technician'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('no_technician'),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final techName = ticket['technician_name'] as String? ?? '-';
    final status = ticket['status'] as String? ?? 'pending';
    final category = _getDisplayCategory(ticket['category']);
    final rating = _parseRating(ticket['rating']);
    final isCompleted = status == 'completed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFA51C30).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.engineering,
                  color: Color(0xFFA51C30),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('my_technician'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      techName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? tr('tech_completed') : tr('tech_active'),
                  style: TextStyle(
                    fontSize: 11,
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            category,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailScreen(
                          ticket: ticket,
                          languageCode: _currentLanguageCode,
                        ),
                      ),
                    ).then((_) => _refreshAll());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA51C30),
                    side: const BorderSide(color: Color(0xFFA51C30)),
                  ),
                  child: Text(tr('view_detail')),
                ),
              ),
              const SizedBox(width: 12),
              if (isCompleted)
                Expanded(
                  child: rating > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star,
                                size: 16,
                                color: index < rating
                                    ? Colors.amber
                                    : Colors.amber.withOpacity(0.3),
                              ),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => _showRatingSheet(ticket),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA51C30),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(tr('rate_now')),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingSheet(Map<String, dynamic> ticket) async {
    int rating = _parseRating(ticket['rating']);
    final commentController = TextEditingController(
      text: ticket['rating_comment']?.toString() ?? '',
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
                      _showTopBanner(tr('rating_required'), isError: true);
                      return;
                    }
                    await supabase.from('tickets').update({
                      'rating': rating,
                      'rating_comment': commentController.text.trim(),
                      'rated_at': DateTime.now().toIso8601String(),
                    }).eq('id', ticket['id']);

                    if (mounted) {
                      Navigator.pop(context);
                      _showTopBanner(tr('rating_thanks'));
                      _refreshAll();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA51C30),
                    foregroundColor: Colors.white,
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

  void _showRoomLog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              tr('menu_room_log'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "ห้อง ${_getDisplayRoomNumber()}",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 30),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('room_logs')
                    .stream(primaryKey: ['id'])
                    .eq('room_number', _roomNumber)
                    .order('log_date', ascending: false),
                builder: (context, snapshot) {
                  debugPrint('[RoomLogs] Stream State: ${snapshot.connectionState}');
                  debugPrint('[RoomLogs] Room Number: $_roomNumber');
                  debugPrint('[RoomLogs] Has Data: ${snapshot.hasData}');
                  debugPrint('[RoomLogs] Data Count: ${snapshot.data?.length ?? 0}');
                  
                  if (snapshot.hasError) {
                    debugPrint('[Error] RoomLogs Error: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
                          const SizedBox(height: 10),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red[500], fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 50,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            tr('no_logs'),
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Room: ${_getDisplayRoomNumber()}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.brown.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.build, color: Colors.brown, size: 20),
                          ),
                          title: Text(
                            log['title'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${log['log_date'] ?? '-'} • ${log['performed_by'] ?? '-'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log['status'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyTechnicianSheet(List<Map<String, dynamic>> myTickets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              tr('my_technician'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildMyTechnicianCard(myTickets),
            ),
          ],
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (c) {
      Widget buildRuleSection(String title, List<String> items) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA51C30).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.rule,
                      size: 18,
                      color: Color(0xFFA51C30),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.98,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
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
              const SizedBox(height: 16),
              Text(
                tr('menu_rules'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'สรุปกฎระเบียบหอพักนักศึกษา (ฉบับย่อ)',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              buildRuleSection(
                'การเข้า-ออกหอพัก',
                [
                  'หอพักเปิด 06.00 น. และปิด 22.30 น.',
                  'กลับหลังเวลา 22.30 น. ให้ทำแบบฟอร์มขอกลับหอพักล่าช้าและแจ้งผู้ดูแลล่วงหน้า',
                  'พกบัตรประจำตัวหอพักและแสดงต่อเจ้าหน้าที่ทุกครั้ง',
                  'หากค้างคืนนอกหอพัก ต้องแจ้งขออนุญาตและระบุวัน/เวลาให้ชัดเจน',
                ],
              ),
              buildRuleSection(
                'การเยี่ยมผู้พักอาศัย',
                [
                  'พบผู้พักอาศัยได้เฉพาะพื้นที่ที่มหาวิทยาลัยกำหนด',
                  'บุคคลภายนอกห้ามเข้าพื้นที่พักอาศัย เว้นแต่ได้รับอนุญาตเป็นกรณีไป',
                ],
              ),
              buildRuleSection(
                'การอยู่ร่วมกัน',
                [
                  'ห้ามรบกวนผู้อื่นและก่อความเดือดร้อน',
                  'ห้ามเล่นการพนัน',
                  'ห้ามดื่มแอลกอฮอล์หรือใช้สารเสพติดทุกชนิด',
                  'ห้ามมีอาวุธ วัตถุไวไฟ หรือวัตถุอันตราย',
                  'ห้ามเลี้ยงสัตว์ในหอพักหรือห้องพัก',
                  'ห้ามทำลายทรัพย์สินหรือสิ่งของส่วนรวม',
                  'ห้ามจัดกิจกรรม/การละเล่นที่ไม่ได้รับอนุญาต',
                  'ห้ามสวมรองเท้าในพื้นที่ที่พักอาศัย',
                ],
              ),
              buildRuleSection(
                'อุปกรณ์และเครื่องใช้ไฟฟ้า',
                [
                  'ใช้เครื่องใช้ไฟฟ้าได้เฉพาะที่อนุญาต (เช่น พัดลม วิทยุ ไดร์เป่าผม คอมพิวเตอร์)',
                  'ห้ามใช้เครื่องใช้ไฟฟ้าต้องห้าม เช่น เตาไฟฟ้า กาต้มน้ำไฟฟ้า ไมโครเวฟ ตู้เย็น',
                  'ห้ามทำอาหารภายในห้องพัก',
                  'ห้ามนำอุปกรณ์ของส่วนกลางมาใช้ส่วนตัวหรือดัดแปลง',
                ],
              ),
              buildRuleSection(
                'การฝ่าฝืนระเบียบ',
                [
                  'ผู้ฝ่าฝืนจะถูกลงโทษตามระเบียบและข้อบังคับของมหาวิทยาลัย',
                  'มหาวิทยาลัยมีสิทธิ์เข้าตรวจสอบ/ซ่อมแซมห้องพักเมื่อจำเป็น',
                  'อาจมีการตรวจระเบียบและสุขอนามัยโดยไม่ต้องแจ้งล่วงหน้า',
                ],
              ),
              buildRuleSection(
                'เมื่อสิ้นปีการศึกษา',
                [
                  'ผู้พักอาศัยต้องย้ายออกตามวันเวลาที่มหาวิทยาลัยกำหนด',
                  'ห้ามค้างพักหลังวันสิ้นปีการศึกษา',
                  'ต้องเคลื่อนย้ายทรัพย์สินออกจากหอพักให้เสร็จภายในกำหนด',
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: Text(
                    tr('ok'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _showSavedInfoDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final user = supabase.auth.currentUser;
    String initialName =
        user?.userMetadata?['full_name'] ??
        user?.userMetadata?['name'] ??
        user?.email?.split('@')[0] ??
        '';
    final phoneController = TextEditingController(
      text: prefs.getString('saved_phone') ?? '',
    );
    final dormController = TextEditingController(
      text: prefs.getString('saved_dorm') ?? '',
    );
    final nameController = TextEditingController(text: initialName);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA51C30), Color(0xFF7C1523)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          _displayName.isNotEmpty
                              ? _displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('profile_info'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('profile_desc'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _buildProfileField(
                  controller: nameController,
                  label: tr('name_hint'),
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildProfileField(
                  controller: phoneController,
                  label: tr('phone_hint'),
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildProfileField(
                  controller: dormController,
                  label: tr('dorm_hint'),
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(c),
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
                        onPressed: () async {
                          await prefs.setString('saved_name', nameController.text);
                          await prefs.setString('saved_phone', phoneController.text);
                          await prefs.setString('saved_dorm', dormController.text);
                          if (mounted) {
                            Navigator.pop(c);
                            _showTopBanner(tr('save_success'));
                            _loadUserProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA51C30),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(tr('save')),
                      ),
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

  Future<void> _showMoreMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final sheetHeight = MediaQuery.of(context).size.height * 0.65;
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA51C30), Color(0xFF7C1523)],
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
                            Icons.grid_view_rounded,
                            color: Colors.white,
                          ),
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
                                    ? 'จัดการโปรไฟล์และการตั้งค่า'
                                    : 'Manage your profile and settings',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
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
                          icon: Icons.person_outline,
                          title: tr('profile_info'),
                          subtitle: tr('profile_desc'),
                          onTap: () {
                            Navigator.pop(context);
                            _showSavedInfoDialog();
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildMoreMenuTile(
                          icon: Icons.language,
                          title: tr('language'),
                          subtitle: _currentLanguageCode == 'th'
                              ? 'ไทย (TH)'
                              : 'English (EN)',
                          onTap: () =>
                              _showLanguageSelector(context, setModalState),
                        ),
                        const SizedBox(height: 10),
                        _buildMoreMenuTile(
                          icon: Icons.support_agent_rounded,
                          title: tr('contact_staff'),
                          subtitle: tr('coming_soon_msg'),
                          onTap: () => _showComingSoonDialog(context),
                        ),
                        const SizedBox(height: 10),
                        _buildMoreMenuTile(
                          icon: Icons.logout,
                          title: tr('logout'),
                          subtitle: tr('logout_confirm_title'),
                          color: Colors.red,
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
        );
      },
    );
  }

  Widget _buildMoreMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    VoidCallback? onTap,
  }) {
    final themeColor = color ?? const Color(0xFFA51C30);
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
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA51C30), Color(0xFF7C1523)],
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
                    backgroundColor: const Color(0xFFA51C30),
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

  void _showTopBanner(String message, {bool isError = false}) {
    _topBannerController?.stop();
    _topBannerController?.dispose();
    _topBannerEntry?.remove();

    final overlay = Overlay.of(context);

    final accentColor = isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    _topBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    final animation = CurvedAnimation(
      parent: _topBannerController!,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _topBannerEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_topBannerEntry!);
    _topBannerController!.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted || _topBannerController == null) return;
      await _topBannerController!.reverse();
      _topBannerEntry?.remove();
      _topBannerEntry = null;
    });
  }

  void _showLanguageSelector(
    BuildContext parentContext,
    StateSetter setModalState,
  ) {
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA51C30), Color(0xFF7C1523)],
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
                          Icons.language,
                          color: Colors.white,
                        ),
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
                    setModalState(fn);
                  },
                  dialogContext: c,
                ),
                const SizedBox(height: 10),
                _buildLanguageOption(
                  label: "English (EN)",
                  value: "en",
                  setModalState: (fn) {
                    modalSetState(fn);
                    setModalState(fn);
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

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA51C30)),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required String value,
    required StateSetter setModalState,
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
          color: isSelected
              ? const Color(0xFFA51C30).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFA51C30) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: isSelected ? const Color(0xFFA51C30) : Colors.grey[400],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFFA51C30) : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFFA51C30)).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? const Color(0xFFA51C30)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color ?? Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _AnimatedNavButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;
  const _AnimatedNavButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.label,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA51C30).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? const Color(0xFFA51C30) : Colors.grey,
            ),
            if (isSelected && label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: const TextStyle(
                  color: Color(0xFFA51C30),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
