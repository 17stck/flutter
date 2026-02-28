// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../utils/app_theme.dart';
import '../equipment/equipment_list_screen.dart';
import '../equipment/add_equipment_screen.dart';
import '../scanner/qr_scanner_screen.dart';
import '../admin/user_management_screen.dart';
import '../admin/import_screen.dart';
import '../../models/equipment_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentProvider>()
        ..listenToEquipments()
        ..loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final eqProv = context.watch<EquipmentProvider>();
    final user = auth.currentUser;
    final stats = eqProv.stats;
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => eqProv.loadStats(),
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _confirmLogout(context),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                radius: 24,
                                child: Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'สวัสดี, ${user?.fullName ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAdmin
                                          ? AppColors.accent
                                          : Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isAdmin ? '👑 Admin' : '👤 User',
                                      style: TextStyle(
                                        color: isAdmin
                                            ? Colors.black87
                                            : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Stats Cards ───────────────────────────────────
                    const _SectionTitle(title: '📊 สรุปครุภัณฑ์'),
                    const SizedBox(height: 12),
                    _StatsGrid(stats: stats),
                    const SizedBox(height: 24),

                    // ─── Quick Actions ─────────────────────────────────
                    const _SectionTitle(title: '⚡ เมนูหลัก'),
                    const SizedBox(height: 12),
                    _QuickActionsGrid(isAdmin: isAdmin),
                    const SizedBox(height: 24),

                    // ─── Recent (last 5) ───────────────────────────────
                    const _SectionTitle(title: '🕐 ครุภัณฑ์ล่าสุด'),
                    const SizedBox(height: 12),
                    _RecentEquipments(
                      items: eqProv.equipments.take(5).toList(),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ─── FAB ────────────────────────────────────────────────────────────
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEquipmentScreen()),
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'เพิ่มครุภัณฑ์',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ออกจากระบบ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ต้องการออกจากระบบใช่หรือไม่?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthProvider>().logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Grid ───────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        'ทั้งหมด',
        stats['total'] ?? 0,
        Icons.inventory_2,
        AppColors.primary,
      ),
      _StatItem(
        'ปกติ',
        stats['normal'] ?? 0,
        Icons.check_circle,
        AppColors.statusNormal,
      ),
      _StatItem(
        'ชำรุด',
        stats['damaged'] ?? 0,
        Icons.broken_image,
        AppColors.statusDamaged,
      ),
      _StatItem(
        'รอซ่อม',
        stats['repairing'] ?? 0,
        Icons.build,
        AppColors.statusRepairing,
      ),
      _StatItem(
        'จำหน่าย',
        stats['disposed'] ?? 0,
        Icons.delete_forever,
        AppColors.statusDisposed,
      ),
      _StatItem(
        'สูญหาย',
        stats['lost'] ?? 0,
        Icons.search_off,
        AppColors.statusLost,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.count, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.count}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: item.color,
            ),
          ),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final bool isAdmin;
  const _QuickActionsGrid({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        'รายการครุภัณฑ์',
        Icons.list_alt,
        AppColors.primary,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EquipmentListScreen()),
        ),
      ),
      _QuickAction(
        'สแกน QR Code',
        Icons.qr_code_scanner,
        AppColors.secondary,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
        ),
      ),
      if (isAdmin)
        _QuickAction(
          'เพิ่มครุภัณฑ์',
          Icons.add_box,
          AppColors.accent,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEquipmentScreen()),
          ),
        ),
      if (isAdmin)
        _QuickAction(
          'นำเข้าข้อมูล',
          Icons.upload_file,
          AppColors.warning,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImportScreen()),
          ),
        ),
      if (isAdmin)
        _QuickAction(
          'จัดการผู้ใช้',
          Icons.people,
          const Color(0xFF9C27B0),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserManagementScreen()),
          ),
        ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: actions.map((a) => _QuickActionCard(action: a)).toList(),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ─── Recent Equipment ─────────────────────────────────────────────────────────
class _RecentEquipments extends StatelessWidget {
  final List<EquipmentModel> items;
  const _RecentEquipments({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'ยังไม่มีข้อมูลครุภัณฑ์',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: items.map((e) {
        final color = getStatusColor(e.status.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  getStatusIcon(e.status.value),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${e.assetCode} · ${e.location}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  getStatusLabel(e.status.value),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
