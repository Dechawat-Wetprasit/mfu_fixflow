import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaterialsTrackingScreen extends StatefulWidget {
  final String ticketId;
  final String ticketRoom;

  const MaterialsTrackingScreen({
    required this.ticketId,
    required this.ticketRoom,
    super.key,
  });

  @override
  State<MaterialsTrackingScreen> createState() => _MaterialsTrackingScreenState();
}

class _MaterialsTrackingScreenState extends State<MaterialsTrackingScreen> {
  final supabase = Supabase.instance.client;
  String _currentLanguageCode = 'th';

  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'general';
  String _selectedUnit = 'piece';
  bool _isLoading = false;

  // Categories
  final List<String> _categories = [
    'general',
    'plumbing',
    'electrical',
    'furniture',
    'ac',
    'internet',
    'other',
  ];

  final List<String> _units = ['piece', 'meter', 'set', 'roll', 'bottle', 'box'];

  final Map<String, Map<String, String>> _translations = {
    'th': {
      'title': 'บันทึกเบิกอุปกรณ์',
      'room': 'ห้อง',
      'category': 'หมวดหมู่การซ่อม',
      'material': 'ชื่ออุปกรณ์',
      'quantity': 'จำนวน',
      'unit': 'หน่วย',
      'notes': 'หมายเหตุ',
      'add_material': 'เพิ่มอุปกรณ์',
      'materials_list': 'รายการอุปกรณ์ที่เบิก',
      'no_materials': 'ยังไม่มีการบันทึกอุปกรณ์',
      'delete': 'ลบ',
      'delete_confirm': 'ยืนยันการลบ?',
      'save_success': 'บันทึกเรียบร้อย',
      'error': 'เกิดข้อผิดพลาด',
      'cancel': 'ยกเลิก',
      'confirm': 'ยืนยัน',
      'cat_general': 'ทั่วไป',
      'cat_plumbing': 'ประปา',
      'cat_electrical': 'ไฟฟ้า',
      'cat_furniture': 'เฟอร์นิเจอร์',
      'cat_ac': 'แอร์',
      'cat_internet': 'อินเทอร์เน็ต',
      'cat_other': 'อื่นๆ',
    },
    'en': {
      'title': 'Materials Tracking',
      'room': 'Room',
      'category': 'Category',
      'material': 'Material Name',
      'quantity': 'Quantity',
      'unit': 'Unit',
      'notes': 'Notes',
      'add_material': 'Add Material',
      'materials_list': 'Materials List',
      'no_materials': 'No materials recorded',
      'delete': 'Delete',
      'delete_confirm': 'Confirm delete?',
      'save_success': 'Saved successfully',
      'error': 'Error occurred',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'cat_general': 'General',
      'cat_plumbing': 'Plumbing',
      'cat_electrical': 'Electrical',
      'cat_furniture': 'Furniture',
      'cat_ac': 'AC',
      'cat_internet': 'Internet',
      'cat_other': 'Other',
    },
  };

  String tr(String key) => _translations[_currentLanguageCode]?[key] ?? key;

  String _getCategoryLabel(String cat) {
    final key = 'cat_$cat';
    return tr(key);
  }

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguageCode = prefs.getString('language_code') ?? 'th';
    });
  }

  Future<void> _addMaterial() async {
    if (_materialController.text.isEmpty || _quantityController.text.isEmpty) {
      _showError(tr('error'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase.from('materials_tracking').insert({
        'ticket_id': widget.ticketId,
        'technician_id': user.id,
        'material_category': _selectedCategory,
        'material_name': _materialController.text,
        'quantity': int.parse(_quantityController.text),
        'unit': _selectedUnit,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'issued_at': DateTime.now().toIso8601String(),
      });

      _materialController.clear();
      _quantityController.clear();
      _notesController.clear();
      _selectedUnit = 'piece';

      _showSuccess(tr('save_success'));
      setState(() {});
    } catch (e) {
      _showError('${tr('error')}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMaterial(dynamic materialId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete')),
        content: Text(tr('delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await supabase.from('materials_tracking').delete().eq('id', materialId);
                _showSuccess(tr('save_success'));
                setState(() {});
              } catch (e) {
                _showError('${tr('error')}: $e');
              }
            },
            child: Text(tr('confirm'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(tr('title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF00796B),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF00796B), const Color(0xFF004D40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Column(
        children: [
          // Input Section
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room Info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF00796B).withOpacity(0.1), const Color(0xFF00796B).withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00796B).withOpacity(0.3), width: 1.5),
                      boxShadow: [BoxShadow(color: const Color(0xFF00796B).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home, color: Color(0xFF00796B), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          '${tr('room')}: ${widget.ticketRoom}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF00796B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Dropdown
                  Text(tr('category'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      onChanged: (val) => setState(() => _selectedCategory = val ?? 'general'),
                      items: _categories
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(_getCategoryLabel(cat))))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Material Name
                  Text(tr('material'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _materialController,
                    decoration: InputDecoration(
                      hintText: tr('material'),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Quantity & Unit
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('quantity'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                hintText: '0',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('unit'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                isExpanded: true,
                                underline: const SizedBox(),
                                onChanged: (val) => setState(() => _selectedUnit = val ?? 'piece'),
                                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Notes
                  Text(tr('notes'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: tr('notes'),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addMaterial,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(tr('add_material'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: const Color(0xFF00796B).withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Materials List
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, color: const Color(0xFF00796B), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        tr('materials_list'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('materials_tracking')
                        .stream(primaryKey: ['id'])
                        .eq('ticket_id', widget.ticketId)
                        .order('issued_at', ascending: false),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 50, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(tr('no_materials'), style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      }

                      final materials = snapshot.data!;
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: materials.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final mat = materials[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00796B).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.inventory_2, color: Color(0xFF00796B), size: 18),
                                ),
                                title: Text(
                                  '${mat['material_name']} (${mat['quantity']} ${mat['unit']})',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${_getCategoryLabel(mat['material_category'])} • ${DateFormat('dd/MM HH:mm').format(DateTime.parse(mat['issued_at']))}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                  onPressed: () => _deleteMaterial(mat['id']),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                ),
                              ),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _materialController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
