import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/facility_model.dart';
import '../services/api_client.dart';
import '../services/spara_api.dart';
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
    'Ditolak',
    'Selesai',
    'Dibatalkan',
  ];
  static const _teal = Color(0xFF08766C);
  static const _pageBackground = Color(0xFFF5F4EE);
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const _longMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const _romanMonths = [
    'I', 'II', 'III', 'IV', 'V', 'VI',
    'VII', 'VIII', 'IX', 'X', 'XI', 'XII',
  ];

  static const _logoAsset = 'lib/assets/images/logo_polibatam.png';

  final _searchController = TextEditingController();
  String _query = '';
  String _selectedStatus = 'Semua';
  _Category? _category;
  _Period _period = _Period.all;
  DateTimeRange? _customRange;
  int _page = 1;

  pw.MemoryImage? _pdfLogo;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<_LoanRecord> _records = const [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  static DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return fallback ?? _today();
  }

  static String _shortTime(dynamic value) {
    final raw = '${value ?? ''}';
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw.isEmpty ? '00:00' : raw;
  }

  static String _statusLabel(String? status) {
    switch (status) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return 'Menunggu';
    }
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        SparaApi.instance.getRiwayat(),
        SparaApi.instance.getFacilities(),
      ]);
      final rawRecords = results[0] as List<Map<String, dynamic>>;
      final facilities = results[1] as List<Facility>;
      final today = _today();

      final byName = <String, Facility>{
        for (final facility in facilities) facility.name.toLowerCase(): facility,
      };

      final records = rawRecords.map((json) {
        final name = '${json['alat'] ?? json['ruangan'] ?? '-'}';
        final isTool = json['alat'] != null && '${json['alat']}'.isNotEmpty;
        final facility = byName[name.toLowerCase()];
        final scheduledAt = _parseDate(
          json['tanggal_mulai'] ?? json['hari_tanggal'],
        );
        final submittedAt = _parseDate(json['dibuat_pada'], fallback: today);
        final dbId = int.tryParse('${json['id_peminjaman']}') ?? 0;
        final location = facility != null
            ? '${facility.building} ? ${facility.floor}'
            : 'PIC: ${json['pic'] ?? '-'}';

        return _LoanRecord(
          id: 'REQ-${scheduledAt.year}-${dbId.toString().padLeft(3, '0')}',
          dbId: dbId,
          category: isTool ? _Category.peralatan : _Category.ruangan,
          name: name,
          status: _statusLabel(json['status_persetujuan'] as String?),
          scheduledAt: scheduledAt,
          timeSlot:
              '${_shortTime(json['jam_mulai'])}-${_shortTime(json['jam_selesai'])}',
          location: location,
          submittedAt: submittedAt,
          applicant: '${json['peminjam'] ?? '-'}',
          purpose: '${json['name_kegiatan'] ?? '-'}',
        );
      }).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Gagal memuat riwayat peminjaman.';
        _isLoading = false;
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  String _fmtLong(DateTime d) => '${d.day} ${_longMonths[d.month - 1]} ${d.year}';

  String _letterNumber(_LoanRecord r) {
    final seq = r.id.split('-').last;
    return '$seq/SPARA-UN/${_romanMonths[r.submittedAt.month - 1]}/'
        '${r.submittedAt.year}';
  }

  String _letterTime(String slot) => slot.replaceAll(':', '.');

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

    final id = record.dbId;
    if (id != null) {
      try {
        await SparaApi.instance.cancelPeminjaman(id);
      } on ApiException catch (e) {
        if (!mounted) return;
        _toast(e.message);
        return;
      } catch (_) {
        if (!mounted) return;
        _toast('Gagal membatalkan pengajuan.');
        return;
      }
    }

    if (!mounted) return;
    setState(() => record.status = 'Dibatalkan');
    _toast('Pengajuan ${record.id} dibatalkan.');
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    if (_pdfLogo != null) return _pdfLogo;
    try {
      final data = await rootBundle.load(_logoAsset);
      _pdfLogo = pw.MemoryImage(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      return _pdfLogo;
    } catch (e) {
      debugPrint('Gagal memuat logo "$_logoAsset": $e');
      return null;
    }
  }

  Future<Uint8List> _buildLetterPdf(
    _LoanRecord r,
    PdfPageFormat format,
    pw.MemoryImage? logo,
  ) async {
    final navy = PdfColor.fromHex('#1F3A5F');
    final ink = PdfColor.fromHex('#1E2B2B');
    final muted = PdfColor.fromHex('#7A8683');
    final boxFill = PdfColor.fromHex('#F3F6F5');
    final boxBorder = PdfColor.fromHex('#D5DCD9');
    final teal = PdfColor.fromHex('#08766C');

    pw.Widget logoWidget() {
      if (logo != null) {
        return pw.SizedBox(
          width: 64,
          height: 48,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        );
      }

      return pw.SizedBox(
        width: 64,
        height: 48,
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              width: 30,
              height: 22,
              decoration: pw.BoxDecoration(
                color: teal,
                borderRadius: pw.BorderRadius.circular(11),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text('polibatam',
                style: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold, color: navy)),
            pw.Text('University',
                style: pw.TextStyle(fontSize: 5.5, color: navy)),
          ],
        ),
      );
    }

    pw.Widget infoRow(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 62,
              child: pw.Text(label,
                  style: pw.TextStyle(fontSize: 10, color: ink)),
            ),
            pw.Text(': ', style: pw.TextStyle(fontSize: 10, color: ink)),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: ink,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final doc = pw.Document(
      title: 'Surat Izin Peminjaman ${r.id}',
      author: 'SPARA Mobile',
    );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.fromLTRB(52, 48, 52, 48),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                logoWidget(),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'POLITEKNIK NEGERI BATAM',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'SUB BAGIAN UMUM DAN KEPEGAWAIAN',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Jalan Ahmad Yani, Teluk Tering, Kecamatan Batam Kota, '
                        'Kota Batam, Kepulauan Riau 29461',
                        style: pw.TextStyle(fontSize: 7, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 2.5, color: PdfColors.black),
            pw.SizedBox(height: 20),

            pw.Center(
              child: pw.Text(
                'SURAT IZIN PEMINJAMAN',
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  color: ink,
                ),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Nomor: ${_letterNumber(r)}',
                style: pw.TextStyle(fontSize: 10, color: ink),
              ),
            ),
            pw.SizedBox(height: 16),

            pw.Text(
              'Subbagian umum Politeknik Negeri Batam menerangkan bahwa '
              'permohonan berikut telah disetujui:',
              style: pw.TextStyle(fontSize: 10, color: ink, lineSpacing: 2),
            ),
            pw.SizedBox(height: 10),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 6),
              decoration: pw.BoxDecoration(
                color: boxFill,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: boxBorder, width: 0.8),
              ),
              child: pw.Column(
                children: [
                  infoRow('Pemohon', r.applicant),
                  infoRow('Fasilitas', r.name, bold: true),
                  infoRow(
                    'Waktu',
                    '${_fmtLong(r.scheduledAt)} · ${_letterTime(r.timeSlot)}',
                  ),
                  infoRow('Keperluan', r.purpose),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            pw.Text(
              'Izin berlaku sesuai jadwal. Pemohon wajib menjaga kebersihan, '
              'keamanan, dan mengembalikan fasilitas dalam kondisi semula.',
              style: pw.TextStyle(fontSize: 10, color: ink, lineSpacing: 2),
            ),

            pw.Spacer(),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Batam, ${_fmtLong(r.submittedAt)}',
                      style: pw.TextStyle(fontSize: 10, color: ink),
                    ),
                    pw.SizedBox(height: 56),
                    pw.Text(
                      'Sugi Hapni Delima, SE, M.Sc.',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                        color: ink,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Koordinator Subbagian Umum Polibatam',
                      style: pw.TextStyle(fontSize: 8, color: ink),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 60),
          ],
        ),
      ),
    );

    return doc.save();
  }

  Future<void> _downloadLetter(_LoanRecord record) async {
    try {
      final logo = await _loadLogo();
      final bytes = await _buildLetterPdf(
        record,
        PdfPageFormat.a4,
        logo,
      );
      final saved = await Printing.sharePdf(
        bytes: bytes,
        filename: 'Surat-Izin-${record.id}.pdf',
      );
      if (!mounted) return;
      _toast(
        saved
            ? 'PDF berhasil diunduh.'
            : 'Gagal mengunduh PDF. Silakan coba lagi.',
      );
    } catch (_) {
      if (!mounted) return;
      _toast('Gagal membuat PDF surat izin. Silakan coba lagi.');
    }
  }

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
                child: _buildLetterPaper(record),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _downloadLetter(record),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download PDF'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterPaper(_LoanRecord record) {
    const navy = Color(0xFF1F3A5F);
    const ink = Color(0xFF1E2B2B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5EAE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                height: 38,
                child: Image.asset(
                  _logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.account_balance,
                    color: _teal,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POLITEKNIK NEGERI BATAM',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    Text(
                      'SUB BAGIAN UMUM DAN KEPEGAWAIAN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    Text(
                      'Jalan Ahmad Yani, Teluk Tering, Kecamatan Batam Kota, '
                      'Kota Batam, Kepulauan Riau 29461',
                      style: TextStyle(fontSize: 6.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 2.5, color: Colors.black),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'SURAT IZIN PEMINJAMAN',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Nomor: ${_letterNumber(record)}',
              style: const TextStyle(fontSize: 10, color: ink),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Subbagian umum Politeknik Negeri Batam menerangkan bahwa '
            'permohonan berikut telah disetujui:',
            style: TextStyle(fontSize: 11, height: 1.45, color: ink),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD5DCD9)),
            ),
            child: Column(
              children: [
                _previewLine('Pemohon', record.applicant),
                _previewLine('Fasilitas', record.name, bold: true),
                _previewLine('Waktu',
                    '${_fmtLong(record.scheduledAt)} · ${_letterTime(record.timeSlot)}'),
                _previewLine('Kegiatan', record.purpose),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Izin berlaku sesuai jadwal. Pemohon wajib menjaga kebersihan, '
            'keamanan, dan mengembalikan fasilitas dalam kondisi semula.',
            style: TextStyle(fontSize: 11, height: 1.45, color: ink),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Batam, ${_fmtLong(record.submittedAt)}',
                  style: const TextStyle(fontSize: 10.5, color: ink),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Sugi Hapni Delima, SE, M.Sc.',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: ink,
                  ),
                ),
                const Text(
                  'Koordinator Subbagian Umum Polibatam',
                  style: TextStyle(fontSize: 8.5, color: ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
          const Text(': ', style: TextStyle(fontSize: 11)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 48,
                                color: AppColors.textGrey,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _loadError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _loadRecords,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : visible.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadRecords,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              itemCount: visible.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _buildRecordCard(visible[index]),
                            ),
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
              color: _teal,
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
                      color: Colors.white,
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                '${record.id}\nDiajukan ${_fmt(record.submittedAt)}',
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey, height: 1.4),
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
    if (record.status == 'Dibatalkan' || record.status == 'Ditolak') {
      final rejected = record.status == 'Ditolak';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF5D8D5)),
        ),
        child: Row(
          children: [
            Icon(
              rejected ? Icons.highlight_off : Icons.cancel_outlined,
              size: 16,
              color: const Color(0xFFD34E4E),
            ),
            const SizedBox(width: 6),
            Text(
              rejected ? 'Pengajuan ditolak' : 'Pengajuan dibatalkan',
              style: const TextStyle(fontSize: 12, color: Color(0xFFD34E4E)),
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
      'Ditolak' => const Color(0xFFD34E4E),
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
    required this.applicant,
    required this.purpose,
    this.dbId,
  });

  final String id;
  final int? dbId;
  final _Category category;
  final String name;
  String status;
  final DateTime scheduledAt;
  final String timeSlot;
  final String location;
  final DateTime submittedAt;
  final String applicant;
  final String purpose;
}