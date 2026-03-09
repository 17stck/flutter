
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  // ══════════════════════════════════════════════════════
  // ⚙️  ตั้งค่าตรงนี้ (2 ค่า)
  static const String _cloudName = 'dau6pgd6f';       // เช่น 'myapp123'
  static const String _uploadPreset = 'equipment_app'; // เช่น 'equipment_unsigned'
  // ══════════════════════════════════════════════════════

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// อัปโหลดรูปจาก File (Android/iOS)
  Future<String> uploadFile(File imageFile, {String? folder}) async {
    final bytes = await imageFile.readAsBytes();
    return _upload(bytes, folder: folder);
  }

  /// อัปโหลดรูปจาก Uint8List (Web / bytes)
  Future<String> uploadBytes(Uint8List bytes, {String? folder}) async {
    return _upload(bytes, folder: folder);
  }

  Future<String> _upload(Uint8List bytes, {String? folder}) async {
    if (_cloudName == 'YOUR_CLOUD_NAME') {
      throw Exception(
        'กรุณาตั้งค่า Cloudinary:\n'
        '1. สมัครฟรีที่ cloudinary.com\n'
        '2. แก้ _cloudName และ _uploadPreset ใน cloudinary_service.dart',
      );
    }

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['upload_preset'] = _uploadPreset;
    if (folder != null) request.fields['folder'] = folder;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'equipment_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // คืน secure_url (https) ของรูปที่อัปโหลด
      return json['secure_url'] as String;
    } else {
      final err = jsonDecode(response.body);
      throw Exception('Cloudinary error: ${err['error']?['message'] ?? response.body}');
    }
  }

  /// ลบรูปจาก Cloudinary
  /// หมายเหตุ: การลบด้วย unsigned preset ต้องใช้ Admin API key
  /// ถ้าไม่ต้องการลบรูปเก่า ข้ามได้เลย (รูปเก่าจะยังอยู่แต่ไม่มี reference)
  Future<void> deleteByUrl(String url) async {
    // Extract public_id from URL
    // URL format: https://res.cloudinary.com/{cloud}/image/upload/v{version}/{public_id}.{ext}
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx == -1) return;

      // Join segments after 'upload' (skip version like v1234567890)
      final afterUpload = segments.sublist(uploadIdx + 1);
      var publicId = afterUpload
          .where((s) => !s.startsWith('v') || !RegExp(r'^v\d+$').hasMatch(s))
          .join('/');
      // Remove extension
      publicId = publicId.replaceAll(RegExp(r'\.\w+$'), '');

      // Signed delete requires API secret — skip silently for unsigned preset
      // Implement Admin API call here if needed with API key + secret
      return;
    } catch (_) {
      // ไม่ต้อง throw — การลบไม่สำเร็จไม่ควรทำให้ app พัง
    }
  }
}