import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

enum _Category {
  peralatan('PERALATAN', 'Peralatan', Icons.photo_camera_outlined),
  ruangan('RUANGAN', 'Ruangan', Icons.meeting_room_outlined);

  const _Category(this.code, this.label, this.icon);
  final String code;
  final String label;
  final IconData icon;
}

enum _Period {
  all('Semua waktu'),
  week('7 hari terakhir'),
  month('30 hari terakhir'),
  custom('Pilih tanggal');

  const _Period(this.label);
  final String label;
}

class LoanHistoryPage extends StatefulWidget {
  const LoanHistoryPage({super.key});

  @override
  State<LoanHistoryPage> createState() => _LoanHistoryPageState();
}

class _LoanHistoryPageState extends State<LoanHistoryPage> {
  static const _itemsPerPage = 4;
  static const _statusFilters = [
    'Semua',
    'Menunggu',
    'Disetujui',
    'Selesai',
    'Dibatalkan',
  ];
  static const _teal = Color(0xFF08766C);
  static const _pageBackground = Color(0xFFF5F4EE);
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  final _searchController = TextEditingController();
  String _query = '';
  String _selectedStatus = 'Semua';
  _Category? _category; // null = semua kategori
  _Period _period = _Period.all;
  DateTimeRange? _customRange;
  int _page = 1;

  late final List<_LoanRecord> _records = _buildSampleRecords();

  // ---------------------------------------------------------------- data

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  List<_LoanRecord> _buildSampleRecords() {
    final today = _today();
    DateTime ago(int d) => today.subtract(Duration(days: d));
    DateTime ahead(int d) => today.add(Duration(days: d));
    return [
      _LoanRecord(
        id: 'REQ-2026-011',
        category: _Category.peralatan,
        name: 'Kamera Sony A6400',
        status: 'Menunggu',
        scheduledAt: ahead(3),
        timeSlot: '08:00-10:00',
        location: 'Gedung Riset · Lantai 2',
        submittedAt: ago(0),
      ),
      _LoanRecord(
        id: 'REQ-2026-010',
        category: _Category.ruangan,
        name: 'Ruang Seminar R.302',
        status: 'Disetujui',
        scheduledAt: ahead(5),
        timeSlot: '09:00-12:00',
        location: 'Gedung Rektorat · Lantai 3',
        submittedAt: ago(2),
      ),
      _LoanRecord(
        id: 'REQ-2026-009',
        category: _Category.peralatan,
        name: 'Proyektor Epson EB-X06',
        status: 'Selesai',
        scheduledAt: ago(6),
        timeSlot: '13:00-15:00',
        location: 'Ruang Kelas A.204 · Gedung A',
        submittedAt: ago(9),
      ),
      _LoanRecord(
        id: 'REQ-2026-008',
        category: _Category.ruangan,
        name: 'Ruang Rapat A.204',
        status: 'Menunggu',
        scheduledAt: ahead(7),
        timeSlot: '10:00-12:00',
        location: 'Gedung A · Lantai 2',
        submittedAt: ago(4),
      ),
      _LoanRecord(
        id: 'REQ-2026-007',
        category: _Category.peralatan,
        name: 'Tripod Kamera',
        status: 'Disetujui',
        scheduledAt: ahead(1),
        timeSlot: '08:00-11:00',
        location: 'Gedung Riset · Lantai 2',
        submittedAt: ago(12),
      ),
      _LoanRecord(
        id: 'REQ-2026-006',
        category: _Category.ruangan,
        name: 'Aula Utama',
        status: 'Selesai',
        scheduledAt: ago(30),
        timeSlot: '08:00-16:00',
        location: 'Gedung Serbaguna · Lantai 1',
        submittedAt: ago(40),
      ),
    ]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  // ------------------------------------------------------------- helpers

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  /// Active submission-date range, or null when not filtering by date.
  DateTimeRange? get _activeRange {
    final today = _today();
    switch (_period) {
      case _Period.all:
        return null;
      case _Period.week:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _Period.month:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case _Period.custom:
        return _customRange;
    }
  }

  String? get _rangeLabel {
    final r = _activeRange;
    if (r == null) return null;
    if (_period == _Period.custom) {
      return '${_fmt(r.start)} – ${_fmt(r.end)}';
    }
    return _period.label;
  }

  int get _activeFilterCount =>
      (_category != null ? 1 : 0) + (_activeRange != null ? 1 : 0);

  bool get _hasAnyFilter =>
      _activeFilterCount > 0 ||
      _selectedStatus != 'Semua' ||
      _query.trim().isNotEmpty;

  List<_LoanRecord> _applyFilters() {
    final query = _query.trim().toLowerCase();
    final range = _activeRange;
    return _records.where((r) {
      if (_selectedStatus != 'Semua' && r.status != _selectedStatus) {
        return false;
      }
      if (_category != null && r.category != _category) return false;
      if (range != null &&
          (r.submittedAt.isBefore(range.start) ||
              r.submittedAt.isAfter(range.end))) {
        return false;
      }
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query) ||
          r.id.toLowerCase().contains(query) ||
          r.status.toLowerCase().contains(query) ||
          r.category.label.toLowerCase().contains(query) ||
          r.location.toLowerCase().contains(query);
    }).toList();
  }

