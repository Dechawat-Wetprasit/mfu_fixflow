import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';
import 'package:mfu_fixflow/features/dashboard/notification_screen.dart';
import 'package:mfu_fixflow/features/admin/manager_history_screen.dart';
import 'package:mfu_fixflow/features/admin/manager_report_screen.dart';
// import 'package:intl/intl.dart'; // ไม่ได้ใช้ในหน้านี้ แต่ถ้าหน้าอื่นใช้ก็เก็บไว้

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  // Animation & UI variables
  late AnimationController _animationController;
  int _selectedIndex = 0;
  bool _isNotificationEnabled = true;

  // ❌ ลบ: final TextEditingController _searchController ออกแล้ว

  List<Map<String, dynamic>> _allTickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  List<Map<String, dynamic>> _technicians = [];

  bool _isLoading = true;
  String _managerName = "Loading...";
  String _managerEmail = "";

  // Dashboard Counts
  int _pendingCount = 0;
  int _inProgressCount = 0;
  int _completedCount = 0;

  // Language
  String _currentLanguageCode = 'th';

  final Map<String, Map<String, String>> _translations = {
    'th': {
      'welcome': 'สวัสดีครับ,',
      'role': 'ผู้จัดการ',
      'search_hint': 'ค้นหาห้อง, ชื่อผู้แจ้ง...',
      'list_header': 'งานรอตรวจสอบ (Pending)',
      'pending': 'รออนุมัติ',
      'working': 'กำลังซ่อม',
      'completed': 'เสร็จสิ้น',
      'menu_main': 'เมนูจัดการ',
      'menu_staff': 'รายชื่อช่าง',
      'menu_announce': 'สร้างประกาศ',
      'menu_history': 'ประวัติงาน',
      'menu_report': 'รายงานสรุป',
      'nav_home': 'หน้าหลัก',
      'nav_more': 'เพิ่มเติม',
      'more_menu': 'เมนูเพิ่มเติม',
      'notification': 'การแจ้งเตือน',
      'notification_on': 'เปิดใช้งาน',
      'notification_off': 'ปิดใช้งาน',
      'language': 'เปลี่ยนภาษา',
      'help': 'ช่วยเหลือ',
      'logout': 'ออกจากระบบ',
      'logout_confirm': 'ต้องการออกจากระบบใช่หรือไม่?',
      'cancel': 'ยกเลิก',
      'exit': 'ออก',
      'no_jobs': 'เยี่ยม! ไม่มีงานค้างรออนุมัติ',
      'staff_list': 'รายชื่อช่างเทคนิค',
      'no_staff': 'ไม่พบรายชื่อช่าง',
      'post_title': 'สร้างประกาศข่าวสาร',
      'post_hint_title': 'หัวข้อประกาศ',
      'post_hint_desc': 'รายละเอียด...',
      'btn_post': 'โพสต์ประกาศ',
      'btn_cancel': 'ยกเลิก',
      'success_post': 'ลงประกาศเรียบร้อย',
      'active_jobs': 'งานที่กำลังดำเนินการ',
      'history_jobs': 'ประวัติงานเสร็จสิ้น',
      'no_data': 'ไม่พบข้อมูล',
      'assign_title': 'เลือกช่างเข้าซ่อม',
      'assign_desc': 'กรุณาเลือกช่างที่ต้องการมอบหมายงานนี้',
      'btn_assign': 'มอบหมายงาน',
      'success_assign': 'มอบหมายงานเรียบร้อย',
      'dialog_title': 'ตรวจสอบงาน',
      'reporter': 'ผู้แจ้ง',
      'dorm': 'หอพัก',
      'room': 'ห้อง',
      'tel': 'โทร',
      'btn_reject': 'ไม่อนุมัติ',
      'btn_approve': 'อนุมัติ',
      'approver_success': 'บันทึกการอนุมัติโดย',
      'reject_success': 'บันทึกการปฏิเสธโดย',
      'greeting_morning': 'สวัสดีตอนเช้า ☀️',
      'greeting_afternoon': 'สวัสดีตอนบ่าย 🌤️',
      'greeting_evening': 'สวัสดีตอนเย็น 🌆',
      'greeting_night': 'สวัสดีตอนค่ำ 🌙',
    },
    'en': {
      'welcome': 'Hello,',
      'role': 'Manager',
      'search_hint': 'Search Room, Name...',
      'list_header': 'Pending Approval',
      'pending': 'Pending',
      'working': 'In Progress',
      'completed': 'Completed',
      'menu_main': 'Management Menu',
      'menu_staff': 'Techs',
      'menu_announce': 'Post News',
      'menu_history': 'History',
      'menu_report': 'Report',
      'nav_home': 'Home',
      'nav_more': 'More',
      'more_menu': 'More Menu',
      'notification': 'Notification',
      'notification_on': 'Enabled',
      'notification_off': 'Disabled',
      'language': 'Language',
      'help': 'Help',
      'logout': 'Logout',
      'logout_confirm': 'Do you want to logout?',
      'cancel': 'Cancel',
      'exit': 'Logout',
      'no_jobs': 'Great! No pending tickets.',
      'staff_list': 'Technician List',
      'no_staff': 'No technicians found',
      'post_title': 'Create Announcement',
      'post_hint_title': 'Title',
      'post_hint_desc': 'Details...',
      'btn_post': 'Post',
      'btn_cancel': 'Cancel',
      'success_post': 'Announcement Posted',
      'active_jobs': 'Active Jobs',
      'history_jobs': 'Completed History',
      'no_data': 'No data found',
      'assign_title': 'Assign Technician',
      'assign_desc': 'Select a technician for this job',
      'btn_assign': 'Assign',
      'success_assign': 'Job Assigned',
      'dialog_title': 'Review Ticket',
      'reporter': 'Reporter',
      'dorm': 'Dorm',
      'room': 'Room',
      'tel': 'Tel',
      'btn_reject': 'Reject',
      'btn_approve': 'Approve',
      'approver_success': 'Approved by',
      'reject_success': 'Rejected by',
      'greeting_morning': 'Good Morning ☀️',
      'greeting_afternoon': 'Good Afternoon 🌤️',
      'greeting_evening': 'Good Evening 🌆',
      'greeting_night': 'Good Night 🌙',
    },
  };

  String tr(String key) => _translations[_currentLanguageCode]?[key] ?? key;

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadLanguage();
    _loadManagerProfile();
    _fetchTechnicians();
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // ❌ ลบ: _searchController.dispose(); ออกแล้ว
    super.dispose();
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

  Future<void> _loadManagerProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _managerEmail = user.email ?? "";
        _managerName = user.userMetadata?['full_name'] ?? "Manager";
      });
    }
  }

  Future<void> _fetchTechnicians() async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('role', 'technician');
      setState(() {
        _technicians = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Error loading techs: $e");
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allData = await supabase
          .from('tickets')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _allTickets = List<Map<String, dynamic>>.from(allData);
          _filteredTickets = _allTickets
              .where((t) => t['status'] == 'pending')
              .toList();

          _pendingCount = allData.where((t) => t['status'] == 'pending').length;
          _inProgressCount = allData
              .where(
                (t) =>
                    t['status'] == 'approved' || t['status'] == 'in_progress',
              )
              .length;
          _completedCount = allData
              .where((t) => t['status'] == 'completed')
              .length;
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
      results = _allTickets.where((t) => t['status'] == 'pending').toList();
    } else {
      results = _allTickets.where((ticket) {
        final room = ticket['room_number']?.toString().toLowerCase() ?? '';
        final name = ticket['contact_name']?.toString().toLowerCase() ?? '';
        final input = keyword.toLowerCase();
        return room.contains(input) || name.contains(input);
      }).toList();
    }
    setState(() => _filteredTickets = results);
  }

  void _filterByStatus(String status) {
    setState(() {
      // ❌ ลบ: _searchController.clear(); ออกแล้ว
      if (status == 'active') {
        _filteredTickets = _allTickets
            .where(
              (t) => t['status'] == 'approved' || t['status'] == 'in_progress',
            )
            .toList();
      } else {
        _filteredTickets = _allTickets
            .where((t) => t['status'] == status)
            .toList();
      }
    });
  }

  // --- Actions ---
  void _showAssignDialog(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('assign_title')),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('assign_desc'),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: _technicians.isEmpty
                    ? Center(child: Text(tr('no_staff')))
                    : ListView.builder(
                        itemCount: _technicians.length,
                        itemBuilder: (context, index) {
                          final tech = _technicians[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                color: Colors.purple,
                              ),
                            ),
                            title: Text(tech['full_name'] ?? 'Unknown'),
                            onTap: () {
                              _confirmAssign(
                                ticket['id'],
                                tech['id'],
                                tech['full_name'],
                              );
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('btn_cancel')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAssign(
    dynamic ticketId,
    String techId,
    String techName,
  ) async {
    try {
      await supabase
          .from('tickets')
          .update({
            'status': 'approved',
            'approver_name': _managerName,
            'technician_id': techId,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${tr('success_assign')} -> $techName"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Assign Error: $e");
    }
  }

  Future<void> _rejectTicket(dynamic ticketId) async {
    Navigator.pop(context);
    try {
      await supabase
          .from('tickets')
          .update({
            'status': 'rejected',
            'approver_name': _managerName,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${tr('reject_success')} $_managerName ❌"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _loadData();
    }
  }

  void _showPostDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('post_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: tr('post_hint_title')),
            ),
            TextField(
              controller: contentCtrl,
              decoration: InputDecoration(labelText: tr('post_hint_desc')),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('btn_cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              await supabase.from('announcements').insert({
                'title': titleCtrl.text,
                'content': contentCtrl.text,
                'created_by': _managerName,
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr('success_post')),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text(tr('btn_post')),
          ),
        ],
      ),
    );
  }

  Future<void> _showActiveJobs() async {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('active_jobs')),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: supabase
                .from('tickets')
                .select()
                .or('status.eq.approved,status.eq.in_progress')
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final jobs = snapshot.data ?? [];
              if (jobs.isEmpty) return Center(child: Text(tr('no_data')));
              return ListView.separated(
                itemCount: jobs.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (c, i) => _buildSimpleTicketItem(jobs[i]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr('btn_cancel')),
          ),
        ],
      ),
    );
  }

  void _showStaffList() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('staff_list')),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _technicians.isEmpty
              ? Center(child: Text(tr('no_staff')))
              : ListView.separated(
                  itemCount: _technicians.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (c, i) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.2),
                      child: const Icon(Icons.person, color: Colors.teal),
                    ),
                    title: Text(_technicians[i]['full_name'] ?? 'Unknown'),
                    subtitle: Text(_technicians[i]['email'] ?? '-'),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr('btn_cancel')),
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
                          Icons.notifications_outlined,
                          tr('notification'),
                          _isNotificationEnabled
                              ? tr('notification_on')
                              : tr('notification_off'),
                          trailing: Switch(
                            value: _isNotificationEnabled,
                            activeThumbColor: Colors.purple,
                            onChanged: (val) {
                              setModalState(() => _isNotificationEnabled = val);
                            },
                          ),
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          Icons.language,
                          tr('language'),
                          _currentLanguageCode == 'th' ? "ไทย" : "English",
                          onTap: () => _showLanguageSelector(context),
                        ),
                        _buildMenuItem(
                          Icons.help_outline,
                          tr('help'),
                          null,
                          onTap: () {},
                        ),
                        const Divider(),
                        _buildMenuItem(
                          Icons.logout,
                          tr('logout'),
                          null,
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

  void _showLanguageSelector(BuildContext parentContext) {
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
                activeColor: Colors.purple,
                onChanged: (val) {
                  setState(() => _currentLanguageCode = val!);
                  _saveLanguage(val!);
                  Navigator.pop(c);
                },
              ),
              onTap: () {
                setState(() => _currentLanguageCode = "th");
                _saveLanguage("th");
                Navigator.pop(c);
              },
            ),
            ListTile(
              title: const Text("English (EN)"),
              leading: Radio<String>(
                value: "en",
                groupValue: _currentLanguageCode,
                activeColor: Colors.purple,
                onChanged: (val) {
                  setState(() => _currentLanguageCode = val!);
                  _saveLanguage(val!);
                  Navigator.pop(c);
                },
              ),
              onTap: () {
                setState(() => _currentLanguageCode = "en");
                _saveLanguage("en");
                Navigator.pop(c);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('logout')),
        content: Text(tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(tr('btn_cancel')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.purple,
        child: Stack(
          children: [
            Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
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
                    // Top Bar
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
                                _managerName,
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
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationScreen(),
                                  ),
                                ).then((_) => _loadData()),
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              if (_pendingCount > 0)
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
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

                    // ❌ ลบ: Search Bar ออกแล้ว (TextField)

                    // Dashboard Status (Clickable)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FadeTransition(
                        opacity: _animationController,
                        child: Container(
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
                              _buildStatusItem(
                                _pendingCount.toString(),
                                tr('pending'),
                                Colors.orange,
                                () => _filterByStatus('pending'),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[200],
                              ),
                              _buildStatusItem(
                                _inProgressCount.toString(),
                                tr('working'),
                                Colors.blue,
                                _showActiveJobs,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[200],
                              ),
                              _buildStatusItem(
                                _completedCount.toString(),
                                tr('completed'),
                                Colors.green,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ManagerHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Grid Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          _buildGridIcon(
                            Icons.campaign,
                            tr('menu_announce'),
                            Colors.pink,
                            _showPostDialog,
                          ),
                          _buildGridIcon(
                            Icons.people,
                            tr('menu_staff'),
                            Colors.teal,
                            _showStaffList,
                          ),
                          _buildGridIcon(
                            Icons.analytics,
                            tr('menu_report'),
                            Colors.orange,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManagerReportScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Pending List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('list_header'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_filteredTickets.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    tr('no_jobs'),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredTickets.length,
                              separatorBuilder: (c, i) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) =>
                                  _buildTicketCard(_filteredTickets[index]),
                            ),
                        ],
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManagerHistoryScreen()),
            );
          },
          backgroundColor: Colors.purple,
          elevation: 4,
          tooltip: tr('menu_history'),
          child: const Icon(Icons.history, size: 30, color: Colors.white),
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
                  _loadData();
                },
              ),
              const SizedBox(width: 40), // Space for FAB
              _AnimatedNavButton(
                icon: Icons.grid_view_rounded,
                label: tr('nav_more'),
                isSelected: _selectedIndex == 1,
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  _showMoreMenu();
                  setState(() => _selectedIndex = 0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---
  Widget _buildStatusItem(
    String count,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridIcon(
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    Color statusColor = Colors.orange;
    String status = ticket['status'] ?? 'pending';
    if (status == 'approved') {
      statusColor = Colors.purple;
    } else if (status == 'in_progress')
      statusColor = Colors.blue;
    else if (status == 'completed')
      statusColor = Colors.green;
    else if (status == 'rejected')
      statusColor = Colors.red;

    return Container(
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
            child: Icon(Icons.build, color: statusColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['category'] ?? 'General',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "${ticket['dorm_building']} - ${ticket['room_number']} • ${ticket['contact_name']}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
            onPressed: () => _showTicketDetailDialog(ticket),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTicketItem(
    Map<String, dynamic> ticket) {
    Color statusColor = Colors.blue;
    if (ticket['status'] == 'completed') {
      statusColor = Colors.green;
    } else if (ticket['status'] == 'approved')
      statusColor = Colors.purple;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.build, color: statusColor, size: 20),
      ),
      title: Text(
        ticket['category'] ?? '-',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text("${ticket['dorm_building']} - ${ticket['room_number']}"),
      trailing: Text(
        ticket['status'],
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  void _showTicketDetailDialog(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${tr('dialog_title')}: ${ticket['category']}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ticket['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(ticket['image_url']),
                ),
              const SizedBox(height: 10),
              Text(ticket['description'] ?? '-'),
              const Divider(),
              Text("${tr('reporter')}: ${ticket['contact_name']}"),
              Text(
                "${tr('dorm')}: ${ticket['dorm_building']} ${tr('room')} ${ticket['room_number']}",
              ),
              Text("${tr('tel')}: ${ticket['contact_phone']}"),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => _rejectTicket(ticket['id']),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('btn_reject')),
          ),
          if (ticket['status'] == 'pending')
            ElevatedButton(
              onPressed: () => _showAssignDialog(ticket),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: Text(tr('btn_approve')),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String? subtitle, {
    Widget? trailing,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? Colors.purple).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.purple),
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
              ? Colors.purple.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.purple : Colors.grey,
            ),
            if (isSelected && label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.purple,
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
