// lib/providers/equipment_provider.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../services/equipment_service.dart';
import '../services/cloudinary_service.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentService _service = EquipmentService();
  final CloudinaryService _cloudinary = CloudinaryService();

  List<EquipmentModel> _equipments = [];
  List<EquipmentModel> _searchResults = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;
  bool _isSearching = false;
  String _errorMessage = '';
  String _searchQuery = '';
  bool _imageUploadSkipped = false;

  List<EquipmentModel> get equipments => _equipments;
  List<EquipmentModel> get searchResults => _searchResults;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get imageUploadSkipped => _imageUploadSkipped;

  String _formatError(Object e) => e.toString();

  // คำนวณ stats จาก _equipments list โดยตรง
  void _computeStats() {
    _stats = {
      'total': _equipments.length,
      'normal':
          _equipments.where((e) => e.status == EquipmentStatus.normal).length,
      'damaged':
          _equipments.where((e) => e.status == EquipmentStatus.damaged).length,
      'repairing': _equipments
          .where((e) => e.status == EquipmentStatus.repairing)
          .length,
      'disposed':
          _equipments.where((e) => e.status == EquipmentStatus.disposed).length,
      'lost': _equipments.where((e) => e.status == EquipmentStatus.lost).length,
    };
  }

  // Stream listener
  void listenToEquipments() {
    _service.getEquipmentsStream().listen(
      (list) {
        _equipments = list;
        _computeStats();
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  // ─── อัปโหลดรูปภาพผ่าน Cloudinary ──────────────────────────────────────
  Future<String?> _uploadImage({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      if (imageBytes != null) {
        return await _cloudinary.uploadBytes(imageBytes, folder: 'equipment');
      } else if (imageFile != null) {
        return await _cloudinary.uploadFile(imageFile, folder: 'equipment');
      }
    } catch (e) {
      // ถ้า Cloudinary ยังไม่ได้ตั้งค่า → skip รูป แต่ยังบันทึกข้อมูลได้
      if (e.toString().contains('YOUR_CLOUD_NAME') ||
          e.toString().contains('กรุณาตั้งค่า')) {
        _imageUploadSkipped = true;
        return null;
      }
      rethrow;
    }
    return null;
  }

  // ─── CRUD ──────────────────────────────────────────────────────────────
  Future<bool> addEquipment(
    EquipmentModel equipment, {
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    _errorMessage = '';
    _imageUploadSkipped = false;
    _isLoading = true;
    notifyListeners();
    try {
      String? imageUrl;
      if (imageFile != null || imageBytes != null) {
        imageUrl = await _uploadImage(imageFile: imageFile, imageBytes: imageBytes);
      }
      final eq = imageUrl != null
          ? equipment.copyWith(imageUrl: imageUrl)
          : equipment;
      await _service.addEquipment(eq);
      _errorMessage = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEquipment(
    String id,
    Map<String, dynamic> data, {
    File? newImageFile,
    Uint8List? newImageBytes,
    String? oldImageUrl,
  }) async {
    _errorMessage = '';
    _imageUploadSkipped = false;
    _isLoading = true;
    notifyListeners();
    try {
      if (newImageFile != null || newImageBytes != null) {
        final uploadedUrl = await _uploadImage(
          imageFile: newImageFile,
          imageBytes: newImageBytes,
        );
        if (uploadedUrl != null) {
          data['imageUrl'] = uploadedUrl;
          // ลบรูปเก่าจาก Cloudinary (best-effort)
          if (oldImageUrl != null) {
            await _cloudinary.deleteByUrl(oldImageUrl);
          }
        }
      }
      await _service.updateEquipment(id, data);
      _errorMessage = '';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus({
    required EquipmentModel equipment,
    required EquipmentStatus newStatus,
    required String checkedBy,
    required String checkedByName,
    String note = '',
  }) async {
    _errorMessage = '';
    try {
      await _service.updateStatus(
        equipment: equipment,
        newStatus: newStatus,
        checkedBy: checkedBy,
        checkedByName: checkedByName,
        note: note,
      );
      _errorMessage = '';
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEquipment(String id) async {
    _errorMessage = '';
    try {
      // หา imageUrl ก่อนลบ เพื่อลบรูปจาก Cloudinary ด้วย
      final eq = _equipments.where((e) => e.id == id).firstOrNull;
      await _service.deleteEquipment(id);
      if (eq?.imageUrl != null) {
        await _cloudinary.deleteByUrl(eq!.imageUrl!);
      }
      _errorMessage = '';
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      notifyListeners();
      return false;
    }
  }

  // ─── SEARCH ────────────────────────────────────────────────────────────
  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _service.searchEquipments(query);
    } catch (e) {
      _errorMessage = _formatError(e);
    }
    _isSearching = false;
    notifyListeners();
  }

  Future<EquipmentModel?> findByCode(String code) async {
    return await _service.getEquipmentByCode(code);
  }

  void clearError() {
    _errorMessage = '';
    _imageUploadSkipped = false;
    notifyListeners();
  }

  // ─── STATS ─────────────────────────────────────────────────────────────
  Future<void> loadStats() async {
    _computeStats();
    notifyListeners();
  }

  // ─── IMPORT CSV ────────────────────────────────────────────────────────
  Future<int> importCsv(List<Map<String, dynamic>> rows, String uid) async {
    _isLoading = true;
    notifyListeners();
    final count = await _service.importFromCsv(rows, uid);
    _isLoading = false;
    notifyListeners();
    return count;
  }
}