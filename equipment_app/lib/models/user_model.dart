// lib/models/user_model.dart

enum UserRole { admin, user }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String department;
  final UserRole role;
  final DateTime createdAt;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.department,
    required this.role,
    required this.createdAt,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      // รองรับทั้ง fullName และ fullname (ตัวพิมพ์เล็ก)
      fullName: map['fullName'] ?? map['fullname'] ?? '',
      department: map['department'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.user,
      createdAt: DateTime.tryParse(
            map['createdAt'] ?? '',
          ) ??
          DateTime.now(),
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName, // บันทึกเป็น fullName เสมอ
      'department': department,
      'role': role == UserRole.admin ? 'admin' : 'user',
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  bool get isAdmin => role == UserRole.admin;
}
