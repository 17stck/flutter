// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success =
        await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!success && mounted) {
      final msg = auth.errorMessage.isNotEmpty
          ? auth.errorMessage
          : 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
            onVisible: () => auth.clearError(), // clearError หลัง snackbar โผล่
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        // ─── Logo gradient ───────────────────────────
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF0D47A1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A73E8).withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // วงกลม subtle ด้านหลัง
                              Positioned(
                                top: -10,
                                right: -10,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              // ไอคอนหลัก
                              const Icon(
                                Icons.inventory_2_rounded,
                                size: 46,
                                color: Colors.white,
                              ),
                              // จุดเล็กมุมขวาล่าง
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF69F0AE),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ระบบตรวจเช็คครุภัณฑ์',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Equipment Management System',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('เข้าสู่ระบบ',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              const Text('กรุณากรอกอีเมลและรหัสผ่านของท่าน',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 28),
                              const _FieldLabel(label: 'อีเมล'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'example@email.com',
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: AppColors.primary),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'กรุณากรอกอีเมล';
                                  if (!v.contains('@'))
                                    return 'รูปแบบอีเมลไม่ถูกต้อง';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(label: 'รหัสผ่าน'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscurePass,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: AppColors.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'กรุณากรอกรหัสผ่าน';
                                  if (v.length < 6)
                                    return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _login,
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login_rounded),
                                            SizedBox(width: 8),
                                            Text('เข้าสู่ระบบ',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('ยังไม่มีบัญชี? ',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14)),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    ),
                                    child: const Text('สมัครสมาชิก',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _DemoAccountInfo(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}

class _DemoAccountInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline, size: 14, color: AppColors.primary),
            SizedBox(width: 4),
            Text('บัญชีทดสอบ',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          _AccountRow(
              icon: Icons.admin_panel_settings,
              role: 'Admin',
              email: 'admin@equipment.com',
              pass: 'admin1234'),
          const SizedBox(height: 4),
          _AccountRow(
              icon: Icons.person,
              role: 'User',
              email: 'user@equipment.com',
              pass: 'user1234'),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String role, email, pass;
  const _AccountRow(
      {required this.icon,
      required this.role,
      required this.email,
      required this.pass});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 13, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Text('$role: $email / $pass',
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFamily: 'monospace')),
    ]);
  }
}
