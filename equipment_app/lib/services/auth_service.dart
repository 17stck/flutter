// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream สำหรับ auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ดึง current user
  User? get currentUser => _auth.currentUser;

  // ─── Login ──────────────────────────────────────────────────────────────
  Future<UserModel?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Register (Admin สร้างโดยไม่กระทบ session ปัจจุบัน) ───────────────
  Future<UserModel?> register({
    required String email,
    required String password,
    required String fullName,
    required String department,
    required UserRole role,
  }) async {
    // ใช้ Secondary FirebaseApp เพื่อสร้าง user
    // โดยไม่กระทบ session ของ admin ที่ login อยู่
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        final user = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          fullName: fullName,
          department: department,
          role: role,
          createdAt: DateTime.now(),
        );

        // ใช้ Firestore จาก secondary app เพื่อให้ auth token ตรงกัน
        final secondaryDb = FirebaseFirestore.instanceFor(app: secondaryApp!);
        await secondaryDb
            .collection('users')
            .doc(credential.user!.uid)
            .set(user.toMap());

        // Sign out จาก secondary app ทันที
        await secondaryAuth.signOut();

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } finally {
      // ลบ secondary app เสมอ ไม่ว่าจะสำเร็จหรือไม่
      await secondaryApp?.delete();
    }
  }

  // ─── Logout ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── Get User Data ───────────────────────────────────────────────────────
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Get All Users (Admin) ────────────────────────────────────────────────
  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─── Reset Password ──────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Update User ─────────────────────────────────────────────────────────
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ─── Delete User ─────────────────────────────────────────────────────────
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ─── Error Handler ───────────────────────────────────────────────────────
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      // อีเมลหรือรหัสผ่านไม่ถูกต้อง (Firebase v5+ ใช้ invalid-credential แทน)
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-login-credentials':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      case 'too-many-requests':
        return 'พยายามเข้าสู่ระบบหลายครั้งเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'network-request-failed':
        return 'ไม่สามารถเชื่อมต่อเครือข่ายได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ';
      case 'operation-not-allowed':
        return 'ไม่อนุญาตให้เข้าสู่ระบบด้วยวิธีนี้';
      default:
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }
  }
}
