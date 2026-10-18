import 'package:flutter/material.dart';

import '../models/facility_model.dart';
import '../theme/app_colors.dart';

class FacilitySearchPage extends StatefulWidget {
  const FacilitySearchPage({super.key});

  @override
  State<FacilitySearchPage> createState() => _FacilitySearchPageState();
}

class _FacilitySearchPageState extends State<FacilitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<Facility> get _results {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return dummyFacilities;
    return dummyFacilities.where((facility) {
      return facility.name.toLowerCase().contains(query) ||
          facility.id.toLowerCase().contains(query) ||
          facility.type.toLowerCase().contains(query) ||
          facility.building.toLowerCase().contains(query);
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
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Pencarian Fasilitas'),
        backgroundColor: AppColors.darkTeal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari nama, kode, jenis, atau gedung',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const _EmptyState(
                    icon: Icons.search_off,
                    title: 'Fasilitas tidak ditemukan',
                    message: 'Coba kata kunci lain.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _FacilityResultCard(facility: results[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FacilityResultCard extends StatelessWidget {
  const _FacilityResultCard({required this.facility});

  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            facility.type == 'Ruangan'
                ? Icons.meeting_room_outlined
                : Icons.devices_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(facility.name),
        subtitle: Text(
          '${facility.id} - ${facility.type} - ${facility.building}',
        ),
        isThreeLine: true,
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
            Icon(icon, size: 52, color: AppColors.midTeal),
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
