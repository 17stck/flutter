// lib/screens/equipment/equipment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/equipment_model.dart';
import '../../models/check_history_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/equipment_provider.dart';
import '../../services/equipment_service.dart';
import '../../utils/app_theme.dart';
import 'add_equipment_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final EquipmentModel equipment;
  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late EquipmentModel _equipment;

  @override
  void initState() {
    super.initState();
    _equipment = widget.equipment;
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showStatusDialog() {
    final user = context.read<AuthProvider>().currentUser!;
    final noteCtrl = TextEditingController();
    EquipmentStatus? selectedStatus = _equipment.status;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'อัปเดตสถานะครุภัณฑ์',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...EquipmentStatus.values.map((s) {
                  final color = getStatusColor(s.value);
                  return RadioListTile<EquipmentStatus>(
                    dense: true,
                    value: s,
                    groupValue: selectedStatus,
                    title: Row(
                      children: [
                        Icon(getStatusIcon(s.value), color: color, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onChanged: (v) => setStateDialog(() => selectedStatus = v),
                  );
                }),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'หมายเหตุ (ถ้ามี)',
                    prefixIcon: Icon(Icons.note),
                  ),
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
                Navigator.pop(ctx);
                final ok = await context.read<EquipmentProvider>().updateStatus(
                      equipment: _equipment,
                      newStatus: selectedStatus!,
                      checkedBy: user.uid,
                      checkedByName: user.fullName,
                      note: noteCtrl.text.trim(),
                    );
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ อัปเดตสถานะเรียบร้อย'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _equipment.assetCode,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: _equipment.assetCode,
              size: 200,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _equipment.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบครุภัณฑ์'),
        content: Text('ต้องการลบ "${_equipment.name}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await context.read<EquipmentProvider>().deleteEquipment(
            _equipment.id,
          );
      if (ok && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final updated = context
        .watch<EquipmentProvider>()
        .equipments
        .where((e) => e.id == _equipment.id)
        .firstOrNull;
    if (updated != null) _equipment = updated;

    final color = getStatusColor(_equipment.status.value);
    final fmt = DateFormat('d MMM yyyy', 'th');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: _showQrDialog,
              ),
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEquipmentScreen(equipment: _equipment),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _equipment.imageUrl != null
                  ? Image.network(_equipment.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.devices,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
            ),
          ),
        ],
        body: Column(
          children: [
            // ─── Header Info ──────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _equipment.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showStatusDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                getStatusIcon(_equipment.status.value),
                                color: color,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _equipment.status.label,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit, color: color, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.qr_code,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _equipment.assetCode,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Tabs ──────────────────────────────────────────────────
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'รายละเอียด'),
                  Tab(text: 'QR Code'),
                  Tab(text: 'ประวัติ'),
                ],
              ),
            ),

            // ─── Tab Content ───────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: Details
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoCard(
                          items: [
                            _InfoRow(
                              'รหัสครุภัณฑ์',
                              _equipment.assetCode,
                              Icons.qr_code,
                            ),
                            _InfoRow('ชื่อ', _equipment.name, Icons.devices),
                            _InfoRow(
                              'ประเภท',
                              _equipment.category,
                              Icons.category,
                            ),
                            _InfoRow(
                              'ยี่ห้อ',
                              _equipment.brand,
                              Icons.branding_watermark,
                            ),
                            _InfoRow(
                              'รุ่น',
                              _equipment.model,
                              Icons.model_training,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(
                          items: [
                            _InfoRow(
                              'ที่ตั้ง',
                              _equipment.location,
                              Icons.location_on,
                            ),
                            if (_equipment.serialNumber?.isNotEmpty == true)
                              _InfoRow(
                                'Serial No.',
                                _equipment.serialNumber!,
                                Icons.numbers,
                              ),
                            if (_equipment.purchasePrice != null)
                              _InfoRow(
                                'ราคาซื้อ',
                                '฿${_equipment.purchasePrice!.toStringAsFixed(0)}',
                                Icons.attach_money,
                              ),
                            _InfoRow(
                              'เพิ่มเมื่อ',
                              fmt.format(_equipment.createdAt),
                              Icons.calendar_today,
                            ),
                          ],
                        ),
                        if (_equipment.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'รายละเอียด',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(_equipment.description),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Tab 2: QR Code
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: _equipment.assetCode,
                                size: 220,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _equipment.assetCode,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                _equipment.name,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'สแกน QR Code เพื่อค้นหาครุภัณฑ์',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: History
                  _HistoryTab(equipmentId: _equipment.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<Widget> items;
  const _InfoCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoRow(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final String equipmentId;
  const _HistoryTab({required this.equipmentId});

  @override
  Widget build(BuildContext context) {
    final svc = EquipmentService();
    return StreamBuilder<List<CheckHistoryModel>>(
      stream: svc.getCheckHistory(equipmentId: equipmentId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'ยังไม่มีประวัติการตรวจสอบ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final h = items[i];
            final fmt = DateFormat('d MMM yyyy HH:mm', 'th');
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusPill(h.statusBefore),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 14),
                      ),
                      _StatusPill(h.statusAfter),
                      const Spacer(),
                      Text(
                        fmt.format(h.checkedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        h.checkedByName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (h.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      h.note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        getStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
