// lib/screens/equipment/add_equipment_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/equipment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../utils/app_theme.dart';

enum AssetCodeInputMode { manual, scanQr }

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

  // รองรับทั้ง mobile (File) และ web (Uint8List)
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageFileName;

  String? _selectedCategory;
  EquipmentStatus _selectedStatus = EquipmentStatus.normal;
  AssetCodeInputMode _assetCodeInputMode = AssetCodeInputMode.manual;

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
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;

    if (kIsWeb) {
      // Web: อ่านเป็น bytes
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageFile = null;
        _imageFileName = picked.name;
      });
    } else {
      // Mobile: ใช้ File
      setState(() {
        _imageFile = File(picked.path);
        _imageBytes = null;
        _imageFileName = picked.name;
      });
    }
  }

  Future<void> _scanAssetCode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _AssetCodeScannerScreen()),
    );
    if (!mounted || scannedCode == null || scannedCode.trim().isEmpty) return;
    setState(() {
      _codeCtrl.text = scannedCode.trim().toUpperCase();
    });
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'เลือกรูปภาพ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'ถ่ายรูป',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageSourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'คลังรูป',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            if (_hasImage) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _imageFile = null;
                    _imageBytes = null;
                    _imageFileName = null;
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                label: const Text(
                  'ลบรูปภาพ',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasImage =>
      _imageFile != null ||
      _imageBytes != null ||
      (_isEdit && widget.equipment!.imageUrl != null);

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
    if (_isEdit && widget.equipment!.imageUrl != null) {
      return Image.network(
        widget.equipment!.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 36),
          SizedBox(height: 8),
          Text(
            'แตะเพื่อเพิ่มรูปภาพ',
            style: TextStyle(color: AppColors.primary, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            'รองรับ JPG, PNG',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      );

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
        newImageBytes: _imageBytes,
        oldImageUrl: widget.equipment!.imageUrl,
      );
      if (ok && mounted) {
        final msg = eqProv.imageUploadSkipped
            ? '⚠️ บันทึกแล้ว แต่ยังไม่ได้ตั้งค่า Cloudinary (รูปไม่ถูกอัปโหลด)'
            : '✅ บันทึกเรียบร้อย';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor:
              eqProv.imageUploadSkipped ? Colors.orange : AppColors.secondary,
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
      final ok = await eqProv.addEquipment(
        eq,
        imageFile: _imageFile,
        imageBytes: _imageBytes,
      );
      if (ok && mounted) {
        final msg = eqProv.imageUploadSkipped
            ? '⚠️ บันทึกแล้ว แต่ยังไม่ได้ตั้งค่า Cloudinary (รูปไม่ถูกอัปโหลด)'
            : '✅ เพิ่มครุภัณฑ์เรียบร้อย';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor:
              eqProv.imageUploadSkipped ? Colors.orange : AppColors.secondary,
        ));
        Navigator.pop(context);
      }
    }

    if (eqProv.errorMessage.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(eqProv.errorMessage),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 5),
      ));
      eqProv.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EquipmentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'แก้ไขครุภัณฑ์' : 'เพิ่มครุภัณฑ์'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── รูปภาพ ─────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _showImagePicker,
                  child: Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _buildImagePreview(),
                        ),
                      ),
                      // กล้องไอคอนมุมขวาล่าง
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_imageFileName != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _imageFileName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── ข้อมูลพื้นฐาน ──────────────────────────────────────
              _sectionTitle('📋 ข้อมูลพื้นฐาน'),
              _assetCodeInputCard(),
              _field(
                'ชื่อครุภัณฑ์ *',
                _nameCtrl,
                hint: 'คอมพิวเตอร์ HP',
                icon: Icons.devices,
                required: true,
              ),

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
              _sectionTitle('🔵 สถานะครุภัณฑ์'),
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
                        Text(
                          s.label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // ── ตำแหน่ง ────────────────────────────────────────────
              _sectionTitle('📍 ที่ตั้ง'),
              _field(
                'ที่ตั้ง *',
                _locationCtrl,
                hint: 'ห้อง 301 อาคาร A',
                icon: Icons.location_on,
                required: true,
              ),

              // ── เพิ่มเติม ───────────────────────────────────────────
              _sectionTitle('📎 ข้อมูลเพิ่มเติม'),
              _field('หมายเลขซีเรียล', _serialCtrl,
                  hint: 'SN-XXXXX', icon: Icons.numbers),
              _field(
                'ราคาที่ซื้อ (บาท)',
                _priceCtrl,
                hint: '25000',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              _field(
                'รายละเอียด',
                _descCtrl,
                hint: 'รายละเอียดเพิ่มเติม...',
                icon: Icons.description,
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEdit ? Icons.save_rounded : Icons.add_circle_rounded),
                            const SizedBox(width: 8),
                            Text(
                              _isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มครุภัณฑ์',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );

  Widget _assetCodeInputCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รหัสครุภัณฑ์ *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('ใส่เอง'),
                    selected:
                        _assetCodeInputMode == AssetCodeInputMode.manual,
                    selectedColor: const Color(0xFFE3F2FD),
                    avatar: const Icon(Icons.edit, size: 18),
                    onSelected: (_) => setState(
                      () => _assetCodeInputMode = AssetCodeInputMode.manual,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('สแกน QR'),
                    selected:
                        _assetCodeInputMode == AssetCodeInputMode.scanQr,
                    selectedColor: const Color(0xFFE3F2FD),
                    avatar: const Icon(Icons.qr_code_scanner, size: 18),
                    onSelected: (_) => setState(
                      () => _assetCodeInputMode = AssetCodeInputMode.scanQr,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _codeCtrl,
              readOnly: _assetCodeInputMode == AssetCodeInputMode.scanQr,
              textCapitalization: TextCapitalization.characters,
              onTap: _assetCodeInputMode == AssetCodeInputMode.scanQr
                  ? _scanAssetCode
                  : null,
              decoration: InputDecoration(
                labelText: 'รหัสครุภัณฑ์ *',
                hintText: 'EQ-2024-001',
                prefixIcon:
                    const Icon(Icons.qr_code, color: AppColors.primary),
                suffixIcon:
                    _assetCodeInputMode == AssetCodeInputMode.scanQr
                        ? IconButton(
                            tooltip: 'สแกน QR',
                            onPressed: _scanAssetCode,
                            icon: const Icon(Icons.qr_code_scanner),
                          )
                        : null,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'กรุณากรอกรหัสครุภัณฑ์'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

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
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'กรุณากรอก $label' : null
            : null,
      ),
    );
  }
}

// ─── Image Source Button ─────────────────────────────────────────────────────
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Asset Code Scanner Screen ───────────────────────────────────────────────
class _AssetCodeScannerScreen extends StatefulWidget {
  const _AssetCodeScannerScreen();

  @override
  State<_AssetCodeScannerScreen> createState() =>
      _AssetCodeScannerScreenState();
}

class _AssetCodeScannerScreenState extends State<_AssetCodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isCaptured = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isCaptured) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _isCaptured = true;
      _controller.stop();
      Navigator.pop(context, value.toUpperCase());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('สแกนรหัสครุภัณฑ์'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _controller.toggleTorch();
            },
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
          ),
          IconButton(
            onPressed: _controller.switchCamera,
            icon: const Icon(Icons.flip_camera_ios),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'สแกน QR แล้วระบบจะใส่รหัสให้อัตโนมัติ',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}