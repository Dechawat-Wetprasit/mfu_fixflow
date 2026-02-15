import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mfu_fixflow/features/auth/role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _language = 'th';
  late AnimationController _animationController;

  late final StreamSubscription<AuthState> _authSubscription;

  late Map<String, Map<String, String>> _translations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _initTranslations();
    _checkCurrentSession();
    _setupAuthListener();
  }

  void _initTranslations() {
    _translations = {
      'th': {
        'title': 'MFU FIXFLOW',
        'subtitle': 'ระบบแจ้งซ่อมออนไลน์',
        'for_student': 'สำหรับนักเรียน',
        'student_btn': 'เข้าสู่ระบบด้วยอีเมล Lamduan',
        'for_staff': 'สำหรับเจ้าหน้าที่ (Staff/Admin)',
        'email': 'อีเมล',
        'password': 'รหัสผ่าน',
        'staff_login': 'เข้าสู่ระบบเจ้าหน้าที่',
        'error_email': 'กรุณากรอกอีเมล',
        'error_password': 'กรุณากรอกรหัสผ่าน',
        'lang_th': 'ไทย',
        'lang_en': 'English',
      },
      'en': {
        'title': 'MFU FIXFLOW',
        'subtitle': 'Online Repair Request System',
        'for_student': 'For Students',
        'student_btn': 'Login with Lamduan Mail',
        'for_staff': 'For Staff (Staff/Admin)',
        'email': 'Email',
        'password': 'Password',
        'staff_login': 'Staff Login',
        'error_email': 'Please enter email',
        'error_password': 'Please enter password',
        'lang_th': 'ไทย',
        'lang_en': 'English',
      },
    };
  }

  String tr(String key) => _translations[_language]?[key] ?? key;

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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

  Future<void> _staffLogin() async {
    if (_emailController.text.trim().isEmpty) {
      _showError(tr('error_email'));
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError(tr('error_password'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      _showError(e.message);
      setState(() => _isLoading = false);
    } catch (e) {
      _showError("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _studentLogin() async {
    try {
      // ใช้ redirect URL ที่แตกต่างกันสำหรับ web และ mobile
      final redirectUrl = kIsWeb 
          ? Uri.base.toString() // ใช้ URL ของ web ที่ deploy ไว้
          : 'mfufixflow://login-callback'; // ใช้ deep link สำหรับ mobile
      
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        queryParams: {
          'hd': 'lamduan.mfu.ac.th',
        },
      );
    } catch (e) {
      _showError("Google Sign-In Error: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageBubble() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageButton('th', tr('lang_th')),
          const SizedBox(width: 4),
          _buildLanguageButton('en', tr('lang_en')),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String langCode, String label) {
    final isSelected = _language == langCode;
    return GestureDetector(
      onTap: () => setState(() => _language = langCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA51C30) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFA51C30),
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo with Animation
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFA51C30), Color(0xFF8B1428)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA51C30).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    tr('title'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFA51C30),
                      letterSpacing: 0.6,
                    ),
                  ),
                  
                  const SizedBox(height: 3),

                  // Subtitle
                  Text(
                    tr('subtitle'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 18),

                  // Content Padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        // Language Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLanguageButton('th', tr('lang_th')),
                              const SizedBox(width: 2),
                              _buildLanguageButton('en', tr('lang_en')),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- Student Section Card ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4285F4).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.school_outlined,
                                      size: 18,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    tr('for_student'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: _studentLogin,
                                  icon: const Icon(Icons.mail_outline, size: 16),
                                  label: Text(
                                    tr('student_btn'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4285F4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Divider with Text
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'หรือ',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // --- Staff Section Card ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA51C30).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.badge_outlined,
                                      size: 18,
                                      color: Color(0xFFA51C30),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    tr('for_staff'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              _buildTextField(
                                tr('email'),
                                Icons.mail_outline,
                                _emailController,
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                tr('password'),
                                Icons.lock_outline,
                                _passwordController,
                                obscure: true,
                              ),
                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _staffLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFA51C30),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation(Colors.grey[700]),
                                          ),
                                        )
                                      : Text(
                                          tr('staff_login'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
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
}