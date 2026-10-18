import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/facility_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _typeFilter = 'Semua';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Facility> get _results {
    return dummyFacilities.where((f) {
      final matchType = _typeFilter == 'Semua' || f.type == _typeFilter;
      final q = _query.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          f.name.toLowerCase().contains(q) ||
          f.building.toLowerCase().contains(q) ||
          f.id.toLowerCase().contains(q);
      return matchType && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.darkTeal,
        foregroundColor: Colors.white,
        title: const Text('Cari Fasilitas'),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildFilterChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length} hasil ditemukan',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: results.length,
                    itemBuilder: (context, i) =>
                        _SearchResultCard(facility: results[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Cari fasilitas kampus...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.midTeal, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const options = ['Semua', 'Ruangan', 'Peralatan'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = _typeFilter == options[i];
          return ChoiceChip(
            label: Text(options[i]),
            selected: selected,
            onSelected: (_) => setState(() => _typeFilter = options[i]),
            selectedColor: AppColors.midTeal,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textDark,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Fasilitas tidak ditemukan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba kata kunci lain atau ubah filter.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Facility facility;
  const _SearchResultCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.meeting_room_outlined),
        title: Text(facility.name),
        subtitle: Text('${facility.building} • ${facility.floor}'),
        trailing: Text(facility.id),
        onTap: () {},
      ),
    );
  }
}