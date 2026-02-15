import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';
import 'package:mfu_fixflow/features/admin/manager_history_screen.dart';
import 'package:mfu_fixflow/features/admin/manager_report_screen.dart';
class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  // --- UI PALETTE (Vibrant Manager Theme) ---
  final Color _gradStart = const Color(0xFF8E24AA); // Purple Vibrant
  final Color _gradEnd = const Color(0xFF4A148C);   // Deep Purple
  final Color _bgColor = const Color(0xFFF5F6FA);   // Soft Gray
  
  // Status Colors
  final Color _colPending = const Color(0xFFFF9800); // Orange
  final Color _colActive = const Color(0xFF039BE5);  // Blue
  final Color _colDone = const Color(0xFF43A047);    // Green
  final Color _colUrgent = const Color(0xFFE53935);  // Red

  late AnimationController _animationController;
  int _selectedIndex = 0;
  bool _isNotificationEnabled = true;

  // Data
  List<Map<String, dynamic>> _technicians = [];
  String _managerName = "Loading...";
  String? _managerId;
  String? _myBuilding;
  bool _isProfileLoaded = false;
  String _currentLanguageCode = 'th';

  final Map<String, Map<String, String>> _translations = {
    'th': {
      'welcome': 'สวัสดี,',
      'role': 'ผู้จัดการหอพัก',
      'building_label': 'ดูแลอาคาร:',
      'list_header': 'รายการแจ้งซ่อมล่าสุด',
      'pending': 'รอตรวจสอบ',
      'working': 'กำลังดำเนินการ',
      'completed': 'ปิดงานแล้ว',
      'menu_title': 'เมนูจัดการ',
      'menu_announce': 'ประกาศ',
      'menu_staff': 'ทีมช่าง',
      'menu_report': 'รายงาน',
      'nav_home': 'หน้าหลัก',
      'nav_history': 'ประวัติ',
      'nav_more': 'เมนู',
      'more_menu': 'เมนูเพิ่มเติม',
      'notification': 'การแจ้งเตือน',
      'notification_on': 'เปิดใช้งาน',
      'notification_off': 'ปิดใช้งาน',
      'language': 'ภาษา (Language)',
      'contact_staff': 'ติดต่อเจ้าหน้าที่',
      'coming_soon_title': 'Coming soon',
      'coming_soon_msg': 'ฟีเจอร์นี้จะเปิดใช้งานเร็วๆ นี้',
      'contact_msg': 'หากพบปัญหา\nติดต่อ 053-916-xxx\nหรือ Line: @mfu_fixflow',
      'logout': 'ออกจากระบบ',
      'logout_confirm': 'ยืนยันการออกจากระบบ?',
      'exit': 'ออก',
      'ok': 'ตกลง',
      'no_jobs': 'เยี่ยมมาก! ไม่มียอดงานค้าง',
      'assign_title': 'เลือกช่างเข้าซ่อม',
      'assign_desc': 'เลือกช่างที่เหมาะสม (ตัวเลขคืองานค้าง)',
      'btn_cancel': 'ยกเลิก',
      'btn_assign': 'มอบหมาย',
      'dialog_title': 'รายละเอียดงาน',
      'urgent_badge': 'ด่วน',
      'tel': 'โทร',
      'success_post': 'ลงประกาศถึงนักศึกษาเรียบร้อย',
      'post_title': 'ประกาศถึงนักศึกษา',
      'post_hint_title': 'หัวข้อ',
      'post_hint_desc': 'รายละเอียด...',
      'btn_post': 'โพสต์',
      'staff_list': 'ทีมช่างเทคนิค',
      'no_staff': 'ไม่พบข้อมูลช่าง',
      'btn_reject': 'ไม่อนุมัติ',
      'btn_approve': 'อนุมัติ/จ่ายงาน',
      'reject_success': 'ปฏิเสธงานเรียบร้อย',
      'success_assign': 'มอบหมายงานสำเร็จ',
      'reporter': 'ผู้แจ้ง',
      'dorm': 'หอพัก',
      'room': 'ห้อง',
      'category': 'หมวดหมู่',
      'desc': 'อาการ',
      'no_data': 'ไม่พบข้อมูล',
      'all_buildings': 'ทุกตึก',
      'appt_date': 'วันนัดหมาย',
      'tech_accepted': 'ช่างรับงานแล้ว',
      'tech_responsible': 'ช่างผู้รับผิดชอบ',
      'wait_tech': 'รอช่างกดรับงาน...',
      'view_detail': 'จัดการ',
      'tab_news': 'ข่าวสาร',
      'tab_noti': 'แจ้งเตือน',
      'noti_empty': 'ไม่มีข้อมูลใหม่',
      'noti_new_job': 'มีงานใหม่รอตรวจสอบ',
      'noti_tech_accepted': 'ช่างรับงานแล้ว',
      'noti_completed': 'งานเสร็จสิ้น',
    },
    'en': {
      'welcome': 'Hello,',
      'role': 'Dorm Manager',
      'building_label': 'Area:',
      'list_header': 'Recent Requests',
      'pending': 'To Review',
      'working': 'In Progress',
      'completed': 'Closed',
      'menu_title': 'Management',
      'menu_announce': 'News',
      'menu_staff': 'Techs',
      'menu_report': 'Report',
      'nav_home': 'Home',
      'nav_history': 'History',
      'nav_more': 'Menu',
      'more_menu': 'More Menu',
      'notification': 'Notification',
      'notification_on': 'Enabled',
      'notification_off': 'Disabled',
      'language': 'Language',
      'contact_staff': 'Contact Staff',
      'coming_soon_title': 'Coming soon',
      'coming_soon_msg': 'This feature will be available soon',
      'contact_msg': 'If you have issues,\nContact 053-916-xxx\nor Line: @mfu_fixflow',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure?',
      'exit': 'Exit',
      'ok': 'OK',
      'no_jobs': 'Great! No pending tasks.',
      'assign_title': 'Assign Technician',
      'assign_desc': 'Select a tech (Number is workload)',
      'btn_cancel': 'Cancel',
      'btn_assign': 'Assign',
      'dialog_title': 'Details',
      'urgent_badge': 'URGENT',
      'tel': 'Call',
      'success_post': 'Posted',
      'post_title': 'New Announcement',
      'post_hint_title': 'Title',
      'post_hint_desc': 'Description...',
      'btn_post': 'Post',
      'staff_list': 'Technician Team',
      'no_staff': 'No technicians found',
      'btn_reject': 'Reject',
      'btn_approve': 'Approve',
      'reject_success': 'Rejected',
      'success_assign': 'Assigned',
      'reporter': 'Reporter',
      'dorm': 'Dorm',
      'room': 'Room',
      'category': 'Category',
      'desc': 'Issue',
      'no_data': 'No data',
      'all_buildings': 'All',
      'appt_date': 'Appointment',
      'tech_accepted': 'Accepted',
      'tech_responsible': 'Responsible',
      'wait_tech': 'Waiting...',
      'view_detail': 'Manage',
      'tab_news': 'News',
      'tab_noti': 'Alerts',
      'noti_empty': 'No new alerts',
      'noti_new_job': 'New job pending review',
      'noti_tech_accepted': 'Technician accepted',
      'noti_completed': 'Job completed',
    },
  };

  String tr(String key) => _translations[_currentLanguageCode]?[key] ?? key;

  String _formatDateTime(String? iso) {
    if (iso == null) return "-";
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadLanguage();
    _loadManagerProfile();
    _fetchTechniciansBase();
    _loadNotificationStatus();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  Future<void> _loadNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('notification_enabled') ?? true;
    if (mounted) {
      setState(() => _isNotificationEnabled = isEnabled);
    }
  }

  Future<void> _toggleNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_enabled', enabled);
    setState(() => _isNotificationEnabled = enabled);
  }

  Future<void> _loadManagerProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final profile = await supabase.from('profiles').select().eq('id', user.id).single();
        setState(() {
          _managerName = profile['full_name'] ?? "Manager";
          _managerId = user.id;
          _myBuilding = profile['responsible_building'];
          _isProfileLoaded = true;
        });
      } catch (e) {
        setState(() {
          _managerName = user.userMetadata?['full_name'] ?? "Manager";
          _managerId = user.id;
          _isProfileLoaded = true;
        });
      }
    }
  }

  Future<void> _fetchTechniciansBase() async {
    try {
      final techsData = await supabase.from('profiles').select().eq('role', 'technician');
      if (mounted) setState(() => _technicians = List<Map<String, dynamic>>.from(techsData));
    } catch (e) {
      debugPrint("Tech Error: $e");
    }
  }

  List<Map<String, dynamic>> _calculateTechnicianLoad(List<Map<String, dynamic>> allTickets) {
    final activeJobs = allTickets.where((t) => t['status'] == 'approved' || t['status'] == 'in_progress').toList();
    List<Map<String, dynamic>> techsWithLoad = [];
    for (var tech in _technicians) {
      int load = activeJobs.where((job) => job['technician_id'] == tech['id']).length;
      Map<String, dynamic> techMap = Map.from(tech);
      techMap['workload'] = load;
      techsWithLoad.add(techMap);
    }
    techsWithLoad.sort((a, b) => (a['workload'] as int).compareTo(b['workload'] as int));
    return techsWithLoad;
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
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

  Stream<List<Map<String, dynamic>>> _getTicketStream() {
    final building = _myBuilding;
    if (building != null && building.isNotEmpty && building != 'All') {
      return supabase.from('tickets').stream(primaryKey: ['id']).eq('dorm_building', building).order('created_at', ascending: false);
    }
    return supabase.from('tickets').stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: !_isProfileLoaded
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getTicketStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final allTickets = snapshot.data!;
                int pendingCount = allTickets.where((t) => t['status'] == 'pending').length;
                int inProgressCount = allTickets.where((t) => t['status'] == 'approved' || t['status'] == 'in_progress').length;
                int completedCount = allTickets.where((t) => t['status'] == 'completed').length;

                List<Map<String, dynamic>> activeList = allTickets.where((t) {
                  String s = t['status'] ?? 'pending';
                  return s == 'pending' || s == 'approved' || s == 'in_progress';
                }).toList();

                activeList.sort((a, b) {
                  bool urgentA = (a['description'] ?? '').toString().contains('ด่วน');
                  bool urgentB = (b['description'] ?? '').toString().contains('ด่วน');
                  if (urgentA && !urgentB) return -1;
                  if (!urgentA && urgentB) return 1;
                  if (a['status'] == 'pending' && b['status'] != 'pending') return -1;
                  if (a['status'] != 'pending' && b['status'] == 'pending') return 1;
                  return 0;
                });

                final techsWithLoad = _calculateTechnicianLoad(allTickets);

                return Stack(
                  children: [
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_gradStart, _gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                        boxShadow: [BoxShadow(color: _gradEnd.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                    ),
                    SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.manage_accounts, color: _gradEnd, size: 30)),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(tr('welcome'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                        Text(_managerName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                          child: Text("${tr('building_label')} ${_myBuilding == null || _myBuilding == 'All' ? tr('all_buildings') : _myBuilding}", style: const TextStyle(color: Colors.white, fontSize: 10)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () => _showNotificationSheet(allTickets),
                                      icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 28),
                                      style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                                    ),
                                    if (pendingCount > 0)
                                      Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: Text(pendingCount > 9 ? '9+' : '$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                _buildStatCard(pendingCount, tr('pending'), Colors.white, _colPending),
                                const SizedBox(width: 10),
                                _buildStatCard(inProgressCount, tr('working'), Colors.white, _colActive),
                                const SizedBox(width: 10),
                                _buildStatCard(completedCount, tr('completed'), Colors.white, _colDone, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerHistoryScreen()))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async { setState(() {}); },
                              color: _gradEnd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(child: _buildMenuButton(Icons.campaign_rounded, tr('menu_announce'), Colors.pink, _showPostDialog)),
                                        const SizedBox(width: 10),
                                        Expanded(child: _buildMenuButton(Icons.people_alt_rounded, tr('menu_staff'), Colors.teal, () => _showStaffList(techsWithLoad))),
                                        const SizedBox(width: 10),
                                        Expanded(child: _buildMenuButton(Icons.bar_chart_rounded, tr('menu_report'), Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerReportScreen())))),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(children: [Text(tr('list_header'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), child: Text("${activeList.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)))]),
                                    const SizedBox(height: 15),
                                    Expanded(
                                      child: activeList.isEmpty
                                          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]), const SizedBox(height: 15), Text(tr('no_jobs'), style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500))]))
                                          : ListView.separated(
                                              padding: const EdgeInsets.only(bottom: 20),
                                              itemCount: activeList.length,
                                              separatorBuilder: (c, i) => const SizedBox(height: 15),
                                              itemBuilder: (context, index) => _buildVibrantTicketCard(activeList[index], techsWithLoad),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 0) {
              setState(() => _selectedIndex = 0);
            } else if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerHistoryScreen()));
            } else if (index == 2) {
              _showMoreMenu();
            }
          },
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: _gradEnd,
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: tr('nav_home')),
            BottomNavigationBarItem(icon: const Icon(Icons.history_rounded), label: tr('nav_history')), // ✅ ปุ่มประวัติ
            BottomNavigationBarItem(icon: const Icon(Icons.grid_view_rounded), label: tr('nav_more')),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---
  
  // ✅ เพิ่ม Widget นี้ให้แล้วครับ เพื่อแก้ Error _buildEmptyStateInSheet
  Widget _buildEmptyStateInSheet() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(tr('noti_empty'), style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildStatCard(int count, String label, Color bg, Color accent, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Column(
            children: [
              Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(12), elevation: 2, shadowColor: Colors.grey.withOpacity(0.2), child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))]))));
  }

  Widget _buildVibrantTicketCard(Map<String, dynamic> ticket, List<Map<String, dynamic>> techsList) {
    String status = ticket['status'] ?? 'pending';
    bool isUrgent = (ticket['description'] ?? '').toString().contains('ด่วน');
    Color themeColor = status == 'pending' ? _colPending : _colActive;
    String statusText = status == 'pending' ? tr('pending') : tr('working');
    IconData statusIcon = status == 'pending' ? Icons.hourglass_empty_rounded : Icons.handyman_rounded;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(20), onTap: () => _showTicketDetailDialog(ticket, techsList), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(statusIcon, color: themeColor, size: 26)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(ticket['category'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87), maxLines: 1)), if (isUrgent) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _colUrgent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(tr('urgent_badge'), style: TextStyle(color: _colUrgent, fontSize: 10, fontWeight: FontWeight.bold)))]), const SizedBox(height: 4), Row(children: [Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Expanded(child: Text("${ticket['dorm_building']} / ${ticket['room_number']}", style: TextStyle(fontSize: 14, color: Colors.grey[600]), maxLines: 1))])]))]),
        const SizedBox(height: 15), Divider(height: 1, color: Colors.grey[200]), const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(statusText, style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold))), Row(children: [Text(tr('view_detail'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _gradEnd)), const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 16, color: _gradEnd)])])
      ])))),
    );
  }

  void _showTicketDetailDialog(Map<String, dynamic> ticket, List<Map<String, dynamic>> techsList) {
    String techName = '-';
    if (ticket['technician_id'] != null) {
      final tech = techsList.firstWhere((t) => t['id'] == ticket['technician_id'], orElse: () => {'full_name': 'Unknown'});
      techName = tech['full_name'];
    }

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) {
      return DraggableScrollableSheet(initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false, builder: (_, controller) {
        return SingleChildScrollView(controller: controller, padding: const EdgeInsets.fromLTRB(24, 10, 24, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 25),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(tr('dialog_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), if (ticket['status'] == 'pending') Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _colPending.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(tr('pending'), style: TextStyle(color: _colPending, fontWeight: FontWeight.bold)))]), const SizedBox(height: 20),
          if (ticket['image_url'] != null) ...[ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(ticket['image_url'], width: double.infinity, height: 200, fit: BoxFit.cover)), const SizedBox(height: 15)],
          
          if (ticket['appointment_date'] != null) Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.calendar_month, color: Colors.blue.shade700), const SizedBox(width: 8), Text(tr('appt_date'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700))]), const SizedBox(height: 4), Text(_formatDateTime(ticket['appointment_date']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), if (techName != '-') ...[const SizedBox(height: 8), Text("${tr('tech_responsible')}: $techName", style: TextStyle(fontSize: 13, color: Colors.grey[700]))]])),
          if (ticket['technician_id'] != null && ticket['appointment_date'] == null) Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.person, color: Colors.purple), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('tech_responsible'), style: const TextStyle(fontSize: 12, color: Colors.purple)), Text(techName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]))])),

          _buildDetailRow(Icons.category_outlined, tr('category'), ticket['category']), _buildDetailRow(Icons.notes_outlined, tr('desc'), ticket['description']),
          Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.place_outlined, size: 22, color: _gradEnd), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('room'), style: const TextStyle(fontSize: 12, color: Colors.grey)), Text("${ticket['dorm_building']} / ${ticket['room_number']}", style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500))]))])),
          Container(margin: const EdgeInsets.symmetric(vertical: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(15)), child: Row(children: [const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.grey)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('reporter'), style: const TextStyle(fontSize: 12, color: Colors.grey)), Text("${ticket['contact_name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])), IconButton(onPressed: () => _makePhoneCall(ticket['contact_phone'] ?? ''), icon: const Icon(Icons.phone), color: Colors.green)])),
          
          const SizedBox(height: 25),
          if (ticket['status'] == 'pending') ...[SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showAssignDialog(ticket, techsList); }, icon: const Icon(Icons.assignment_ind), label: Text(tr('btn_approve')), style: ElevatedButton.styleFrom(backgroundColor: _gradEnd, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: TextButton(onPressed: () { Navigator.pop(context); _rejectTicket(ticket['id']); }, child: Text(tr('btn_reject'), style: TextStyle(color: _colUrgent))))],
          if (ticket['status'] == 'approved') Center(child: Text(tr('wait_tech'), style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic))),
          const SizedBox(height: 20),
        ]));
      });
    });
  }

  void _showAssignDialog(Map<String, dynamic> ticket, List<Map<String, dynamic>> techsList) {
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(tr('assign_title'), style: const TextStyle(fontWeight: FontWeight.bold)), content: SizedBox(width: double.maxFinite, height: 350, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr('assign_desc'), style: TextStyle(fontSize: 12, color: Colors.grey[600])), const SizedBox(height: 15), Expanded(child: techsList.isEmpty ? Center(child: Text(tr('no_staff'))) : ListView.separated(itemCount: techsList.length, separatorBuilder: (c, i) => const Divider(), itemBuilder: (context, index) { final tech = techsList[index]; final workload = tech['workload'] ?? 0; return ListTile(leading: CircleAvatar(backgroundColor: workload > 5 ? _colUrgent.withOpacity(0.1) : _colDone.withOpacity(0.1), child: Text("$workload", style: TextStyle(color: workload > 5 ? _colUrgent : _colDone, fontWeight: FontWeight.bold))), title: Text(tech['full_name'] ?? 'Unknown'), subtitle: Text(workload > 5 ? "งานเยอะ" : "ว่าง", style: TextStyle(fontSize: 12, color: workload > 5 ? _colUrgent : _colDone)), trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey), onTap: () { _confirmAssign(ticket['id'], tech['id'], tech['full_name']); Navigator.pop(context); }); }))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('btn_cancel')))]));
  }

  Future<void> _confirmAssign(dynamic ticketId, String techId, String techName) async {
    try { await supabase.from('tickets').update({'status': 'approved', 'manager_name': _managerName, 'manager_id': _managerId, 'technician_id': techId, 'approved_at': DateTime.now().toIso8601String()}).eq('id', ticketId); if (mounted) _showNotification("${tr('success_assign')} -> $techName"); } catch (e) { debugPrint("Assign Error: $e"); }
  }

  Future<void> _rejectTicket(dynamic ticketId) async {
    try {
      await supabase
          .from('tickets')
          .update({
            'status': 'rejected',
            'manager_name': _managerName,
            'manager_id': _managerId,
          })
          .eq('id', ticketId);
      
      if (mounted) {
        _showNotification(tr('reject_success'), isError: false);
        debugPrint('✅ Ticket rejected successfully: $ticketId');
      }
    } catch (e) {
      debugPrint('❌ Reject error: $e');
      if (mounted) {
        _showNotification('เกิดข้อผิดพลาด: $e', isError: true);
      }
    }
  }

  void _showPostDialog() {
    final titleCtrl = TextEditingController(); final contentCtrl = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: Text(tr('post_title'), style: const TextStyle(fontWeight: FontWeight.bold)), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: titleCtrl, decoration: InputDecoration(labelText: tr('post_hint_title'), border: const OutlineInputBorder())), const SizedBox(height: 10), TextField(controller: contentCtrl, decoration: InputDecoration(labelText: tr('post_hint_desc'), border: const OutlineInputBorder()), maxLines: 3)]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('btn_cancel'))), ElevatedButton(onPressed: () async { if (titleCtrl.text.isEmpty) return; await supabase.from('announcements').insert({'title': titleCtrl.text, 'content': contentCtrl.text, 'created_by': _managerName, 'target_group': 'student'}); if (mounted) { Navigator.pop(c); _showNotification(tr('success_post')); } }, style: ElevatedButton.styleFrom(backgroundColor: _gradEnd, foregroundColor: Colors.white), child: Text(tr('btn_post')))]));
  }

  void _showStaffList(List<Map<String, dynamic>> techsList) {
    showDialog(context: context, builder: (c) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: Text(tr('staff_list'), style: const TextStyle(fontWeight: FontWeight.bold)), content: SizedBox(width: double.maxFinite, height: 300, child: techsList.isEmpty ? Center(child: Text(tr('no_staff'))) : ListView.separated(itemCount: techsList.length, separatorBuilder: (c, i) => const Divider(), itemBuilder: (c, i) { final tech = techsList[i]; return ListTile(leading: CircleAvatar(backgroundColor: Colors.teal.withOpacity(0.1), child: const Icon(Icons.person, color: Colors.teal)), title: Text(tech['full_name'] ?? 'Unknown'), subtitle: Text("งานค้าง: ${tech['workload'] ?? 0}")); })), actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('btn_cancel')))]));
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 22, color: _gradEnd), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value ?? "-", style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500))]))]));
  }

  void _showNotificationSheet(List<Map<String, dynamic>> allTickets) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (context) {
      return DefaultTabController(length: 2, child: Container(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), height: MediaQuery.of(context).size.height * 0.75, child: Column(children: [
        Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 16),
        Container(decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(12)), child: TabBar(indicator: BoxDecoration(color: _gradEnd, borderRadius: BorderRadius.circular(12)), labelColor: Colors.white, unselectedLabelColor: Colors.grey[600], indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent, tabs: [Tab(text: tr('tab_news'), icon: const Icon(Icons.campaign_rounded)), Tab(text: tr('tab_noti'), icon: const Icon(Icons.notifications_active_rounded))])),
        const SizedBox(height: 16),
        Expanded(child: TabBarView(children: [_buildNewsTab(), _buildJobNotiTab(allTickets)])),
      ])));
    });
  }

  // ✅ ปรับ News Tab ให้สวยงามตามที่ขอ
  Widget _buildNewsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('announcements').select().order('created_at', ascending: false).limit(10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _gradEnd));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyStateInSheet();
        final news = snapshot.data!;
        return ListView.separated(
          itemCount: news.length,
          separatorBuilder: (c, i) => Divider(color: Colors.grey[200]),
          itemBuilder: (context, index) {
            final item = news[index];
            final date = DateFormat('dd/MM/yyyy').format(DateTime.parse(item['created_at']));
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.article, color: Colors.blue)),
              title: Text(item['title'] ?? 'ประกาศ', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            );
          },
        );
      },
    );
  }

  Widget _buildJobNotiTab(List<Map<String, dynamic>> allTickets) {
    final items = allTickets.take(20).toList();
    if (items.isEmpty) return _buildEmptyStateInSheet();
    return ListView.separated(itemCount: items.length, separatorBuilder: (c, i) => Divider(color: Colors.grey[100]), itemBuilder: (context, index) { final item = items[index]; final status = item['status'] ?? 'pending'; IconData icon = Icons.info; Color color = Colors.grey; String title = ""; if (status == 'pending') { title = tr('noti_new_job'); icon = Icons.new_releases; color = Colors.orange; } else if (status == 'in_progress') { title = tr('noti_tech_accepted'); icon = Icons.handyman; color = Colors.blue; } else if (status == 'completed') { title = tr('noti_completed'); icon = Icons.check_circle; color = Colors.green; } else { title = "Status: $status"; } return ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("${item['category']} - ${item['dorm_building']} ${item['room_number']}"), onTap: () { Navigator.pop(context); _showTicketDetailDialog(item, []); }); });
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
                            _toggleNotification(val);
                            setModalState(() => _isNotificationEnabled = val);
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
                        icon: Icons.support_agent_rounded,
                        title: tr('contact_staff'),
                        subtitle: tr('coming_soon_msg'),
                        onTap: () => _showComingSoonDialog(context),
                      ),
                      const SizedBox(height: 10),
                      _buildMoreMenuTile(
                        icon: Icons.logout,
                        title: tr('logout'),
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

  void _showContactDialog(BuildContext context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr('contact_staff')),
          content: Text(tr('contact_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('ok')),
            ),
          ],
        ),
      );

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
                            tr('logout'),
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
                      child: Text(tr('ok')),
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
                      child: Text(tr('logout')),
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