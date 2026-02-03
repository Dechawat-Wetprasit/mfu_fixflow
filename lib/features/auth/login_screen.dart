import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mfu_fixflow/features/auth/role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkCurrentSession();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkCurrentSession() {
    final session = supabase.auth.currentSession;
    if (session != null) {
      _redirectUser();
    }
  }

  void _setupAuthListener() {
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _redirectUser();
      }
    });
  }

  void _redirectUser() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  // 1. Staff Login (Email/Password)
  Future<void> _staffLogin() async {
    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Listener will handle redirection
    } on AuthException catch (e) {
      _showError(e.message);
      setState(() => _isLoading = false);
    } catch (e) {
      _showError("An error occurred: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. Student Login (Google - Lamduan Only)
  Future<void> _studentLogin() async {
    try {
      // ⚠️ แก้ตรงนี้ครับ: เปลี่ยนเป็น mfufixflow://login-callback
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'mfufixflow://login-callback',
        queryParams: {
          'hd': 'lamduan.mfu.ac.th', // Restrict to university email
        },
      );
    } catch (e) {
      _showError("Google Sign-In Error: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, size: 80, color: Color(0xFFA51C30)),
                const SizedBox(height: 10),
                const Text(
                  "MFU FIXFLOW",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA51C30),
                    letterSpacing: 2,
                  ),
                ),
                const Text(
                  "Online Repair Request System",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 50),

                // --- 🎓 Section 1: Student ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "For Students",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _studentLogin,
                    icon: const Icon(Icons.school, color: Colors.white),
                    label: const Text(
                      "Login with Lamduan Mail",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Staff Only",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 20),

                // --- 👔 Section 2: Staff ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "For Staff (Staff/Admin)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA51C30),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _staffLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFA51C30),
                      side: const BorderSide(color: Color(0xFFA51C30)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Staff Login"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
