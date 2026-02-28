// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String _errorMessage = '';

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  bool _isLoggingIn = false; // flag ป้องกัน _init รบกวน login flow

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      // ถ้ากำลัง login อยู่ให้ข้ามไป เพราะ login() จัดการเองแล้ว
      if (_isLoggingIn) return;

      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData != null) {
          _currentUser = userData;
          _status = AuthStatus.authenticated;
        } else {
          await _authService.logout();
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _currentUser = null;
        if (_status != AuthStatus.error) {
          _status = AuthStatus.unauthenticated;
        }
      }
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoggingIn = true;
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _isLoggingIn = false;
        notifyListeners();
        return true;
      } else {
        // Firebase Auth สำเร็จแต่ไม่มีข้อมูลใน Firestore
        await _authService.logout();
        _errorMessage = 'ไม่พบข้อมูลผู้ใช้ในระบบ กรุณาติดต่อผู้ดูแล';
        _status = AuthStatus.error;
        _isLoggingIn = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      _isLoggingIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String department,
    required UserRole role,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        department: department,
        role: role,
      );
      // register สำเร็จ — ไม่ต้อง set authenticated เพราะ
      // register_screen จะ pop กลับไปหน้า login เอง
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
