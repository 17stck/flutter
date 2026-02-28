// lib/screens/equipment/equipment_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/equipment_model.dart';
import '../../utils/app_theme.dart';
import 'equipment_detail_screen.dart';
import 'package:equipment_app/models/equipment_model.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _searchCtrl = TextEditingController();
  EquipmentStatus? _filterStatus;
  bool _isSearchMode = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eqProv = context.watch<EquipmentProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    // เลือก list ที่จะแสดง
    List<EquipmentModel> displayList = _isSearchMode
        ? eqProv.searchResults
        : _filterStatus != null
            ? eqProv.equipments.where((e) => e.status == _filterStatus).toList()
            : eqProv.equipments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการครุภัณฑ์'),
        actions: [
          IconButton(
            icon: Icon(_isSearchMode ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
                if (!_isSearchMode) {
                  _searchCtrl.clear();
                  eqProv.search('');
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar ────────────────────────────────────────────────
          if (_isSearchMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ค้นหาด้วย รหัส, ชื่อ, ยี่ห้อ, สถานที่...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            eqProv.search('');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => eqProv.search(v),
              ),
            ),

          // ─── Filter Chips ──────────────────────────────────────────────
          if (!_isSearchMode)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _FilterChip(
                    label: 'ทั้งหมด',
                    isSelected: _filterStatus == null,
                    color: AppColors.primary,
                    onTap: () => setState(() => _filterStatus = null),
                  ),
                  ...EquipmentStatus.values.map(
                    (s) => _FilterChip(
                      label: s.label,
                      isSelected: _filterStatus == s,
                      color: getStatusColor(s.value),
                      onTap: () => setState(() => _filterStatus = s),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Count ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'พบ ${displayList.length} รายการ',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ─── List ──────────────────────────────────────────────────────
          Expanded(
            child: eqProv.isSearching
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? _EmptyState(isSearch: _isSearchMode)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: displayList.length,
                        itemBuilder: (_, i) => _EquipmentCard(
                          equipment: displayList[i],
                          isAdmin: isAdmin,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EquipmentDetailScreen(
                                  equipment: displayList[i]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── Equipment Card ───────────────────────────────────────────────────────────
class _EquipmentCard extends StatelessWidget {
  final EquipmentModel equipment;
  final bool isAdmin;
  final VoidCallback onTap;
  const _EquipmentCard({
    required this.equipment,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(equipment.status.value);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Image / Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: equipment.imageUrl != null
                    ? Image.network(
                        equipment.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _PlaceholderIcon(color: color),
                      )
                    : _PlaceholderIcon(color: color),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            equipment.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusBadge(
                          label: equipment.status.label,
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          equipment.assetCode,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            equipment.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          equipment.category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final Color color;
  const _PlaceholderIcon({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.devices, color: color, size: 28),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({required this.isSearch});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            isSearch ? 'ไม่พบครุภัณฑ์ที่ค้นหา' : 'ยังไม่มีข้อมูลครุภัณฑ์',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
