import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mfu_fixflow/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_fixflow/features/auth/login_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  bool _isAuthorized = false;
  String _currentLanguageCode = 'th';

  final Color _gradStart = const Color(0xFF8E24AA);
  final Color _gradEnd = const Color(0xFF4A148C);

  final Map<String, Map<String, String>> _translations = {
    'th': {
      'title': 'จัดการผู้ใช้งาน',
      'search': 'ค้นหาชื่อหรืออีเมล...',
      'add_user': 'เพิ่มผู้ใช้',
      'no_users': 'ไม่พบข้อมูลผู้ใช้',
      'email': 'อีเมล',
      'full_name': 'ชื่อ-นามสกุล',
      'role': 'บทบาท',
      'building': 'อาคารที่รับผิดชอบ',
      'password': 'รหัสผ่าน',
      'edit': 'แก้ไข',
      'delete': 'ลบ',
      'cancel': 'ยกเลิก',
      'save': 'บันทึก',
      'confirm': 'ยืนยัน',
      'create_user': 'สร้างผู้ใช้ใหม่',
      'edit_user': 'แก้ไขผู้ใช้',
      'delete_confirm': 'ยืนยันการลบผู้ใช้?',
      'logout_confirm': 'ต้องการออกจากระบบหรือไม่?',
      'success_create': 'สร้างผู้ใช้สำเร็จ',
      'success_update': 'อัพเดทสำเร็จ',
      'success_delete': 'ลบสำเร็จ',
      'error': 'เกิดข้อผิดพลาด',
      'manager': 'ผู้จัดการหอพัก',
      'technician': 'ช่างเทคนิค',
      'head_technician': 'หัวหน้าช่าง',
      'select_role': 'เลือกบทบาท',
      'select_building': 'เลือกอาคาร',
      'all_buildings': 'ทุกอาคาร',
      'required_email': 'กรุณากรอกอีเมล',
      'required_password': 'กรุณากรอกรหัสผ่าน (6 ตัวอักษรขึ้นไป)',
      'required_name': 'กรุณากรอกชื่อ-นามสกุล',
      'required_role': 'กรุณาเลือกบทบาท',
      'unauthorized': 'ไม่มีสิทธิ์เข้าถึง',
      'unauthorized_msg': 'เฉพาะ IT Admin เท่านั้นที่สามารถจัดการผู้ใช้ได้',
      'back': 'กลับ',
      'logout': 'ออกจากระบบ',
    },
    'en': {
      'title': 'User Management',
      'search': 'Search name or email...',
      'add_user': 'Add User',
      'no_users': 'No users found',
      'email': 'Email',
      'full_name': 'Full Name',
      'role': 'Role',
      'building': 'Responsible Building',
      'password': 'Password',
      'edit': 'Edit',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'save': 'Save',
      'confirm': 'Confirm',
      'create_user': 'Create New User',
      'edit_user': 'Edit User',
      'delete_confirm': 'Confirm delete user?',
      'logout_confirm': 'Do you want to logout?',
      'success_create': 'User created successfully',
      'success_update': 'Updated successfully',
      'success_delete': 'Deleted successfully',
      'error': 'Error occurred',
      'manager': 'Manager',
      'technician': 'Technician',
      'head_technician': 'Head Technician',
      'select_role': 'Select Role',
      'select_building': 'Select Building',
      'all_buildings': 'All Buildings',
      'required_email': 'Please enter email',
      'unauthorized': 'Unauthorized',
      'unauthorized_msg': 'Only IT Admins can access user management',
      'back': 'Back',
      'logout': 'Logout',
      'required_password': 'Please enter password (6+ characters)',
      'required_name': 'Please enter full name',
      'required_role': 'Please select role',
    },
  };

  final List<String> _buildings = [
    'L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7',
    'F1', 'F2', 'F3', 'F4', 'F5', 'F6',
    'Sak thong 1', 'Sak thong 2',
    'Prasert',
    'Polgenpao',
  ];

  String? _normalizeBuilding(dynamic building) {
    if (building == null) return null;
    final value = building.toString().trim();
    if (value.isEmpty) return null;
    if (value.toLowerCase() == 'all') return null;
    if (!_buildings.contains(value)) return null;
    return value;
  }

  Map<String, dynamic>? _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Buffer (seconds) before expiry to trigger refresh. Use 5 min to avoid Invalid JWT at Edge.
  static const int _tokenRefreshBufferSec = 300;

  Future<Session?> _getValidSession() async {
    final current = supabase.auth.currentSession;
    if (current == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = current.expiresAt;

    if (expiresAt != null && (expiresAt - now) > _tokenRefreshBufferSec) {
      return current;
    }

    try {
      debugPrint('Token expiring or expired. Refreshing...');
      final response = await supabase.auth.refreshSession();

      if (response.session != null) {
        final payload = _decodeJwt(response.session!.accessToken);
        debugPrint('Refreshed Token exp: ${payload?['exp']}');
        return response.session;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      return null;
    }
  }

  /// ดึง session ที่ refresh แล้วสำหรับเรียก Edge Function (ลดโอกาส Invalid JWT)
  Future<Session?> _getSessionForEdgeFunction() async {
    try {
      final response = await supabase.auth.refreshSession();
      // ใช้ session จาก response เท่านั้น ถ้า null ให้เช็คด้วย _getValidSession (ไม่ใช้ currentSession ตรงๆ เพราะอาจเป็น token เก่าหมดอายุ)
      if (response.session != null) return response.session;
      return await _getValidSession();
    } catch (e) {
      debugPrint('Error getting session for Edge Function: $e');
      return await _getValidSession();
    }
  }

  String tr(String key) => _translations[_currentLanguageCode]?[key] ?? key;

  Future<Map<String, dynamic>> _invokeManageUsers(
    Map<String, dynamic> body,
    String accessToken,
  ) async {
    final token = accessToken.trim();
    if (token.isEmpty) throw Exception('No access token');
    final url = Uri.parse('$supabaseUrl/functions/v1/manage-users');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorMessage = decoded['error']?.toString() ??
        decoded['message']?.toString() ??
        response.body;
    throw Exception('HTTP ${response.statusCode}: $errorMessage');
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _checkAuthorization();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _checkAuthorization() async {
    final session = await _getValidSession();
    final user = session?.user ?? supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isAuthorized = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      setState(() {
        // เฉพาะ IT Admin หรือ Admin เท่านั้นที่เข้าได้
        _isAuthorized = profile['role'] == 'admin' || profile['role'] == 'it_admin';
        if (_isAuthorized) {
          _loadUsers();
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      debugPrint('Error checking authorization: $e');
      setState(() {
        _isAuthorized = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguageCode = prefs.getString('language_code') ?? 'th';
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // ดึงข้อมูลผู้ใช้จาก profiles table (ทุก role ยกเว้น student)
      final data = await supabase
          .from('profiles')
          .select()
          .or('role.eq.admin,role.eq.it_admin,role.eq.manager,role.eq.technician,role.eq.head_technician')
          .order('created_at', ascending: false);

      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(data);
        _filteredUsers = _allUsers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['full_name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _showCreateUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String? selectedRole;
    String? selectedBuilding;
    bool _obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gradStart, _gradEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_add, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          tr('create_user'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: tr('email'),
                            hintText: 'example@mfu.ac.th',
                            prefixIcon: Icon(Icons.email_outlined, color: _gradEnd),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _gradEnd, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: tr('password'),
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outline, color: _gradEnd),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setDialogState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _gradEnd, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          obscureText: _obscurePassword,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: tr('full_name'),
                            hintText: 'John Doe',
                            prefixIcon: Icon(Icons.person_outline, color: _gradEnd),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _gradEnd, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: tr('role'),
                            prefixIcon: Icon(Icons.badge_outlined, color: _gradEnd),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _gradEnd, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          value: selectedRole,
                          items: [
                            DropdownMenuItem<String?>(value: 'admin', child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings, size: 20, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                const Text('Admin'),
                              ],
                            )),
                            DropdownMenuItem<String?>(value: 'it_admin', child: Row(
                              children: [
                                Icon(Icons.computer, size: 20, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text('IT Admin'),
                              ],
                            )),
                            DropdownMenuItem<String?>(value: 'manager', child: Row(
                              children: [
                                Icon(Icons.business_center, size: 20, color: Colors.purple.shade700),
                                const SizedBox(width: 8),
                                Text(tr('manager')),
                              ],
                            )),
                            DropdownMenuItem<String?>(value: 'technician', child: Row(
                              children: [
                                Icon(Icons.build, size: 20, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Text(tr('technician')),
                              ],
                            )),
                            DropdownMenuItem<String?>(value: 'head_technician', child: Row(
                              children: [
                                Icon(Icons.engineering, size: 20, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                Text(tr('head_technician')),
                              ],
                            )),
                          ],
                          onChanged: (value) => setDialogState(() => selectedRole = value),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: tr('building'),
                            prefixIcon: Icon(Icons.apartment, color: _gradEnd),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _gradEnd, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          value: selectedBuilding,
                          items: [
                            DropdownMenuItem<String?>(value: null, child: Row(
                              children: [
                                Icon(Icons.all_inclusive, size: 20, color: _gradEnd),
                                const SizedBox(width: 8),
                                Text(tr('all_buildings')),
                              ],
                            )),
                            ..._buildings.map((b) => DropdownMenuItem<String?>(
                              value: b, 
                              child: Row(
                                children: [
                                  Icon(Icons.domain, size: 20, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(b),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (value) => setDialogState(() => selectedBuilding = value),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          tr('cancel'),
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _createUser(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          fullName: nameController.text.trim(),
                          role: selectedRole,
                          building: selectedBuilding,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(tr('save'), style: const TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gradEnd,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
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
    );
  }

  Future<void> _createUser({
    required String email,
    required String password,
    required String fullName,
    required String? role,
    required String? building,
  }) async {
    // Validation
    if (email.isEmpty) {
      _showSnackBar(tr('required_email'), isError: true);
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showSnackBar(tr('required_password'), isError: true);
      return;
    }
    if (fullName.isEmpty) {
      _showSnackBar(tr('required_name'), isError: true);
      return;
    }
    if (role == null) {
      _showSnackBar(tr('required_role'), isError: true);
      return;
    }

    try {
      final session = await _getSessionForEdgeFunction();
      if (session == null) {
        _showSnackBar('กรุณาเข้าสู่ระบบใหม่', isError: true);
        return;
      }

      final data = await _invokeManageUsers({
        'action': 'create',
        'userData': {
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role,
          'responsible_building': building,
        },
      }, session.accessToken);

      if (data['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(tr('success_create'));
          _loadUsers();
        }
      } else {
        final errorMsg = data['error'] ?? 'Unknown error';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      if (mounted) {
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          _showSnackBar('ไม่มีสิทธิ์เข้าถึง กรุณาเข้าสู่ระบบใหม่', isError: true);
        } else {
          _showSnackBar('เกิดข้อผิดพลาด: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
        }
      }
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['full_name']);
    String? selectedRole = user['role'];
    String? selectedBuilding = _normalizeBuilding(user['responsible_building']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_gradStart, _gradEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          tr('edit_user'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: TextEditingController(text: user['email']),
                          decoration: InputDecoration(
                            labelText: tr('email'),
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          enabled: false,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: tr('full_name'),
                            hintText: 'John Doe',
                            prefixIcon: Icon(Icons.person_outline, color: _gradEnd),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _gradEnd, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: tr('role'),
                            prefixIcon: Icon(Icons.badge_outlined, color: _gradEnd),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _gradEnd, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          value: selectedRole,
                          items: [
                            DropdownMenuItem<String?>(value: 'admin', child: Row(
                              children: [
                                Icon(Icons.admin_panel_settings, size: 20, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                const Text('Admin'),
                              ],
                            )),
                            DropdownMenuItem<String?>(value: 'it_admin', child: Row(
                              children: [
                                Icon(Icons.computer, size: 20, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text('IT Admin'),
                              ],
                            )),
                            DropdownMenuItem<String?>(value: 'manager', child: Row(
                              children: [
                                Icon(Icons.business_center, size: 20, color: Colors.purple.shade700),
                                const SizedBox(width: 8),
                                Text(tr('manager')),
                              ],
                            )),
                            DropdownMenuItem<String?>(value: 'technician', child: Row(
                              children: [
                                Icon(Icons.build, size: 20, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Text(tr('technician')),
                              ],
                            )),
                            DropdownMenuItem<String?>(value: 'head_technician', child: Row(
                              children: [
                                Icon(Icons.engineering, size: 20, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                Text(tr('head_technician')),
                              ],
                            )),
                          ],
                          onChanged: (value) => setDialogState(() => selectedRole = value),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String?>(
                          decoration: InputDecoration(
                            labelText: tr('building'),
                            prefixIcon: Icon(Icons.apartment, color: _gradEnd),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _gradEnd, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          value: selectedBuilding,
                          items: [
                            DropdownMenuItem<String?>(value: null, child: Row(
                              children: [
                                Icon(Icons.all_inclusive, size: 20, color: _gradEnd),
                                const SizedBox(width: 8),
                                Text(tr('all_buildings')),
                              ],
                            )),
                            ..._buildings.map((b) => DropdownMenuItem<String?>(
                              value: b,
                              child: Row(
                                children: [
                                  Icon(Icons.domain, size: 20, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(b),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (value) => setDialogState(() => selectedBuilding = value),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          tr('cancel'),
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _updateUser(
                          userId: user['id'],
                          fullName: nameController.text.trim(),
                          role: selectedRole,
                          building: _normalizeBuilding(selectedBuilding),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(tr('save'), style: const TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gradEnd,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
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
    );
  }

  Future<void> _updateUser({
    required String userId,
    required String fullName,
    required String? role,
    required String? building,
  }) async {
    if (fullName.isEmpty) {
      _showSnackBar(tr('required_name'), isError: true);
      return;
    }
    if (role == null) {
      _showSnackBar(tr('required_role'), isError: true);
      return;
    }

    try {
      final session = await _getSessionForEdgeFunction();
      if (session == null) {
        _showSnackBar('กรุณาเข้าสู่ระบบใหม่', isError: true);
        return;
      }

      // เรียกใช้ Edge Function เพื่ออัพเดทผู้ใช้
      final data = await _invokeManageUsers({
        'action': 'update',
        'userData': {
          'user_id': userId,
          'full_name': fullName,
          'role': role,
          'responsible_building': building,
        },
      }, session.accessToken);

      if (data['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(tr('success_update'));
          _loadUsers();
        }
      } else {
        final errorMsg = data['error'] ?? 'Unknown error';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      if (mounted) {
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          _showSnackBar('ไม่มีสิทธิ์เข้าถึง กรุณาเข้าสู่ระบบใหม่', isError: true);
        } else {
          _showSnackBar('เกิดข้อผิดพลาด: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
        }
      }
    }
  }

  void _showDeleteConfirmDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr('confirm'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('delete_confirm'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        tr('cancel'),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteUser(userId);
                      },
                      icon: const Icon(Icons.delete_forever, size: 20),
                      label: Text(tr('delete'), style: const TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final session = await _getSessionForEdgeFunction();
      if (session == null) {
        _showSnackBar('กรุณาเข้าสู่ระบบใหม่', isError: true);
        return;
      }

      // เรียกใช้ Edge Function เพื่อลบผู้ใช้
      final data = await _invokeManageUsers({
        'action': 'delete',
        'userData': {
          'user_id': userId,
        },
      }, session.accessToken);

      if (data['success'] == true) {
        if (mounted) {
          _showSnackBar(tr('success_delete'));
          _loadUsers();
        }
      } else {
        final errorMsg = data['error'] ?? 'Unknown error';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      if (mounted) {
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          _showSnackBar('ไม่มีสิทธิ์เข้าถึง กรุณาเข้าสู่ระบบใหม่', isError: true);
        } else {
          _showSnackBar('เกิดข้อผิดพลาด: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
        }
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  String _getRoleDisplay(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'it_admin':
        return 'IT Admin';
      case 'manager':
        return tr('manager');
      case 'technician':
        return tr('technician');
      case 'head_technician':
        return tr('head_technician');
      default:
        return role ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ถ้าไม่มีสิทธิ์เข้าถึง ให้แสดงหน้า Unauthorized
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: CircularProgressIndicator(color: _gradEnd),
        ),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: _gradEnd,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            tr('title'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 80,
                  color: Colors.red.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  tr('unauthorized'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('unauthorized_msg'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gradEnd,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(tr('back')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // หน้าจัดการผู้ใช้ปกติ - Modern UI
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 0,
                children: [
                  Text(
                    tr('title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '${_filteredUsers.length} ${_currentLanguageCode == 'th' ? 'ผู้ใช้' : 'users'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.normal,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_gradStart, _gradEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: tr('logout'),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.logout_rounded,
                                  size: 48,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                tr('confirm'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr('logout_confirm'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        tr('cancel'),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        tr('logout'),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                    
                    if (confirm == true && mounted) {
                      await supabase.auth.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),

          // Modern Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: tr('search'),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search_rounded, color: _gradEnd, size: 24),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: _gradEnd, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
          ),

          // User List with Modern Cards
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : _filteredUsers.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.people_outline_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              tr('no_users'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentLanguageCode == 'th' 
                                  ? 'ลองค้นหาด้วยคำอื่น หรือเพิ่มผู้ใช้ใหม่'
                                  : 'Try different keywords or add a new user',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final user = _filteredUsers[index];
                            return _buildModernUserCard(user);
                          },
                          childCount: _filteredUsers.length,
                        ),
                      ),
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        elevation: 4,
        backgroundColor: _gradEnd,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: Text(
          tr('add_user'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // Helper method สำหรับสร้าง user card ที่ทันสมัย
  Widget _buildModernUserCard(Map<String, dynamic> user) {
    final roleColors = _getRoleColors(user['role']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEditUserDialog(user),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [roleColors['light']!, roleColors['dark']!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: roleColors['dark']!.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getRoleIcon(user['role']),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user['email'] ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Role and Building Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  roleColors['light']!.withOpacity(0.2),
                                  roleColors['dark']!.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: roleColors['dark']!.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRoleIcon(user['role']),
                                  size: 14,
                                  color: roleColors['dark'],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getRoleDisplay(user['role']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: roleColors['dark'],
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (user['responsible_building'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.apartment_rounded,
                                    size: 14,
                                    color: Colors.amber.shade800,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user['responsible_building'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Menu
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.more_vert_rounded, color: Colors.grey.shade700, size: 20),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'แก้ไข',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'ลบ',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditUserDialog(user);
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(
                        user['id'],
                        user['full_name'] ?? '-',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods สำหรับสีและไอคอนของ role
  Map<String, Color> _getRoleColors(String? role) {
    switch (role) {
      case 'admin':
        return {'light': Colors.red.shade400, 'dark': Colors.red.shade700};
      case 'it_admin':
        return {'light': Colors.blue.shade400, 'dark': Colors.blue.shade700};
      case 'manager':
        return {'light': Colors.purple.shade400, 'dark': Colors.purple.shade700};
      case 'head_technician':
        return {'light': Colors.green.shade400, 'dark': Colors.green.shade700};
      case 'technician':
        return {'light': Colors.orange.shade400, 'dark': Colors.orange.shade700};
      default:
        return {'light': Colors.grey.shade400, 'dark': Colors.grey.shade700};
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'it_admin':
        return Icons.computer_rounded;
      case 'manager':
        return Icons.business_center_rounded;
      case 'head_technician':
        return Icons.engineering_rounded;
      case 'technician':
        return Icons.build_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
