// lib/models/check_history_model.dart

class CheckHistoryModel {
  final String id;
  final String equipmentId;
  final String equipmentCode;
  final String equipmentName;
  final String checkedBy;
  final String checkedByName;
  final String statusBefore;
  final String statusAfter;
  final String note;
  final DateTime checkedAt;

  CheckHistoryModel({
    required this.id,
    required this.equipmentId,
    required this.equipmentCode,
    required this.equipmentName,
    required this.checkedBy,
    required this.checkedByName,
    required this.statusBefore,
    required this.statusAfter,
    required this.note,
    required this.checkedAt,
  });

  factory CheckHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CheckHistoryModel(
      id: id,
      equipmentId: map['equipmentId'] ?? '',
      equipmentCode: map['equipmentCode'] ?? '',
      equipmentName: map['equipmentName'] ?? '',
      checkedBy: map['checkedBy'] ?? '',
      checkedByName: map['checkedByName'] ?? '',
      statusBefore: map['statusBefore'] ?? '',
      statusAfter: map['statusAfter'] ?? '',
      note: map['note'] ?? '',
      checkedAt: DateTime.parse(
        map['checkedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'equipmentCode': equipmentCode,
      'equipmentName': equipmentName,
      'checkedBy': checkedBy,
      'checkedByName': checkedByName,
      'statusBefore': statusBefore,
      'statusAfter': statusAfter,
      'note': note,
      'checkedAt': checkedAt.toIso8601String(),
    };
  }
}
