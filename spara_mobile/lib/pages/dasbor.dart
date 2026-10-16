import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/facility_model.dart';
import '../widgets/bottom_nav_bar.dart';

class DasborPage extends StatefulWidget {
  const DasborPage({super.key});

  @override
  State<DasborPage> createState() => _DasborPageState();
}

class _DasborPageState extends State<DasborPage> {
  int _navIndex = 0;
  int _selectedCategory = 0;
  int _currentPage = 1;
  final int _totalPages = 3;
  int? _selectedChip;
  static const int _itemsPerPage = 3;

  List<Facility> get _filteredFacilities {
    final category = _selectedCategory == 0 ? 'Ruangan' : 'Peralatan';
    return dummyFacilities.where((f) => f.type == category).toList();
  }

  List<Facility> get _pageFacilities {
    final all = _filteredFacilities;
    return List.generate(_itemsPerPage, (i) => all[i % all.length]);
  }

  void _onNavTap(int index) => setState(() => _navIndex = index);
  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLoanInfoCard(),
                  _buildRecommendationSection(),
                  _buildFacilityList(),
                  _buildPagination(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Text(
                      'RT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Selamat datang,',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'Rajiv Tajusal!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 28),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5252),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Mau pinjem apa nih hari ini?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Cari fasilitas kampus...',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanInfoCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.midTeal,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.assignment_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Informasi Peminjaman Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _buildStatBox(
                        'Dalam Proses', '8', 'Pengajuan',
                        'Menunggu disetujui')),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildStatBox(
                        'Peminjaman Selesai', '24', 'Peminjaman',
                        'Telah selesai dilakukan')),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Lihat Riwayat Lengkap →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(
      String title, String value, String unit, String caption) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '\n$unit',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(caption,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bolt, color: Color(0xFFFFC107), size: 20),
              SizedBox(width: 6),
              Text(
                'Rekomendasi Kilat',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Saran cepat dari/ruangan yang sesuai kebutuhan anda.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 14),
          _buildCategoryTabs(),
          const SizedBox(height: 12),
          _buildCapacityChips(),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    const tabs = [
      ['Ruangan &\nLaboratorium', Icons.meeting_room_outlined],
      ['Peralatan &\nInventaris', Icons.devices_outlined],
    ];
    return Row(
      children: List.generate(tabs.length, (i) {
        final selected = _selectedCategory == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = i;
              _currentPage = 1;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.midTeal : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.midTeal
                      : Colors.grey.shade200,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color:
                              AppColors.midTeal.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tabs[i][1] as IconData,
                    size: 18,
                    color: selected ? Colors.white : AppColors.midTeal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tabs[i][0] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCapacityChips() {
    const chips = ['Proyektor', 'Komputer', 'Papan Tulis'];
    return Wrap(
      spacing: 8,
      children: List.generate(chips.length, (i) {
        final selected = _selectedChip == i;
        return ChoiceChip(
          label: Text(chips[i]),
          selected: selected,
          onSelected: (val) =>
              setState(() => _selectedChip = val ? i : null),
          // Selected: midTeal; unselected: white
          selectedColor: AppColors.midTeal,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          side: BorderSide(
            color: selected ? AppColors.midTeal : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }),
    );
  }

  Widget _buildFacilityList() {
    final items = _pageFacilities;
    return ListView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemBuilder: (context, index) =>
          _FacilityCard(facility: items[index]),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              '$_currentPage dari $_totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),

          Row(
            children: List.generate(_totalPages, (i) {
              final page = i + 1;
              final isActive = page == _currentPage;
              return GestureDetector(
                onTap: () => _goToPage(page),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.darkTeal
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? AppColors.darkTeal
                          : Colors.grey.shade200,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$page',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : AppColors.textDark,
                    ),
                  ),
                ),
              );
            }),
          ),

          ElevatedButton.icon(
            onPressed: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Berikutnya'),
            iconAlignment: IconAlignment.end,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final Facility facility;
  const _FacilityCard({required this.facility});

  static const Color _lihatDetailColor  = Color(0xFF2E474C);
  static const Color _pinjamColor       = Color(0xFF197B47);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3E40), Color(0xFF1B4F4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.meeting_room_outlined,
                      size: 56, color: Colors.white38),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    facility.building,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        facility.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        facility.id,
                        style: const TextStyle(
                          color: _pinjamColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _infoChip(Icons.people_outline, facility.capacity),
                    _infoChip(Icons.layers_outlined, facility.floor),
                    _infoChip(Icons.category_outlined, facility.type),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: _lihatDetailColor, width: 1.5),
                          foregroundColor: _lihatDetailColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Lihat Detail'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinjamColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Pinjam Sekarang →'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
