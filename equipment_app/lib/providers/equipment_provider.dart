// lib/providers/equipment_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../services/equipment_service.dart';

class EquipmentProvider extends ChangeNotifier {
  final EquipmentService _service = EquipmentService();

  List<EquipmentModel> _equipments = [];
  List<EquipmentModel> _searchResults = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;
  bool _isSearching = false;
  String _errorMessage = '';
  String _searchQuery = '';

  List<EquipmentModel> get equipments => _equipments;
  List<EquipmentModel> get searchResults => _searchResults;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

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

  // Stream listener — คำนวณ stats อัตโนมัติทุกครั้งที่ข้อมูลเปลี่ยน
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

  // ─── CRUD ──────────────────────────────────────────────────────────────
  Future<bool> addEquipment(EquipmentModel equipment, {File? imageFile}) async {
    _isLoading = true;
    notifyListeners();
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _service.uploadImage(imageFile, equipment.assetCode);
      }
      final eq =
          imageUrl != null ? equipment.copyWith(imageUrl: imageUrl) : equipment;
      await _service.addEquipment(eq);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEquipment(
    String id,
    Map<String, dynamic> data, {
    File? newImageFile,
    String? oldImageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (newImageFile != null) {
        if (oldImageUrl != null) await _service.deleteImage(oldImageUrl);
        final code = data['assetCode'] ?? 'EQ';
        data['imageUrl'] = await _service.uploadImage(newImageFile, code);
      }
      await _service.updateEquipment(id, data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
    try {
      await _service.updateStatus(
        equipment: equipment,
        newStatus: newStatus,
        checkedBy: checkedBy,
        checkedByName: checkedByName,
        note: note,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEquipment(String id) async {
    try {
      await _service.deleteEquipment(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
    }
    _isSearching = false;
    notifyListeners();
  }

  Future<EquipmentModel?> findByCode(String code) async {
    return await _service.getEquipmentByCode(code);
  }

  // ─── STATS ─────────────────────────────────────────────────────────────
  Future<void> loadStats() async {
    _computeStats(); // คำนวณจาก list แทนเรียก Firestore
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
