import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/facility_model.dart';

const _cream = Color(0xFFFBF6EE);

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _typeFilter = 'Semua';
  bool _showFilter = false;

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
    final hasInput = _query.trim().isNotEmpty || _typeFilter != 'Semua';

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchRow(),
            if (_showFilter) _buildFilterButtons(),
            if (hasInput && results.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Hasil Pencarian',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.darkTeal,
                  ),
                ),
              ),
            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      itemCount: results.length,
                      itemBuilder: (context, i) =>
                          _SearchResultCard(facility: results[i]),
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
              // Ganti dengan logo asli: Image.asset('assets/images/logo.png', height: 32)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.darkTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apartment, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'SPARA MOBILE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Pencarian',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Temukan ruangan dan peralatan\nyang kamu butuhkan',
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari nama fasilitas, ID, atau status',
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.midTeal, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.darkTeal,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _showFilter = !_showFilter),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.tune, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    const options = ['Ruangan', 'Peralatan'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: options.map((o) {
          final selected = _typeFilter == o;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: o == options.first ? 10 : 0),
              child: GestureDetector(
                // tap lagi untuk batal filter
                onTap: () =>
                    setState(() => _typeFilter = selected ? 'Semua' : o),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.darkTeal : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.darkTeal
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    o,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected ? Colors.white : AppColors.darkTeal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F7F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2,
                  size: 40, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pencarian tidak ditemukan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.darkTeal,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ketik nama ruangan atau gedung untuk mulai mencari. '
              'Anda dapat memfilter hasilnya nanti.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade700, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Facility facility;
  const _SearchResultCard({required this.facility});

  @override
  Widget build(BuildContext context) {
    // Asumsi: model Facility punya field `status` ('Tersedia' / 'Maintenance' / dll)
    final status = facility.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/ruang_kelas.jpg', // ganti sesuai aset kamu
                width: 74,
                height: 74,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 74,
                  height: 74,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.meeting_room_outlined),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.darkTeal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(status: status),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.apartment,
                          size: 12, color: Colors.grey.shade700),
                      const SizedBox(width: 3),
                      Text(facility.building,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade700)),
                      const SizedBox(width: 12),
                      Icon(Icons.stairs,
                          size: 12, color: Colors.grey.shade700),
                      const SizedBox(width: 3),
                      Text(facility.floor,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade700)),
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
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    switch (status) {
      case 'Tersedia':
        bg = const Color(0xFF2EE62E);
        break;
      case 'Maintenance':
        bg = const Color(0xFFF5B800);
        break;
      default:
        bg = Colors.grey.shade400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTeal,
        ),
      ),
    );
  }
}