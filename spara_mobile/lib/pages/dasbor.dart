import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/facility_model.dart';
import '../widgets/bottom_nav_bar.dart';
import 'bottom_nav_pages.dart';
import 'riwayat.dart';
import 'profil.dart';

class DasborPage extends StatefulWidget {
  const DasborPage({super.key});

  @override
  State<DasborPage> createState() => _DasborPageState();
}

class _DasborPageState extends State<DasborPage> {
  static const int _itemsPerPage = 3;
  static const _pageBackground = Color(0xFFF4F7F6);
  static const _deepTeal = Color(0xFF064B45);
  static const _green = Color(0xFF197B47);

  static const _tabs = [
    (label: 'Ruangan & Laboratorium', icon: Icons.meeting_room_outlined),
    (label: 'Peralatan & Inventaris', icon: Icons.devices_outlined),
  ];

  static const _chips = [
    (label: 'Proyektor', icon: Icons.view_in_ar_outlined),
    (label: 'Komputer', icon: Icons.computer_outlined),
    (label: 'Papan Tulis', icon: Icons.desktop_windows_outlined),
  ];

  static const _notifications = [
    (
      icon: Icons.check_circle_outline,
      title: 'Pengajuan disetujui',
      body: 'Peminjaman Ruang Seminar R.302 telah disetujui Admin.',
      time: '2 jam lalu',
    ),
    (
      icon: Icons.schedule,
      title: 'Menunggu persetujuan',
      body: 'Pengajuan Kamera Sony A6400 sedang ditinjau.',
      time: 'Kemarin',
    ),
    (
      icon: Icons.event_available_outlined,
      title: 'Pengingat jadwal',
      body: 'Jadwal peminjaman Proyektor Epson besok pukul 13:00.',
      time: '2 hari lalu',
    ),
  ];

  int _navIndex = 0;
  int _selectedCategory = 0;
  int _currentPage = 1;
  int? _selectedChip;
  bool _hasUnread = true;

  List<Facility> get _filteredFacilities {
    final category = _selectedCategory == 0 ? 'Ruangan' : 'Peralatan';
    final chip = _selectedChip == null
        ? null
        : _chips[_selectedChip!].label.toLowerCase();
    return dummyFacilities.where((f) {
      if (f.type != category) return false;
      if (chip == null) return true;
      return '${f.name} ${f.type} ${f.building}'.toLowerCase().contains(chip);
    }).toList();
  }

