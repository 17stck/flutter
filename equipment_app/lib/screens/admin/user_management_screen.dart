// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _authService = AuthService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await _authService.getAllUsers();
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddUserDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    UserRole selectedRole = UserRole.user;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('เพิ่มผู้ใช้งาน',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ-นามสกุล',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v!.isEmpty ? 'กรุณากรอก' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'อีเมล',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (v) => v!.isEmpty || !v.contains('@')
                        ? 'อีเมลไม่ถูกต้อง'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'รหัสผ่าน',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (v) =>
                        v!.length < 6 ? 'ต้องมีอย่างน้อย 6 ตัว' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(
                      labelText: 'แผนก',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'บทบาท',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: UserRole.user,
                          child: Text('User (ผู้ใช้งาน)')),
                      DropdownMenuItem(
                          value: UserRole.admin,
                          child: Text('Admin (ผู้ดูแล)')),
                    ],
                    onChanged: (v) => setD(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setD(() => isSubmitting = true);
                      try {
                        await _authService.register(
                          email: emailCtrl.text,
                          password: passCtrl.text,
                          fullName: nameCtrl.text,
                          department: deptCtrl.text,
                          role: selectedRole,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ เพิ่มผู้ใช้เรียบร้อย'),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                          _loadUsers(); // รีโหลดรายชื่อ
                        }
                      } catch (e) {
                        setD(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('เพิ่มผู้ใช้'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final deptCtrl = TextEditingController(text: user.department);
    UserRole selectedRole = user.role;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('แก้ไขผู้ใช้งาน',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v!.isEmpty ? 'กรุณากรอก' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(
                    labelText: 'แผนก',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'บทบาท',
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: UserRole.user, child: Text('User (ผู้ใช้งาน)')),
                    DropdownMenuItem(
                        value: UserRole.admin, child: Text('Admin (ผู้ดูแล)')),
                  ],
                  onChanged: (v) => setD(() => selectedRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await _authService.updateUser(user.uid, {
                  'fullName': nameCtrl.text.trim(),
                  'department': deptCtrl.text.trim(),
                  'role': selectedRole == UserRole.admin ? 'admin' : 'user',
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ แก้ไขข้อมูลเรียบร้อย'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                  _loadUsers();
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบผู้ใช้งาน',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('ต้องการลบ "${user.fullName}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              await _authService.deleteUser(user.uid);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ ลบผู้ใช้เรียบร้อย'),
                  backgroundColor: AppColors.danger,
                ),
              );
              _loadUsers();
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการผู้ใช้งาน')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('เพิ่มผู้ใช้', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Text('ยังไม่มีผู้ใช้งาน',
                      style: TextStyle(color: AppColors.textSecondary)),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      return _UserCard(
                        user: u,
                        onEdit: () => _showEditUserDialog(u),
                        onDelete: () => _confirmDelete(u),
                      );
                    },
                  ),
                ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.isAdmin;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAdmin
                ? AppColors.accent.withOpacity(0.2)
                : AppColors.primary.withOpacity(0.1),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: isAdmin ? const Color(0xFF795548) : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.accent.withOpacity(0.2)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAdmin ? '👑 Admin' : '👤 User',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isAdmin
                              ? const Color(0xFF795548)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                if (user.department.isNotEmpty)
                  Text(
                    user.department,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
