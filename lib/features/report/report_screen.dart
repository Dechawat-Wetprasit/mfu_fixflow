import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportScreen extends StatefulWidget {
  // Receive language code from previous screen (default to 'th')
  final String languageCode;
  const ReportScreen({super.key, this.languageCode = 'th'});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  // FEATURE: Selected Category Variable
  String? _selectedCategory;

  // FEATURE: Selected Dorm Building Variable
  String? _selectedDorm;

  // FEATURE: Dorm Buildings List
  final List<String> _dormBuildings = [
    'L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7',
    'F1', 'F2', 'F3', 'F4', 'F5', 'F6',
    'Sak thong 1', 'Sak thong 2',
    'Prasert',
    'Polgenpao',
  ];

  // FEATURE: Category List (Keys for translation)
  final List<String> _categories = [
    'cat_water',
    'cat_electric',
    'cat_ac',
    'cat_furniture',
    'cat_internet',
    'cat_other',
  ];

  // FEATURE: Dictionary for translations
  late Map<String, Map<String, String>> _translations;

  @override
  void initState() {
    super.initState();
    _initTranslations(); // Prepare translations
    _loadUserData();
  }

  void _initTranslations() {
    _translations = {
      'th': {
        'title': 'แจ้งซ่อม',
        'section_user': 'ข้อมูลผู้แจ้ง',
        'label_name': 'ชื่อ-สกุล (จากระบบ)',
        'label_phone': 'เบอร์โทร',
        'err_phone': 'กรุณากรอกเบอร์โทร',
        'label_dorm': 'หอพัก (เช่น F1)',
        'err_dorm': 'ระบุหอพัก',
        'label_room': 'เลขห้อง',
        'err_room': 'ระบุห้อง',
        'section_issue': 'รายละเอียดปัญหา',
        'label_category': 'หมวดหมู่ปัญหา', // New label
        'hint_category': 'เลือกหมวดหมู่', // New hint
        'err_category': 'กรุณาเลือกหมวดหมู่', // New error
        'hint_issue': 'เช่น แอร์ไม่เย็น, น้ำรั่ว',
        'err_issue': 'กรุณาระบุปัญหา',
        'btn_photo': 'ถ่ายรูป (จำเป็น)',
        'btn_retake': 'ถ่ายใหม่',
        'err_photo_req': '*ต้องแนบรูปภาพ',
        'btn_submit': 'ส่งแจ้งซ่อม',
        'msg_no_photo': 'กรุณาถ่ายรูปประกอบการแจ้งซ่อม',
        'msg_success': 'ส่งแจ้งซ่อมเรียบร้อย! ✅',
        'err_login': 'กรุณาเข้าสู่ระบบ',
        // Categories
        'cat_water': 'ประปา (น้ำรั่ว/ไม่ไหล)',
        'cat_electric': 'ไฟฟ้า (หลอดขาด/ไฟดับ)',
        'cat_ac': 'เครื่องปรับอากาศ',
        'cat_furniture': 'เฟอร์นิเจอร์/อุปกรณ์',
        'cat_internet': 'อินเทอร์เน็ต/Wifi',
        'cat_other': 'อื่นๆ',
      },
      'en': {
        'title': 'Report Issue',
        'section_user': 'Reporter Info',
        'label_name': 'Name (System)',
        'label_phone': 'Phone Number',
        'err_phone': 'Phone number required',
        'label_dorm': 'Dorm Building (e.g. F1)',
        'err_dorm': 'Dorm required',
        'label_room': 'Room No.',
        'err_room': 'Room required',
        'section_issue': 'Issue Details',
        'label_category': 'Category', // New label
        'hint_category': 'Select Category', // New hint
        'err_category': 'Please select a category', // New error
        'hint_issue': 'e.g. AC not cold, Water leak',
        'err_issue': 'Please describe the issue',
        'btn_photo': 'Take Photo (Required)',
        'btn_retake': 'Retake',
        'err_photo_req': '*Photo required',
        'btn_submit': 'Submit Report',
        'msg_no_photo': 'Please take a photo of the issue',
        'msg_success': 'Report submitted successfully! ✅',
        'err_login': 'Please login first',
        // Categories
        'cat_water': 'Plumbing (Leak/No Water)',
        'cat_electric': 'Electrical (Light/Power)',
        'cat_ac': 'Air Conditioner',
        'cat_furniture': 'Furniture/Equipment',
        'cat_internet': 'Internet/Wifi',
        'cat_other': 'Other',
      },
    };
  }

  // Translation helper function
  String tr(String key) => _translations[widget.languageCode]?[key] ?? key;

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      String? systemName =
          user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'];
      if (systemName != null && systemName.isNotEmpty) {
        _nameCtrl.text = systemName;
      } else {
        _nameCtrl.text = user?.email ?? '';
      }

      _phoneCtrl.text = prefs.getString('saved_phone') ?? '';
      
      // Load saved dorm as selected value
      String? savedDorm = prefs.getString('saved_dorm');
      if (savedDorm != null && savedDorm.isNotEmpty && _dormBuildings.contains(savedDorm)) {
        _selectedDorm = savedDorm;
      }
      
      _roomCtrl.text = prefs.getString('saved_room') ?? '';
    });
  }

  Future<void> _saveDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_phone', _phoneCtrl.text);
    await prefs.setString('saved_dorm', _selectedDorm ?? '');
    await prefs.setString('saved_room', _roomCtrl.text);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 800);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _showCustomNotification(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF43A047)
            : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      _showCustomNotification(tr('msg_no_photo'), isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw tr('err_login');

      await _saveDataLocally();

      final bytes = await _imageFile!.readAsBytes();
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('tickets').uploadBinary(fileName, bytes);
      final imageUrl = supabase.storage.from('tickets').getPublicUrl(fileName);

      // Map category key to a readable string for the DB if needed,
      // or just store the translated string. Here storing the translated string.
      String categoryToSave = tr(_selectedCategory!);

      await supabase.from('tickets').insert({
        'user_id': user.id,
        'category': categoryToSave,
        'description': _descCtrl.text.trim(),
        'status': 'pending',
        'image_url': imageUrl,
        'contact_name': _nameCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'dorm_building': _selectedDorm ?? '',
        'room_number': _roomCtrl.text.trim(),
      });

      // ✅ บันทึกลง room_logs เมื่อแจ้งซ่อม
      final fullRoomNumber = "${_selectedDorm ?? ''}${_roomCtrl.text.trim()}";
      await supabase.from('room_logs').insert({
        'room_number': fullRoomNumber,
        'title': categoryToSave,
        'status': 'รอตรวจสอบ',
        'performed_by': _nameCtrl.text.trim(),
        'log_date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _showCustomNotification(tr('msg_success'), isSuccess: true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      _showCustomNotification('Error: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          tr('title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFFA51C30),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Reporter Info Card ---
              _buildModernCard(
                children: [
                  _buildCardHeader(
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFFA51C30),
                    title: tr('section_user'),
                    subtitle: 'ข้อมูล',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    readOnly: true,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: _inputDecor(tr('label_name'), Icons.person).copyWith(
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecor(tr('label_phone'), Icons.phone_rounded)
                        .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    style: const TextStyle(fontSize: 12),
                    validator: (v) => v!.isEmpty ? tr('err_phone') : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDorm,
                          decoration: _inputDecor(tr('label_dorm'), Icons.apartment_rounded)
                              .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                          hint: const Text('เลือก', style: TextStyle(fontSize: 12)),
                          isExpanded: true,
                          items: _dormBuildings.map((String dorm) {
                            return DropdownMenuItem<String>(
                              value: dorm,
                              child: Text(dorm, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() => _selectedDorm = newValue);
                          },
                          validator: (value) => value == null ? tr('err_dorm') : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _roomCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecor(tr('label_room'), Icons.meeting_room_rounded)
                              .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                          style: const TextStyle(fontSize: 12),
                          validator: (v) => v!.isEmpty ? tr('err_room') : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Issue Details Card ---
              _buildModernCard(
                children: [
                  _buildCardHeader(
                    icon: Icons.build_rounded,
                    iconColor: const Color(0xFF4285F4),
                    title: tr('section_issue'),
                    subtitle: 'ปัญหา',
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _inputDecor(tr('label_category'), Icons.category_rounded)
                        .copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                    hint: Text(tr('hint_category'), style: const TextStyle(fontSize: 12)),
                    items: _categories.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(tr(key), style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() => _selectedCategory = newValue);
                    },
                    validator: (value) => value == null ? tr('err_category') : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    minLines: 2,
                    decoration: _inputDecor(tr('hint_issue'), Icons.description_rounded)
                        .copyWith(
                          hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                    style: const TextStyle(fontSize: 12),
                    validator: (v) => v!.isEmpty ? tr('err_issue') : null,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // --- Photo Section Card ---
              _buildModernCard(
                children: [
                  _buildCardHeader(
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFFA51C30),
                    title: 'ภาพประกอบ',
                    subtitle: 'จำเป็น',
                    isRequired: true,
                  ),
                  const SizedBox(height: 12),
                  if (_imageFile != null)
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  _imageFile!,
                                  height: 240,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: InkWell(
                                  onTap: () => setState(() => _imageFile = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red[600],
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6),
                                      ],
                                    ),
                                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: Text(
                        _imageFile == null ? tr('btn_photo') : tr('btn_retake'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _imageFile == null ? Colors.red[600] : Colors.amber[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA51C30),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.grey[700]),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              tr('btn_submit'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isRequired = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [iconColor, Color.lerp(iconColor, Colors.black, 0.15)!],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    bool isRequired = false,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          top: BorderSide(color: borderColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [iconColor, Color.lerp(iconColor, Colors.black, 0.2)!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (isRequired) const SizedBox(width: 3),
                        if (isRequired)
                          const Text(
                            '*',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 16, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFA51C30), width: 1.5),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
