import 'package:flutter/material.dart';

import '../models/facility_model.dart';
import '../theme/app_colors.dart';

const _teal = Color(0xFF08766C);
const _pageBackground = Color(0xFFF5F4EE);

class FacilitySearchPage extends StatefulWidget {
  const FacilitySearchPage({super.key});

  @override
  State<FacilitySearchPage> createState() => _FacilitySearchPageState();
}

class _FacilitySearchPageState extends State<FacilitySearchPage> {
  static const _statusFilters = ['Semua', 'Tersedia', 'Dipinjam', 'Maintenance'];

  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Semua';
  String _status = 'Semua';

  int get _activeFilterCount =>
      (_category == 'Semua' ? 0 : 1) + (_status == 'Semua' ? 0 : 1);

  List<Facility> get _results {
    final query = _query.trim().toLowerCase();
    return dummyFacilities.where((f) {
      if (_category != 'Semua' && f.type != _category) return false;
      if (_status != 'Semua' && f.status != _status) return false;
      if (query.isEmpty) return true;
      return f.name.toLowerCase().contains(query) ||
          f.id.toLowerCase().contains(query) ||
          f.type.toLowerCase().contains(query) ||
          f.building.toLowerCase().contains(query) ||
          f.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchRow(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Text(
                'Hasil Pencarian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const _EmptyState(
                      icon: Icons.search_off,
                      title: 'Fasilitas tidak ditemukan',
                      message: 'Coba kata kunci lain atau ubah filter.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _SearchResultCard(facility: results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'lib/assets/images/logo_spara/logo_gelap.png',
                height: 36,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.apartment, color: _teal, size: 28),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Spara Mobile',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Pencarian',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Temukan ruangan dan peralatan yang kamu butuhkan',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textGrey,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    final count = _activeFilterCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari nama fasilitas, ID, atau lokasi',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close, size: 20),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            backgroundColor: const Color(0xFFD34E4E),
            child: Material(
              color: count > 0 ? _teal : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: const ValueKey('open-search-filter'),
                borderRadius: BorderRadius.circular(14),
                onTap: _openFilterSheet,
                child: Tooltip(
                  message: 'Filter kategori & status',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.tune,
                      color: count > 0 ? Colors.white : _teal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    var draftCategory = _category;
    var draftStatus = _status;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          Widget chip({
            required String label,
            required bool selected,
            required VoidCallback onTap,
            IconData? icon,
          }) {
            return ChoiceChip(
              avatar: icon == null
                  ? null
                  : Icon(icon,
                      size: 18, color: selected ? Colors.white : _teal),
              label: Text(label),
              selected: selected,
              onSelected: (_) => onTap(),
              showCheckmark: false,
              selectedColor: _teal,
              backgroundColor: const Color(0xFFF1F4F2),
              side: BorderSide.none,
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textDark,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }

          Widget sectionTitle(String text) => Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 6),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              );

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter fasilitas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheet(() {
                          draftCategory = 'Semua';
                          draftStatus = 'Semua';
                        }),
                        style: TextButton.styleFrom(foregroundColor: _teal),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  sectionTitle('Kategori'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in ['Semua', 'Ruangan', 'Peralatan'])
                        chip(
                          label: option,
                          selected: draftCategory == option,
                          onTap: () =>
                              setSheet(() => draftCategory = option),
                        ),
                    ],
                  ),
                  sectionTitle('Status'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in _statusFilters)
                        chip(
                          label: option,
                          selected: draftStatus == option,
                          onTap: () => setSheet(() => draftStatus = option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => setState(() {
                        _category = draftCategory;
                        _status = draftStatus;
                        Navigator.pop(context);
                      }),
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Terapkan filter'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.facility});

  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                facility.imagePath,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFE3F1EE),
                  child: const Icon(
                    Icons.meeting_room_outlined,
                    color: _teal,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: facility.status),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.apartment,
                          size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 3),
                      Text(
                        facility.building,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.stairs,
                          size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 3),
                      Text(
                        facility.floor,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      'Tersedia' => const Color(0xFF198B68),
      'Dipinjam' => _teal,
      'Maintenance' => const Color(0xFFC98F0A),
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: _teal),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}
