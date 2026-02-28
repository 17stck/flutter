// lib/screens/admin/import_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../utils/app_theme.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  List<Map<String, dynamic>> _previewRows = [];
  String? _fileName;
  bool _isParsing = false;
  String _errorMsg = '';

  Future<void> _pickCsv() async {
    setState(() {
      _isParsing = true;
      _errorMsg = '';
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null) {
        setState(() => _isParsing = false);
        return;
      }

      final file = File(result.files.single.path!);
      _fileName = result.files.single.name;
      final content = await file.readAsString();
      _previewRows = _parseCsv(content);
    } catch (e) {
      _errorMsg = 'เกิดข้อผิดพลาด: $e';
    }
    setState(() => _isParsing = false);
  }

  List<Map<String, dynamic>> _parseCsv(String content) {
    final lines = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];

    // Header row
    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final rows = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split(',').map((v) => v.trim()).toList();
      final row = <String, dynamic>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = j < values.length ? values[j] : '';
      }
      rows.add(row);
    }
    return rows;
  }

  Future<void> _import() async {
    if (_previewRows.isEmpty) return;
    final uid = context.read<AuthProvider>().currentUser!.uid;
    final count = await context.read<EquipmentProvider>().importCsv(
      _previewRows,
      uid,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ นำเข้าสำเร็จ $count รายการ'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<EquipmentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('นำเข้าข้อมูลครุภัณฑ์')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Info Card ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'รูปแบบไฟล์ CSV',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ไฟล์ CSV ต้องมี Header ดังนี้:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'assetCode,name,brand,model,category,description,location,serialNumber,purchasePrice',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ตัวอย่าง:\nEQ-2024-001,คอมพิวเตอร์ HP,HP,ProBook 450,คอมพิวเตอร์,,ห้อง 301,SN001,25000',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Upload Button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isParsing ? null : _pickCsv,
                icon: _isParsing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file, color: AppColors.primary),
                label: Text(
                  _fileName ?? 'เลือกไฟล์ CSV',
                  style: const TextStyle(color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_errorMsg.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_errorMsg, style: const TextStyle(color: AppColors.danger)),
            ],

            // ─── Preview ──────────────────────────────────────────────
            if (_previewRows.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'ตัวอย่างข้อมูล',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_previewRows.length} รายการ',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._previewRows
                  .take(5)
                  .map(
                    (row) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row['assetCode']} - ${row['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${row['category']} | ${row['brand']} | ${row['location']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (_previewRows.length > 5)
                Text(
                  '... และอีก ${_previewRows.length - 5} รายการ',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _import,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    isLoading
                        ? 'กำลังนำเข้า...'
                        : 'นำเข้า ${_previewRows.length} รายการ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
