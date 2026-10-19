import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class W10AttractionScreen extends StatefulWidget {
  const W10AttractionScreen({Key? key}) : super(key: key);

  @override
  State<W10AttractionScreen> createState() => _W10AttractionScreenState();
}

class _W10AttractionScreenState extends State<W10AttractionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedProvince;
  bool _isRecommended = false;
  bool _isSaving = false;
  int? _editingId;
  List<Map<String, dynamic>> _attractionsList = [];

  final List<String> _provinces = [
    'กรุงเทพมหานคร',
    'เชียงใหม่',
    'กระบี่',
    'สมุทรสงคราม',
    'จันทบุรี',
  ];

  @override
  void initState() {
    super.initState();
    _refreshAttractions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _refreshAttractions() async {
    try {
      final data = await DatabaseHelper.instance.getAllAttractions();
      if (!mounted) return;
      setState(() => _attractionsList = data);
    } catch (e) {
      if (!mounted) return;
      _showMessage('โหลดข้อมูลไม่สำเร็จ: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.teal,
        ),
      );
  }

  Future<void> _saveToDatabase() async {
    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      _showMessage('กรุณากรอกข้อมูลให้ครบถ้วน', isError: true);
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final row = <String, dynamic>{
      'name': _nameController.text.trim(),
      'province': _selectedProvince!,
      'description': _descriptionController.text.trim(),
      'rating': 4.5,
      'is_recommended': _isRecommended ? 1 : 0,
    };

    try {
      if (_editingId == null) {
        await DatabaseHelper.instance.insertAttraction(row);
      } else {
        await DatabaseHelper.instance.updateAttraction(_editingId!, row);
      }

      await _refreshAttractions();
      if (!mounted) return;

      final wasEditing = _editingId != null;
      _clearForm();
      _showMessage(wasEditing ? 'แก้ไขข้อมูลสำเร็จ' : 'บันทึกข้อมูลลง SQLite สำเร็จ');
    } catch (e) {
      _showMessage('บันทึกข้อมูลไม่สำเร็จ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _startEditing(Map<String, dynamic> item) {
    final province = item['province']?.toString();
    setState(() {
      _editingId = item['id'] as int;
      _nameController.text = item['name']?.toString() ?? '';
      _descriptionController.text = item['description']?.toString() ?? '';
      _selectedProvince =
          _provinces.contains(province) ? province : null;
      _isRecommended = (item['is_recommended'] as num?)?.toInt() == 1;
    });
    _formKey.currentState?.reset();
    _showMessage('กำลังแก้ไข: ${item['name']}');
    // เลื่อนกลับไปยังแบบฟอร์มด้านบน
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 250),
      alignment: 0,
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedProvince = null;
      _isRecommended = false;
      _editingId = null;
    });
  }

  Future<void> _deleteAttraction(int id) async {
    try {
      await DatabaseHelper.instance.deleteAttraction(id);
      await _refreshAttractions();
      if (!mounted) return;
      if (_editingId == id) _clearForm();
      _showMessage('ลบข้อมูลสำเร็จ');
    } catch (e) {
      _showMessage('ลบข้อมูลไม่สำเร็จ: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกข้อมูลด้วย SQLite (W10)'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'กรอกข้อมูลสถานที่ท่องเที่ยว',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสถานที่ท่องเที่ยว',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'กรุณากรอกชื่อสถานที่'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: const InputDecoration(
                    labelText: 'จังหวัด',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  items: _provinces
                      .map((province) => DropdownMenuItem(
                            value: province,
                            child: Text(province),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedProvince = value),
                  validator: (value) =>
                      value == null ? 'กรุณาเลือกจังหวัด' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดสถานที่',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'กรุณากรอกรายละเอียด'
                          : null,
                ),
                CheckboxListTile(
                  title: const Text('แนะนำเป็นสถานที่ยอดนิยม'),
                  value: _isRecommended,
                  onChanged: (value) =>
                      setState(() => _isRecommended = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isSaving ? null : _saveToDatabase,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_editingId == null ? Icons.save : Icons.edit),
                    label: Text(
                      _isSaving
                          ? 'กำลังบันทึก...'
                          : _editingId == null
                              ? 'บันทึกข้อมูลลง SQLite'
                              : 'บันทึกการแก้ไข',
                    ),
                  ),
                ),
                if (_editingId != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _clearForm,
                      child: const Text('ยกเลิกการแก้ไข'),
                    ),
                  ),
                ],
                const Divider(height: 32, thickness: 2),
                const Text(
                  'รายการข้อมูลในฐานข้อมูล SQLite',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_attractionsList.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'ยังไม่มีข้อมูลใน SQLite',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _attractionsList.length,
                    itemBuilder: (context, index) {
                      final item = _attractionsList[index];
                      final id = (item['id'] as num).toInt();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Icon(
                              Icons.location_on,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(item['name']?.toString() ?? ''),
                          subtitle: Text(
                            '${item['province'] ?? ''} - '
                            '${item['description'] ?? ''}'
                            '${(item['is_recommended'] as num?)?.toInt() == 1 ? '\n⭐ สถานที่แนะนำ' : ''}',
                          ),
                          isThreeLine:
                              (item['is_recommended'] as num?)?.toInt() == 1,
                          trailing: Wrap(
                            spacing: 0,
                            children: [
                              IconButton(
                                tooltip: 'แก้ไข',
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _startEditing(item),
                              ),
                              IconButton(
                                tooltip: 'ลบ',
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteAttraction(id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