  int _pageCountFor(int total) =>
      (total / _itemsPerPage).ceil().clamp(1, 999).toInt();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi,';
    if (h < 15) return 'Selamat siang,';
    if (h < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  void _onNavTap(int index) => setState(() => _navIndex = index);

  void _onBackToDashboard() {
    if (_navIndex != 0) setState(() => _navIndex = 0);
  }

  void _goToPage(int page, int pageCount) {
    if (page < 1 || page > pageCount) return;
    setState(() => _currentPage = page);
  }

  void _toast(String message, {IconData icon = Icons.info_outline}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _showNotifications() async {
    setState(() => _hasUnread = false);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              for (final n in _notifications)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          n.icon,
                          color: AppColors.darkTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.body,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textGrey,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.time,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _onNavTap(2);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkTeal,
                    side: const BorderSide(color: AppColors.darkTeal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Lihat riwayat peminjaman'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFacilityDetail(Facility f) async {
    final borrow = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.darkTeal),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4F4A), Color(0xFF2C7A72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    f.type == 'Ruangan'
                        ? Icons.meeting_room_outlined
                        : Icons.devices_outlined,
                    size: 52,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  f.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kode ${f.id}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                row(Icons.apartment_outlined, 'Gedung', f.building),
                row(Icons.layers_outlined, 'Lantai', '${f.floor}'),
                row(Icons.people_outline, 'Kapasitas', '${f.capacity}'),
                row(Icons.category_outlined, 'Kategori', f.type),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: Color(0xFFD8E2E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Pinjam Sekarang'),
                        iconAlignment: IconAlignment.end,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (borrow == true && mounted) await _showBookingSheet(f);
  }

  Future<void> _showBookingSheet(Facility f) async {
    DateTime? date;
    TimeOfDay? start;
    TimeOfDay? end;
    var purpose = '';
    String? error;

    String two(int v) => v.toString().padLeft(2, '0');
    String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
    String fmtTime(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}';
    int mins(TimeOfDay t) => t.hour * 60 + t.minute;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          Widget picker({
            required IconData icon,
            required String label,
            required String? value,
            required VoidCallback onTap,
          }) {
            final filled = value != null;
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F9F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: filled
                        ? AppColors.accentTeal
                        : const Color(0xFFE1E8E8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.darkTeal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        value ?? label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: filled
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: filled ? AppColors.textDark : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

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
                  const Text(
                    'Ajukan Peminjaman',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${f.name} · ${f.building}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  picker(
                    icon: Icons.calendar_month_outlined,
                    label: 'Pilih tanggal',
                    value: date == null ? null : fmtDate(date!),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date ?? now,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: now.add(const Duration(days: 90)),
                      );
                      if (picked != null) setSheet(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: picker(
                          icon: Icons.schedule,
                          label: 'Mulai',
                          value: start == null ? null : fmtTime(start!),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  start ?? const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (picked != null) setSheet(() => start = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: picker(
                          icon: Icons.schedule,
                          label: 'Selesai',
                          value: end == null ? null : fmtTime(end!),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  end ?? const TimeOfDay(hour: 10, minute: 0),
                            );
                            if (picked != null) setSheet(() => end = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => purpose = v.trim(),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Keperluan peminjaman',
                      filled: true,
                      fillColor: const Color(0xFFF6F9F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.accentTeal,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        if (date == null || start == null || end == null) {
                          setSheet(
                            () =>
                                error = 'Lengkapi tanggal dan jam peminjaman.',
                          );
                          return;
                        }
                        if (mins(end!) <= mins(start!)) {
                          setSheet(
                            () =>
                                error = 'Jam selesai harus setelah jam mulai.',
                          );
                          return;
                        }
                        if (purpose.isEmpty) {
                          setSheet(() => error = 'Isi keperluan peminjaman.');
                          return;
                        }
                        Navigator.pop(sheetContext, true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Kirim pengajuan'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (submitted == true && mounted) {
      _toast(
        'Pengajuan ${f.name} terkirim (pratinjau lokal).',
        icon: Icons.check_circle_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBackToDashboard();
      },
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: IndexedStack(
          index: _navIndex,
          children: [
            _buildDashboard(context),
            FacilitySearchPage(onFacilitySelected: _showFacilityDetail),
            const LoanHistoryPage(),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: MainBottomNavBar(
          currentIndex: _navIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildLoanInfoCard(), _buildRecommendationPanel()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _onNavTap(3),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFDDF3EF),
                        child: Text(
                          'RT',
                          style: TextStyle(
                            color: AppColors.darkTeal,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
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
                          _greeting,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                        const Text(
                          'Rajiv Tajusa David',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Badge(
                    isLabelVisible: _hasUnread,
                    smallSize: 10,
                    backgroundColor: const Color(0xFFFF5252),
                    alignment: const AlignmentDirectional(24, 8),
                    child: IconButton(
                      key: const ValueKey('dashboard-notifications'),
                      tooltip: 'Notifikasi',
                      onPressed: _showNotifications,
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const Text(
                      'Mau pinjam apa hari ini?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 2,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        key: const ValueKey('dashboard-search'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _onNavTap(1),
                        child: const SizedBox(
                          height: 50,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: AppColors.darkTeal,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Cari fasilitas kampus...',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.tune,
                                  color: AppColors.accentTeal,
                                  size: 20,
                                ),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildLoanInfoCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.darkTeal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Informasi Peminjaman Saya',
                    style: TextStyle(
                      color: AppColors.darkTeal,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Dalam Proses',
                    value: '8',
                    unit: 'Pengajuan',
                    caption: 'Menunggu disetujui',
                    backgroundColor: const Color(0xFFEAF8F5),
                    foregroundColor: AppColors.darkTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    icon: Icons.task_alt_rounded,
                    title: 'Selesai',
                    value: '24',
                    unit: 'Peminjaman',
                    caption: 'Telah selesai dilakukan',
                    backgroundColor: const Color(0xFFEEF1FB),
                    foregroundColor: const Color(0xFF26334F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('dashboard-view-history'),
                onPressed: () => _onNavTap(2),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Lihat Riwayat Lengkap'),
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentTeal,
                  minimumSize: const Size(0, 40),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String caption,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onNavTap(2),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: foregroundColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                caption,
                style: TextStyle(
                  color: foregroundColor.withValues(alpha: 0.72),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationPanel() {
    final filtered = _filteredFacilities;
    final pageCount = _pageCountFor(filtered.length);
    final page = _currentPage.clamp(1, pageCount).toInt();
    final items = filtered
        .skip((page - 1) * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return Container(
      key: const ValueKey('recommendation-panel'),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF19796F), Color(0xFF08766C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Color(0xFFFFC107),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Rekomendasi Kilat',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saran cepat alat/ruangan sesuai dengan kebutuhan Anda.',
                  style: TextStyle(color: Color(0xFFCFE3E0), fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                _buildCategoryTabs(),
                const SizedBox(height: 14),
                _buildCapacityChips(),
              ],
            ),
          ),
          if (items.isEmpty)
            _buildEmptyRecommendation()
          else
            ListView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
              itemBuilder: (context, index) => _FacilityCard(
                facility: items[index],
                onDetail: () => _showFacilityDetail(items[index]),
                onBorrow: () => _showBookingSheet(items[index]),
              ),
            ),
          _buildPagination(page, pageCount),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off, color: Colors.white70, size: 44),
            const SizedBox(height: 8),
            const Text(
              'Belum ada rekomendasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba kategori lain atau hapus filter.',
              style: TextStyle(color: Color(0xFFCFE3E0), fontSize: 12.5),
            ),
            if (_selectedChip != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _selectedChip = null;
                  _currentPage = 1;
                }),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Hapus filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedCategory == i;
          final tab = _tabs[i];
          return Expanded(
            child: GestureDetector(
              key: ValueKey('recommendation-tab-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                _selectedCategory = i;
                _currentPage = 1;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 20,
                      color: selected ? AppColors.darkTeal : Colors.white70,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? _deepTeal : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCapacityChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_chips.length, (i) {
        final selected = _selectedChip == i;
        final chip = _chips[i];
        return FilterChip(
          avatar: Icon(
            chip.icon,
            size: 18,
            color: selected ? Colors.white : AppColors.darkTeal,
          ),
          label: Text(chip.label),
          selected: selected,
          onSelected: (value) => setState(() {
            _selectedChip = value ? i : null;
            _currentPage = 1;
          }),
          selectedColor: _deepTeal,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : _deepTeal,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          showCheckmark: false,
        );
      }),
    );
  }

  Widget _buildPagination(int page, int pageCount) {
    final canPrev = page > 1;
    final canNext = page < pageCount;

    Widget navButton({
      required Key key,
      required String tooltip,
      required IconData icon,
      required VoidCallback? onTap,
    }) {
      return IconButton(
        key: key,
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          fixedSize: const Size(44, 44),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkTeal,
          disabledBackgroundColor: Colors.white24,
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          navButton(
            key: const ValueKey('recommendation-previous'),
            tooltip: 'Sebelumnya',
            icon: Icons.chevron_left,
            onTap: canPrev ? () => _goToPage(page - 1, pageCount) : null,
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(pageCount, (i) {
                  final p = i + 1;
                  final isActive = p == page;
                  return Semantics(
                    button: true,
                    selected: isActive,
                    label: 'Halaman $p',
                    child: GestureDetector(
                      onTap: () => _goToPage(p, pageCount),
                      child: AnimatedContainer(
                        key: ValueKey('recommendation-page-$p'),
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive ? _deepTeal : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$p',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          navButton(
            key: const ValueKey('recommendation-next'),
            tooltip: 'Berikutnya',
            icon: Icons.chevron_right,
            onTap: canNext ? () => _goToPage(page + 1, pageCount) : null,
          ),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.facility,
    required this.onDetail,
    required this.onBorrow,
  });

  final Facility facility;
  final VoidCallback onDetail;
  final VoidCallback onBorrow;

  static const Color _lihatDetailColor = Color(0xFF2E474C);
  static const Color _pinjamColor = Color(0xFF197B47);

  @override
  Widget build(BuildContext context) {
    final isRoom = facility.type == 'Ruangan';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onDetail,
            child: Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B4F4A), Color(0xFF2C7A72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isRoom
                          ? Icons.meeting_room_outlined
                          : Icons.devices_outlined,
                      size: 56,
                      color: Colors.white38,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.apartment,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          facility.building,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F3EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        facility.id,
                        style: const TextStyle(
                          color: _pinjamColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _infoChip(Icons.people_outline, '${facility.capacity}'),
                    _infoChip(Icons.layers_outlined, '${facility.floor}'),
                    _infoChip(Icons.category_outlined, facility.type),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: ValueKey('detail-${facility.id}'),
                        onPressed: onDetail,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: _lihatDetailColor,
                            width: 1.5,
                          ),
                          foregroundColor: _lihatDetailColor,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Lihat Detail'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: ValueKey('borrow-${facility.id}'),
                        onPressed: onBorrow,
                        style: FilledButton.styleFrom(
                          backgroundColor: _pinjamColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5E6B75)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF3F4A52)),
          ),
        ],
      ),
    );
  }
}
