// lib/services/equipment_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment_model.dart';
import '../models/check_history_model.dart';

class EquipmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // ─── Collection References ──────────────────────────────────────────────
  CollectionReference get _equipments => _db.collection('equipments');
  CollectionReference get _history => _db.collection('check_history');

  // ─── CREATE ─────────────────────────────────────────────────────────────
  Future<String> addEquipment(EquipmentModel equipment) async {
    final docRef = await _equipments.add(equipment.toMap());
    return docRef.id;
  }

  // ─── READ ALL ────────────────────────────────────────────────────────────
  Stream<List<EquipmentModel>> getEquipmentsStream() {
    return _equipments
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => EquipmentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ─── READ ONE ────────────────────────────────────────────────────────────
  Future<EquipmentModel?> getEquipmentById(String id) async {
    final doc = await _equipments.doc(id).get();
    if (doc.exists) {
      return EquipmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // ─── SEARCH BY CODE ──────────────────────────────────────────────────────
  Future<EquipmentModel?> getEquipmentByCode(String code) async {
    final snap = await _equipments
        .where('assetCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return EquipmentModel.fromMap(
        snap.docs.first.data() as Map<String, dynamic>,
        snap.docs.first.id,
      );
    }
    return null;
  }

  // ─── SEARCH (Full-text simulation) ───────────────────────────────────────
  Future<List<EquipmentModel>> searchEquipments(String query) async {
    final q = query.trim().toUpperCase();
    final snap = await _equipments.get();
    return snap.docs
        .map(
          (doc) => EquipmentModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .where(
          (e) =>
              e.assetCode.toUpperCase().contains(q) ||
              e.name.toUpperCase().contains(q) ||
              e.brand.toUpperCase().contains(q) ||
              e.category.toUpperCase().contains(q) ||
              e.location.toUpperCase().contains(q),
        )
        .toList();
  }

  // ─── FILTER BY STATUS ────────────────────────────────────────────────────
  Stream<List<EquipmentModel>> getByStatus(EquipmentStatus status) {
    return _equipments
        .where('status', isEqualTo: status.value)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => EquipmentModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // ─── UPDATE ──────────────────────────────────────────────────────────────
  Future<void> updateEquipment(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now().toIso8601String();
    await _equipments.doc(id).update(data);
  }

  // ─── UPDATE STATUS + Log ─────────────────────────────────────────────────
  Future<void> updateStatus({
    required EquipmentModel equipment,
    required EquipmentStatus newStatus,
    required String checkedBy,
    required String checkedByName,
    String note = '',
  }) async {
    // อัปเดตสถานะ
    await _equipments.doc(equipment.id).update({
      'status': newStatus.value,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // บันทึกประวัติ
    final history = CheckHistoryModel(
      id: _uuid.v4(),
      equipmentId: equipment.id,
      equipmentCode: equipment.assetCode,
      equipmentName: equipment.name,
      checkedBy: checkedBy,
      checkedByName: checkedByName,
      statusBefore: equipment.status.value,
      statusAfter: newStatus.value,
      note: note,
      checkedAt: DateTime.now(),
    );
    await _history.add(history.toMap());
  }

  // ─── DELETE ──────────────────────────────────────────────────────────────
  Future<void> deleteEquipment(String id) async {
    // ลบรูปภาพถ้ามี
    final eq = await getEquipmentById(id);
    if (eq?.imageUrl != null) {
      try {
        await _storage.refFromURL(eq!.imageUrl!).delete();
      } catch (_) {}
    }
    await _equipments.doc(id).delete();
  }

  // ─── UPLOAD IMAGE ────────────────────────────────────────────────────────
  Future<String> uploadImage(File file, String assetCode) async {
    final fileName =
        '${assetCode}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('equipment_images/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ─── DELETE IMAGE ────────────────────────────────────────────────────────
  Future<void> deleteImage(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  // ─── CHECK HISTORY ───────────────────────────────────────────────────────
  Stream<List<CheckHistoryModel>> getCheckHistory({String? equipmentId}) {
    Query query = _history.orderBy('checkedAt', descending: true);
    if (equipmentId != null) {
      query = query.where('equipmentId', isEqualTo: equipmentId);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (doc) => CheckHistoryModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(),
    );
  }

  // ─── DASHBOARD STATS ─────────────────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats() async {
    final snap = await _equipments.get();
    final items = snap.docs
        .map(
          (doc) => EquipmentModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();

    final stats = <String, int>{
      'total': items.length,
      'normal': 0,
      'damaged': 0,
      'repairing': 0,
      'disposed': 0,
      'lost': 0,
    };
    for (final e in items) {
      stats[e.status.value] = (stats[e.status.value] ?? 0) + 1;
    }
    return stats;
  }

  // ─── IMPORT FROM CSV ─────────────────────────────────────────────────────
  Future<int> importFromCsv(List<Map<String, dynamic>> rows, String uid) async {
    int count = 0;
    final batch = _db.batch();
    for (final row in rows) {
      final docRef = _equipments.doc();
      final now = DateTime.now().toIso8601String();
      batch.set(docRef, {
        'assetCode': (row['assetCode'] ?? '').toString().trim().toUpperCase(),
        'name': (row['name'] ?? '').toString().trim(),
        'brand': (row['brand'] ?? '').toString().trim(),
        'model': (row['model'] ?? '').toString().trim(),
        'category': (row['category'] ?? '').toString().trim(),
        'description': (row['description'] ?? '').toString().trim(),
        'location': (row['location'] ?? '').toString().trim(),
        'status': 'normal',
        'imageUrl': null,
        'serialNumber': (row['serialNumber'] ?? '').toString().trim(),
        'purchasePrice': double.tryParse(
          row['purchasePrice']?.toString() ?? '',
        ),
        'purchaseDate': row['purchaseDate'],
        'createdBy': uid,
        'createdAt': now,
        'updatedAt': now,
      });
      count++;
    }
    await batch.commit();
    return count;
  }
}