  int _pageCountFor(int total) =>
      (total / _itemsPerPage).ceil().clamp(1, 999).toInt();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- actions

  void _updateStatus(String status) => setState(() {
        _selectedStatus = status;
        _page = 1;
      });

  void _updateQuery(String query) => setState(() {
        _query = query;
        _page = 1;
      });

  void _resetAll() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedStatus = 'Semua';
      _category = null;
      _period = _Period.all;
      _customRange = null;
      _page = 1;
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<DateTimeRange?> _pickRange(DateTimeRange? initial) {
    final today = _today();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      initialDateRange: initial,
      helpText: 'Pilih rentang tanggal pengajuan',
      saveText: 'Terapkan',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _teal),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    var draftCategory = _category;
    var draftPeriod = _period;
    var draftRange = _customRange;

    final applied = await showModalBottomSheet<bool>(
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
                          'Filter pengajuan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheet(() {
                          draftCategory = null;
                          draftPeriod = _Period.all;
                          draftRange = null;
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
                      chip(
                        label: 'Semua',
                        selected: draftCategory == null,
                        onTap: () => setSheet(() => draftCategory = null),
                      ),
                      for (final c in _Category.values)
                        chip(
                          label: c.label,
                          icon: c.icon,
                          selected: draftCategory == c,
                          onTap: () => setSheet(() => draftCategory = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  sectionTitle('Waktu pengajuan'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in _Period.values)
                        chip(
                          label: p == _Period.custom && draftRange != null
                              ? '${_fmt(draftRange!.start)} – '
                                  '${_fmt(draftRange!.end)}'
                              : p.label,
                          icon: p == _Period.custom
                              ? Icons.date_range_outlined
                              : null,
                          selected: draftPeriod == p,
                          onTap: () async {
                            if (p == _Period.custom) {
                              final picked = await _pickRange(draftRange);
                              if (picked == null) return;
                              setSheet(() {
                                draftRange = picked;
                                draftPeriod = _Period.custom;
                              });
                            } else {
                              setSheet(() => draftPeriod = p);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Terapkan filter',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (applied != true || !mounted) return;
    setState(() {
      _category = draftCategory;
      _period = draftPeriod;
      _customRange = draftRange;
      _page = 1;
    });
  }

  Future<void> _confirmCancellation(_LoanRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 36),
        title: const Text('Batalkan pengajuan?'),
        content: Text(
          'Peminjaman ${record.name} akan dibatalkan dan tidak dapat '
          'dikembalikan.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => record.status = 'Dibatalkan');
    _toast('Pengajuan ${record.id} dibatalkan.');
  }

  String _letterText(_LoanRecord r) => 'SURAT IZIN PEMINJAMAN\n'
      'LAYANAN FASILITAS KAMPUS\n\n'
      'Nomor: ${r.id}/SPARA/${r.submittedAt.year}\n\n'
      'Dengan ini menerangkan bahwa permohonan peminjaman fasilitas '
      'berikut telah disetujui:\n\n'
      'Fasilitas : ${r.name}\n'
      'Jadwal    : ${_fmt(r.scheduledAt)} · ${r.timeSlot}\n'
      'Lokasi    : ${r.location}\n\n'
      'Petugas Layanan\nSPARA Mobile';

  Future<void> _showLetterPreview(_LoanRecord record) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        backgroundColor: const Color(0xFFF5F7F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: _teal),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Preview Surat Izin',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5EAE7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.account_balance,
                                color: _teal, size: 32),
                            SizedBox(height: 6),
                            Text(
                              'SURAT IZIN PEMINJAMAN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'LAYANAN FASILITAS KAMPUS',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 28),
                      Text(
                        'Nomor: ${record.id}/SPARA/${record.submittedAt.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Dengan ini menerangkan bahwa permohonan peminjaman '
                        'fasilitas berikut telah disetujui:',
                        style: TextStyle(fontSize: 12.5, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      _previewLine('Fasilitas', record.name),
                      _previewLine('Jadwal',
                          '${_fmt(record.scheduledAt)} · ${record.timeSlot}'),
                      _previewLine('Lokasi', record.location),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Petugas Layanan\nSPARA Mobile',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _letterText(record)),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    if (!mounted) return;
                    _toast('Isi surat disalin ke papan klip.');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Salin isi surat'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilters();
    final pageCount = _pageCountFor(filtered.length);
    final page = _page.clamp(1, pageCount).toInt();
    final visible =
        filtered.skip((page - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SPARA MOBILE',
              style: TextStyle(
                color: _teal,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Riwayat Peminjaman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusFilters(),
          _buildActiveFilterChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pengajuan terbaru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  '${filtered.length} pengajuan',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildRecordCard(visible[index]),
                  ),
          ),
          _buildPagination(page, pageCount),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final count = _activeFilterCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _updateQuery,
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
                          _updateQuery('');
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
                key: const ValueKey('open-filter'),
                borderRadius: BorderRadius.circular(14),
                onTap: _openFilterSheet,
                child: Tooltip(
                  message: 'Filter kategori & waktu',
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

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final selected = filter == _selectedStatus;
          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) => _updateStatus(filter),
            selectedColor: _teal,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    final rangeLabel = _rangeLabel;
    if (_category == null && rangeLabel == null) {
      return const SizedBox(height: 0);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (_category != null)
              InputChip(
                avatar: Icon(_category!.icon, size: 16, color: _teal),
                label: Text(_category!.label),
                onDeleted: () => setState(() {
                  _category = null;
                  _page = 1;
                }),
                deleteButtonTooltipMessage: 'Hapus filter kategori',
                backgroundColor: const Color(0xFFE3F1EE),
                side: BorderSide.none,
                labelStyle: const TextStyle(fontSize: 12, color: _teal),
              ),
            if (rangeLabel != null)
              InputChip(
                avatar: const Icon(Icons.event, size: 16, color: _teal),
                label: Text(rangeLabel),
                onPressed: _openFilterSheet,
                onDeleted: () => setState(() {
                  _period = _Period.all;
                  _customRange = null;
                  _page = 1;
                }),
                deleteButtonTooltipMessage: 'Hapus filter waktu',
                backgroundColor: const Color(0xFFE3F1EE),
                side: BorderSide.none,
                labelStyle: const TextStyle(fontSize: 12, color: _teal),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(_LoanRecord record) {
    final statusColor = _statusColor(record.status);
    final canCancel = record.status == 'Menunggu';
    final hasLetter = record.status == 'Disetujui' || record.status == 'Selesai';
    return Container(
      key: ValueKey('loan-record-${record.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(record.category.icon, size: 14, color: _teal),
              const SizedBox(width: 4),
              Text(
                record.category.code,
                style: const TextStyle(
                  color: _teal,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            record.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          _buildProgressCard(record),
          const SizedBox(height: 10),
          _infoRow(Icons.calendar_month_outlined,
              '${_fmt(record.scheduledAt)} · ${record.timeSlot}'),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, record.location),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${record.id}\nDiajukan ${_fmt(record.submittedAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey, height: 1.4),
                ),
              ),
              if (canCancel)
                OutlinedButton.icon(
                  key: ValueKey('cancel-${record.id}'),
                  onPressed: () => _confirmCancellation(record),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Batalkan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD34E4E),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    side: const BorderSide(color: Color(0xFFD34E4E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (hasLetter)
                FilledButton.icon(
                  key: ValueKey('letter-${record.id}'),
                  onPressed: () => _showLetterPreview(record),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('Lihat surat izin'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _teal),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(_LoanRecord record) {
    if (record.status == 'Dibatalkan') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF5D8D5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFD34E4E)),
            SizedBox(width: 6),
            Text(
              'Pengajuan dibatalkan',
              style: TextStyle(fontSize: 12, color: Color(0xFFD34E4E)),
            ),
          ],
        ),
      );
    }

    final completedSteps = switch (record.status) {
      'Menunggu' => 1,
      'Disetujui' => 3,
      'Selesai' => 3,
      _ => 0,
    };
    final steps = [
      'Pengajuan diterima',
      record.status == 'Menunggu'
          ? 'Menunggu persetujuan Admin SBUM'
          : 'Disetujui Admin SBUM',
      'Surat izin diterbitkan',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EFEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Proses persetujuan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$completedSteps/3',
                style: const TextStyle(
                  color: _teal,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(steps.length, (index) {
            final done = index < completedSteps;
            final active =
                index == completedSteps && record.status == 'Menunggu';
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    done
                        ? Icons.check_circle
                        : active
                            ? Icons.schedule
                            : Icons.radio_button_unchecked,
                    size: 14,
                    color: done
                        ? _teal
                        : active
                            ? const Color(0xFFDBA629)
                            : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 11.5,
                        color:
                            done || active ? AppColors.textDark : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            const Text(
              'Pengajuan tidak ditemukan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ubah kata kunci atau sesuaikan filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            if (_hasAnyFilter) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const ValueKey('reset-filters'),
                onPressed: _resetAll,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset semua filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _teal,
                  side: const BorderSide(color: _teal),
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

  Widget _buildPagination(int page, int pageCount) {
    final canPrev = page > 1;
    final canNext = page < pageCount;
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Sebelumnya',
                onPressed: canPrev ? () => setState(() => _page = page - 1) : null,
                icon: const Icon(Icons.chevron_left),
                color: _teal,
                disabledColor: Colors.grey.shade400,
              ),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(pageCount, (index) {
                      final p = index + 1;
                      final selected = p == page;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: TextButton(
                            key: ValueKey('history-page-$p'),
                            onPressed: () => setState(() => _page = p),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  selected ? _teal : const Color(0xFFF1F4F2),
                              foregroundColor:
                                  selected ? Colors.white : AppColors.textDark,
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              '$p',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Berikutnya',
                onPressed: canNext ? () => setState(() => _page = page + 1) : null,
                icon: const Icon(Icons.chevron_right),
                color: _teal,
                disabledColor: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Menunggu' => const Color(0xFFC98F0A),
      'Disetujui' => const Color(0xFF198B68),
      'Selesai' => const Color(0xFF5E6B75),
      'Dibatalkan' => const Color(0xFFD34E4E),
      _ => AppColors.textGrey,
    };
  }
}

class _LoanRecord {
  _LoanRecord({
    required this.id,
    required this.category,
    required this.name,
    required this.status,
    required this.scheduledAt,
    required this.timeSlot,
    required this.location,
    required this.submittedAt,
  });

  final String id;
  final _Category category;
  final String name;
  String status;
  final DateTime scheduledAt;
  final String timeSlot;
  final String location;
  final DateTime submittedAt;
}