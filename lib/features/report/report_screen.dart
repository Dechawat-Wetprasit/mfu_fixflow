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
  final _dormCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  // 🔥 Selected Category Variable
  String? _selectedCategory;

  // 🔥 Category List (Keys for translation)
  final List<String> _categories = [
    'cat_water',
    'cat_electric',
    'cat_ac',
    'cat_furniture',
    'cat_internet',
    'cat_other',
  ];

  // 🔥 Dictionary for translations
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
      _dormCtrl.text = prefs.getString('saved_dorm') ?? '';
      _roomCtrl.text = prefs.getString('saved_room') ?? '';
    });
  }

  Future<void> _saveDataLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_phone', _phoneCtrl.text);
    await prefs.setString('saved_dorm', _dormCtrl.text);
    await prefs.setString('saved_room', _roomCtrl.text);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 800);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('msg_no_photo')),
          backgroundColor: Colors.red,
        ),
      );
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
        'category': categoryToSave, // 🔥 Save selected category
        'description': _descCtrl.text.trim(),
        'status': 'pending',
        'image_url': imageUrl,
        'contact_name': _nameCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'dorm_building': _dormCtrl.text.trim(),
        'room_number': _roomCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('msg_success')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('title')),
        backgroundColor: const Color(0xFFA51C30),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('section_user'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA51C30),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nameCtrl,
                readOnly: true,
                style: TextStyle(color: Colors.grey[700]),
                decoration: _inputDecor(
                  tr('label_name'),
                  Icons.person,
                ).copyWith(filled: true, fillColor: Colors.grey[200]),
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDecor(tr('label_phone'), Icons.phone),
                validator: (v) => v!.isEmpty ? tr('err_phone') : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dormCtrl,
                      decoration: _inputDecor(
                        tr('label_dorm'),
                        Icons.apartment,
                      ),
                      validator: (v) => v!.isEmpty ? tr('err_dorm') : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _roomCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecor(
                        tr('label_room'),
                        Icons.meeting_room,
                      ),
                      validator: (v) => v!.isEmpty ? tr('err_room') : null,
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),

              Row(
                children: [
                  Text(
                    tr('section_issue'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    " *",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🔥 Dropdown Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecor(tr('label_category'), Icons.category),
                hint: Text(tr('hint_category')),
                items: _categories.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(tr(key)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? tr('err_category') : null,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDecor(tr('hint_issue'), Icons.build),
                validator: (v) => v!.isEmpty ? tr('err_issue') : null,
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  border: _imageFile == null
                      ? Border.all(color: Colors.red.withOpacity(0.5), width: 1)
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _imageFile == null ? tr('btn_photo') : tr('btn_retake'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _imageFile == null
                            ? Colors.red[50]
                            : Colors.grey[200],
                        foregroundColor: _imageFile == null
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_imageFile != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFile!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _imageFile = null),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        tr('err_photo_req'),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA51C30),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          tr('btn_submit'),
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
