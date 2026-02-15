import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import หน้าจอปลายทางต่างๆ
import 'package:mfu_fixflow/features/dashboard/home_screen.dart';
import 'package:mfu_fixflow/features/admin/technician_screen.dart';
import 'package:mfu_fixflow/features/admin/manager_screen.dart';
import 'package:mfu_fixflow/features/admin/user_management_screen.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // รอให้ Widget สร้างเสร็จก่อนค่อยเริ่มเช็คข้อมูล
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRedirect());
  }

  /// ฟังก์ชันหลักสำหรับตัดสินใจว่าจะพา User ไปหน้าไหน
  Future<void> _resolveRedirect() async {
    final session = _supabase.auth.currentSession;
    
    // 1. ถ้าไม่มี Session (ไม่ได้ล็อกอิน) ให้ดีดกลับไปหน้า Login
    if (session == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    final user = session.user;
    final email = user.email ?? '';
    final metadata = user.userMetadata;
    final role = metadata?['role'] as String?; // ดึงค่า role จาก DB

    // 2. ตรวจสอบ Domain (Security Check)
    // อนุญาตเฉพาะเมล @mfu.ac.th (บุคลากร) และ @lamduan.mfu.ac.th (นักศึกษา)
    final isStaff = email.endsWith('@mfu.ac.th');
    final isStudent = email.endsWith('@lamduan.mfu.ac.th');

    if (!isStaff && !isStudent) {
      if (mounted) _showAccessDeniedDialog(email);
      return;
    }

    // 3. Routing Logic: เลือกหน้าตาม Role
    Widget targetScreen;

    if (role == 'admin' || role == 'it_admin') {
      // Admin และ IT Admin ไปหน้า User Management โดยตรง
      targetScreen = const UserManagementScreen();
    } else if (role == 'manager') {
      targetScreen = const ManagerScreen();
    } else if (role == 'head_technician' || role == 'technician') {
      targetScreen = const TechnicianScreen();
    } else {
      // Default: ถ้าไม่ระบุ Role หรือเป็น role อื่นๆ ให้ไปหน้า Student/Home
      targetScreen = const HomeScreen();
    }

    // 4. ไปยังหน้าปลายทาง
    _navigateTo(targetScreen);
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    _navigateTo(const LoginScreen());
  }

  void _showAccessDeniedDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text("อีเมล $email ไม่ได้รับอนุญาตให้เข้าใช้งานระบบนี้"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("ออกจากระบบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI หน้า Loading ระหว่างรอตรวจสอบสิทธิ์
    return const Scaffold(
      backgroundColor: Color(0xFFA51C30), // สีธีมแม่ฟ้าหลวง
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              "กำลังตรวจสอบสิทธิ์การเข้าใช้งาน...",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }
}