import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mfu_fixflow/features/dashboard/home_screen.dart';
import 'package:mfu_fixflow/features/admin/technician_screen.dart';
import 'package:mfu_fixflow/features/admin/manager_screen.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // เรียกหลังจาก build เสร็จเพื่อความปลอดภัย
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoleAndRedirect();
    });
  }

  Future<void> _checkRoleAndRedirect() async {
    final session = supabase.auth.currentSession;

    // 1. ถ้าไม่มี Session ให้กลับไปหน้า Login
    if (session == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    final user = session.user;
    final email = user.email ?? '';

    // 2. เช็ค Domain (ป้องกันคนนอก)
    bool isStudent = email.endsWith('@lamduan.mfu.ac.th');
    bool isStaff = email.endsWith('@mfu.ac.th');

    // *สำหรับการทดสอบ: อนุญาต gmail ทั่วไปได้ถ้าต้องการ (ลบออกเมื่อขึ้น Production)*
    // bool isTestUser = email.endsWith('@gmail.com');

    if (!isStudent && !isStaff) {
      if (mounted) {
        _showErrorDialog("อีเมล $email ไม่ได้รับอนุญาตให้ใช้งานระบบนี้");
      }
      return;
    }

    // 3. กำหนดหน้าปลายทาง (Routing)
    Widget targetScreen;

    // TODO: แนะนำให้เปลี่ยนไปเช็คจาก Table 'profiles' ใน Database แทนการ Hardcode
    if (email == 'manager@mfu.ac.th') {
      targetScreen = const ManagerScreen();
    } else if (email == 'tech@mfu.ac.th') {
      targetScreen = const TechnicianScreen();
    } else {
      // Default: นักศึกษา หรือ Staff ทั่วไปที่ไม่ได้เป็น Tech/Manager
      targetScreen = const HomeScreen();
    }

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => targetScreen));
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text("ไม่สามารถเข้าใช้งานได้"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _logout();
            },
            child: const Text(
              "ตกลง (ออกจากระบบ)",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFA51C30),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              "กำลังตรวจสอบข้อมูลผู้ใช้...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
