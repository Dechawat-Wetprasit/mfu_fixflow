import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_fixflow/features/dashboard/notification_screen.dart';
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
  String _roomNumber = "F3";

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

  // Data Variables
  List<Map<String, dynamic>> _myTickets = [];
  List<Map<String, dynamic>> _announcements = []; // ตัวแปรเก็บข่าวจริง
  int _unreadNotifications = 0;

  // Dashboard Counts
  int _pending = 0;
  int _inProgress = 0;
  int _completed = 0;

  late AnimationController _animationController;
  int _selectedIndex = 0;

  final bool _isNotificationEnabled = true;
  bool _isLoading = true;
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
      'greeting_morning': 'สวัสดีตอนเช้า ☀️',
      'greeting_afternoon': 'สวัสดีตอนบ่าย 🌤️',
      'greeting_evening': 'สวัสดีตอนเย็น 🌆',
      'greeting_night': 'สวัสดีตอนค่ำ 🌙',
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
      'save_success': '✅ บันทึกข้อมูลเรียบร้อย',
      'save': 'บันทึก',
      'contact_staff': 'ติดต่อเจ้าหน้าที่',
      'contact_msg':
          'หากพบปัญหาการใช้งาน\nกรุณาติดต่อ 053-916-xxx\nหรือ Line: @mfu_fixflow',
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
    },
    'en': {
      'hello': 'HELLO',
      'guest': 'Guest',
      'login': 'Login',
      'logout_confirm_title': 'Confirm',
      'logout_confirm_msg': 'Do you want to logout?',
      'cancel': 'Cancel',
      'exit': 'Logout',
      'greeting_morning': 'Good Morning ☀️',
      'greeting_afternoon': 'Good Afternoon 🌤️',
      'greeting_evening': 'Good Evening 🌆',
      'greeting_night': 'Good Night 🌙',
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
      'save_success': '✅ Saved successfully',
      'save': 'Save',
      'contact_staff': 'Contact Staff',
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
    if (_isLoggedIn) {
      _loadData();
    } else {
      _loadPublicData();
    }
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPublicData() async {
    try {
      final newsResponse = await supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(newsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    if (!_isLoggedIn) return;
    setState(() => _isLoading = true);

    final userId = supabase.auth.currentUser!.id;

    try {
      // 1. ดึง Tickets
      final ticketResponse = await supabase
          .from('tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // 2. ดึงข่าว
      final newsResponse = await supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      // 3. ดึงจำนวน Notification
      final notiResponse = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count();

      // 4. คำนวณ Status Counts
      int p = 0, ip = 0, c = 0;
      for (var t in ticketResponse) {
        final status = t['status'];
        if (status == 'pending' || status == 'approved') {
          p++;
        } else if (status == 'in_progress')
          ip++;
        else if (status == 'completed')
          c++;
      }

      if (mounted) {
        setState(() {
          _myTickets = List<Map<String, dynamic>>.from(ticketResponse);
          _announcements = List<Map<String, dynamic>>.from(newsResponse);
          _unreadNotifications = notiResponse.count;
          _pending = p;
          _inProgress = ip;
          _completed = c;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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

    if (fullName == null || fullName.isEmpty) {
      fullName =
          user?.userMetadata?['full_name'] ??
          user?.userMetadata?['name'] ??
          user?.email?.split('@')[0] ??
          "User";
    }

    if (mounted) {
      setState(() {
        _displayName = fullName!.split(' ')[0];
        _roomNumber = (savedDorm != null && savedDorm.isNotEmpty)
            ? savedDorm
            : "F3";
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadUserProfile();
    if (_isLoggedIn) {
      await _loadData();
    } else {
      await _loadPublicData();
    }
    _animationController.forward(from: 0.0);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('logout_confirm_title')),
        content: Text(tr('logout_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr('exit'), style: const TextStyle(color: Colors.red)),
          ),
        ],
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: const Color(0xFFA51C30),
        child: Stack(
          children: [
            Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA51C30), Color(0xFF800020)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (_isLoggedIn) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationScreen(),
                                      ),
                                    ).then((_) => _refreshAll());
                                  } else {
                                    _showLoginDialog();
                                  }
                                },
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                              if (_unreadNotifications > 0)
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.yellow,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Status Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FadeTransition(
                        opacity: _animationController,
                        child: _buildStatusCard(),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Latest Jobs (Moved Up)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.2,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle(tr('latest_jobs')),
                                if (_isLoggedIn)
                                  IconButton(
                                    onPressed: _refreshAll,
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.grey,
                                      size: 22,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            if (_isLoggedIn)
                              _buildRecentTicketList()
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Center(
                                      child: Text(tr('login_alert')),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Main Menu (Moved Up)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.4,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(tr('main_menu')),
                            const SizedBox(height: 15),
                            _buildQuickMenuGrid(context),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // News Section (Moved Down)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(
                              0.6,
                              1.0,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(tr('news')),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 140,
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _announcements.isEmpty
                                  ? Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Text(
                                          tr('no_news'),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _announcements.length,
                                      itemBuilder: (context, index) =>
                                          _buildNewsCard(_announcements[index]),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
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
      ),
    );
  }

  // --- Widgets ---

  Widget _buildNewsCard(Map<String, dynamic> news) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Announcement",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(news['created_at']),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            news['content'] ?? '-',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusItem(_pending.toString(), tr('pending'), Colors.orange),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatusItem(
            _inProgress.toString(),
            tr('repairing'),
            Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatusItem(
            _completed.toString(),
            tr('completed'),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String count, String label, Color color) => Column(
    children: [
      Text(
        count,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

  Widget _buildQuickMenuGrid(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
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
        Icons.support_agent,
        tr('menu_contact'),
        Colors.teal,
        () => _showContactDialog(context),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTicketList() {
    if (_myTickets.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _myTickets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final ticket = _myTickets[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: child,
              ),
            ),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailScreen(
                    ticket: ticket,
                    languageCode: _currentLanguageCode,
                  ),
                ),
              ),
              child: _buildHorizontalTicketCard(ticket),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalTicketCard(Map<String, dynamic> ticket) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket['status']).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.build,
                  color: _getStatusColor(ticket['status']),
                  size: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(ticket['status']),
                  style: TextStyle(
                    color: _getStatusColor(ticket['status']),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDisplayCategory(ticket['category']),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                ticket['description'] ?? '-',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 5),
              Text(
                _formatDate(ticket['created_at']),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'];
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(
            ticket: ticket,
            languageCode: _currentLanguageCode,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.build, color: statusColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayCategory(ticket['category']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket['description'] ?? '-',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  );

  Future<void> _showHistoryDialog(BuildContext context) async {
    // ฟังก์ชันนี้ไม่ได้ใช้ใน Flow ใหม่แต่เก็บไว้เผื่ออนาคต
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
              "ห้อง $_roomNumber",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 30),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase
                    .from('room_logs')
                    .select()
                    .eq('room_number', _roomNumber)
                    .order('log_date', ascending: false),
                builder: (context, snapshot) {
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
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        leading: const Icon(Icons.build, color: Colors.brown),
                        title: Text(log['title'] ?? '-'),
                        subtitle: Text(
                          "${log['log_date']} • ${log['performed_by']}",
                        ),
                        trailing: Text(
                          log['status'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

  void _showContactDialog(BuildContext context) => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tr('menu_contact')),
      content: Text(tr('contact_msg')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('ok'))),
      ],
    ),
  );
  void _showRulesDialog(BuildContext context) => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(tr('menu_rules')),
      content: const Text("1. ห้ามส่งเสียงดัง\n2. แจ้งซ่อมภายในเวลาทำการ"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('ok'))),
      ],
    ),
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
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('profile_info')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: tr('name_hint'),
                  icon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: tr('phone_hint'),
                  icon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dormController,
                decoration: InputDecoration(
                  labelText: tr('dorm_hint'),
                  icon: const Icon(Icons.home),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              tr('cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await prefs.setString('saved_name', nameController.text);
              await prefs.setString('saved_phone', phoneController.text);
              await prefs.setString('saved_dorm', dormController.text);
              if (mounted) {
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('save_success')),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadUserProfile();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA51C30),
              foregroundColor: Colors.white,
            ),
            child: Text(tr('save')),
          ),
        ],
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
            return Container(
              height: 350,
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
                    tr('more_menu'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: tr('profile_info'),
                          onTap: () {
                            Navigator.pop(context);
                            _showSavedInfoDialog();
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.language,
                          title: tr('language'),
                          subtitle: _currentLanguageCode == 'th'
                              ? "ไทย (TH)"
                              : "English (EN)",
                          onTap: () =>
                              _showLanguageSelector(context, setModalState),
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: tr('contact_staff'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text(tr('contact_staff')),
                                content: Text(tr('contact_msg')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c),
                                    child: Text(tr('ok')),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: tr('logout'),
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _handleLogout();
                          },
                        ),
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

  void _showLanguageSelector(
    BuildContext parentContext,
    StateSetter setModalState,
  ) {
    showDialog(
      context: parentContext,
      builder: (c) => AlertDialog(
        title: Text(tr('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("ไทย (TH)"),
              leading: Radio<String>(
                value: "th",
                groupValue: _currentLanguageCode,
                activeColor: const Color(0xFFA51C30),
                onChanged: (val) {
                  setState(() => _currentLanguageCode = val!);
                  _saveLanguage(val!);
                  setModalState(() {});
                  Navigator.pop(c);
                },
              ),
              onTap: () {
                setState(() => _currentLanguageCode = "th");
                _saveLanguage("th");
                setModalState(() {});
                Navigator.pop(c);
              },
            ),
            ListTile(
              title: const Text("English (EN)"),
              leading: Radio<String>(
                value: "en",
                groupValue: _currentLanguageCode,
                activeColor: const Color(0xFFA51C30),
                onChanged: (val) {
                  setState(() => _currentLanguageCode = val!);
                  _saveLanguage(val!);
                  setModalState(() {});
                  Navigator.pop(c);
                },
              ),
              onTap: () {
                setState(() => _currentLanguageCode = "en");
                _saveLanguage("en");
                setModalState(() {});
                Navigator.pop(c);
              },
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      return DateFormat('dd MMM').format(DateTime.parse(dateStr).toLocal());
    } catch (e) {
      return dateStr;
    }
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
