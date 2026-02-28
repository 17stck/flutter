// lib/screens/equipment/add_equipment_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/equipment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../utils/app_theme.dart';

class AddEquipmentScreen extends StatefulWidget {
  final EquipmentModel? equipment;
  const AddEquipmentScreen({super.key, this.equipment});

  @override
  State<AddEquipmentScreen> createState() => _AddEquipmentScreenState();
}

class _AddEquipmentScreenState extends State<AddEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  File? _imageFile;
  String? _selectedCategory;
  EquipmentStatus _selectedStatus = EquipmentStatus.normal;

  bool get _isEdit => widget.equipment != null;

  final _categories = [
    'คอมพิวเตอร์',
    'เครื่องพิมพ์',
    'อุปกรณ์เครือข่าย',
    'เฟอร์นิเจอร์',
    'เครื่องมือวัด',
    'ยานพาหนะ',
    'อุปกรณ์ไฟฟ้า',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.equipment!;
      _codeCtrl.text = e.assetCode;
      _nameCtrl.text = e.name;
      _brandCtrl.text = e.brand;
      _modelCtrl.text = e.model;
      _selectedCategory = _categories.contains(e.category) ? e.category : null;
      _descCtrl.text = e.description;
      _locationCtrl.text = e.location;
      _serialCtrl.text = e.serialNumber ?? '';
      _priceCtrl.text = e.purchasePrice?.toString() ?? '';
      _selectedStatus = e.status;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _serialCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลือกรูปภาพ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('ถ่ายรูป'),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('คลังรูป'),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final eqProv = context.read<EquipmentProvider>();
    final uid = context.read<AuthProvider>().currentUser!.uid;
    final now = DateTime.now();

    if (_isEdit) {
      final data = {
        'assetCode': _codeCtrl.text.trim().toUpperCase(),
        'name': _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'category': _selectedCategory ?? '',
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'serialNumber': _serialCtrl.text.trim(),
        'purchasePrice': double.tryParse(_priceCtrl.text),
        'status': _selectedStatus.value,
      };
      final ok = await eqProv.updateEquipment(
        widget.equipment!.id,
        data,
        newImageFile: _imageFile,
        oldImageUrl: widget.equipment!.imageUrl,
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ อัปเดตครุภัณฑ์เรียบร้อย'),
          backgroundColor: AppColors.secondary,
        ));
        Navigator.pop(context);
      }
    } else {
      final eq = EquipmentModel(
        id: const Uuid().v4(),
        assetCode: _codeCtrl.text.trim().toUpperCase(),
        name: _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        category: _selectedCategory ?? '',
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        status: _selectedStatus,
        serialNumber: _serialCtrl.text.trim(),
        purchasePrice: double.tryParse(_priceCtrl.text),
        createdBy: uid,
        createdAt: now,
        updatedAt: now,
      );
      final ok = await eqProv.addEquipment(eq, imageFile: _imageFile);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ เพิ่มครุภัณฑ์เรียบร้อย'),
          backgroundColor: AppColors.secondary,
        ));
        Navigator.pop(context);
      }
    }

    if (eqProv.errorMessage.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(eqProv.errorMessage),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EquipmentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขครุภัณฑ์' : 'เพิ่มครุภัณฑ์')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _showImagePicker,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3), width: 2),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_imageFile!, fit: BoxFit.cover))
                        : _isEdit && widget.equipment!.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                    widget.equipment!.imageUrl!,
                                    fit: BoxFit.cover))
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      color: AppColors.primary, size: 32),
                                  SizedBox(height: 6),
                                  Text('เพิ่มรูปภาพ',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── ข้อมูลพื้นฐาน ──────────────────────────────────────
              _sectionTitle('ข้อมูลพื้นฐาน'),
              _field('รหัสครุภัณฑ์ *', _codeCtrl,
                  hint: 'EQ-2024-001', icon: Icons.qr_code, required: true),
              _field('ชื่อครุภัณฑ์ *', _nameCtrl,
                  hint: 'คอมพิวเตอร์ HP', icon: Icons.devices, required: true),

              // Category Dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'ประเภทครุภัณฑ์ *',
                    prefixIcon: Icon(Icons.category, color: AppColors.primary),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'กรุณาเลือกประเภท' : null,
                ),
              ),

              _field('ยี่ห้อ', _brandCtrl,
                  hint: 'HP, Dell...', icon: Icons.branding_watermark),
              _field('รุ่น', _modelCtrl,
                  hint: 'ProBook 450', icon: Icons.model_training),

              // ── สถานะ ───────────────────────────────────────────────
              _sectionTitle('สถานะครุภัณฑ์'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: EquipmentStatus.values.map((s) {
                    final color = getStatusColor(s.value);
                    return RadioListTile<EquipmentStatus>(
                      dense: true,
                      value: s,
                      groupValue: _selectedStatus,
                      title: Row(children: [
                        Icon(getStatusIcon(s.value), color: color, size: 18),
                        const SizedBox(width: 8),
                        Text(s.label,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w600)),
                      ]),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── ตำแหน่ง ────────────────────────────────────────────
              _sectionTitle('ข้อมูลตำแหน่ง'),
              _field('ที่ตั้ง *', _locationCtrl,
                  hint: 'ห้อง 301 อาคาร A',
                  icon: Icons.location_on,
                  required: true),

              // ── เพิ่มเติม ───────────────────────────────────────────
              _sectionTitle('ข้อมูลเพิ่มเติม'),
              _field('หมายเลขซีเรียล', _serialCtrl,
                  hint: 'SN-XXXXX', icon: Icons.numbers),
              _field('ราคาที่ซื้อ (บาท)', _priceCtrl,
                  hint: '25000',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number),
              _field('รายละเอียด', _descCtrl,
                  hint: 'รายละเอียดเพิ่มเติม...',
                  icon: Icons.description,
                  maxLines: 3),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEdit ? Icons.save : Icons.add_circle),
                            const SizedBox(width: 8),
                            Text(
                              _isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มครุภัณฑ์',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              icon != null ? Icon(icon, color: AppColors.primary) : null,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอก $label' : null
            : null,
      ),
    );
  }
}
