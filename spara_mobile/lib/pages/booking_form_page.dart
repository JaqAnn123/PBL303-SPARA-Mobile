import 'package:flutter/material.dart';

import '../models/facility_model.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../services/spara_api.dart';
import '../theme/app_colors.dart';

typedef _PjOption = ({String idNumber, String name});

/// Form pengajuan peminjaman (ruangan maupun peralatan).
///
/// Field mengikuti form web (`ModalPengajuanRuangan.jsx`): jenis kegiatan,
/// nama kegiatan, penanggung jawab, tanggal (bisa multi-hari), jam mulai,
/// jam selesai, dan keterangan. Setelah dikonfirmasi, pengajuan dikirim ke
/// `POST /peminjaman` lalu halaman ditutup dengan hasil `true`.
class BookingFormPage extends StatefulWidget {
  const BookingFormPage({super.key, required this.facility});

  final Facility facility;

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  static const Color _pageBackground = Color(0xFFF4F7F6);
  static const Color _green = Color(0xFF197B47);
  static const List<String> _jenisOptions = ['akademik', 'non-akademik'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _keteranganController = TextEditingController();

  String _jenisKegiatan = 'akademik';
  DateTime? _tanggal;
  DateTime? _tanggalSelesai;
  bool _multiHari = false;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  String? _pjId;
  String _pjName = '';
  List<_PjOption> _pjOptions = const [];
  bool _loadingPj = true;
  bool _submitting = false;
  String? _error;

  Facility get _facility => widget.facility;
  bool get _isRoom => _facility.type == 'Ruangan';

  @override
  void initState() {
    super.initState();
    final current = Session.instance.user;
    if (current != null) {
      _pjId = current.idNumber;
      _pjName = current.name;
    }
    _loadPenanggungJawab();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _two(int value) => value.toString().padLeft(2, '0');

  String _fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  String _fmtTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  int get _dayCount {
    final start = _tanggal;
    if (start == null) return 0;
    if (!_multiHari) return 1;
    final end = _tanggalSelesai;
    if (end == null) return 0;
    return end.difference(start).inDays + 1;
  }

  String get _dateLabel {
    final start = _tanggal;
    if (start == null) return '';
    if (!_multiHari || _tanggalSelesai == null) return _fmtDate(start);
    return '${_fmtDate(start)} s/d ${_fmtDate(_tanggalSelesai!)}';
  }

  // ── Data ────────────────────────────────────────────────────────────────

  Future<void> _loadPenanggungJawab() async {
    final options = <_PjOption>[];
    final current = Session.instance.user;
    if (current != null) {
      options.add((idNumber: current.idNumber, name: current.name));
    }

    try {
      final list = await SparaApi.instance.getPenanggungJawab();
      for (final item in list) {
        final id = '${item['id_number'] ?? ''}'.trim();
        final name = '${item['name'] ?? ''}'.trim();
        if (id.isEmpty) continue;
        if (options.any((o) => o.idNumber == id)) continue;
        options.add((idNumber: id, name: name.isEmpty ? id : name));
      }
    } catch (_) {
      // Daftar PJ gagal dimuat: tetap bisa memakai user yang sedang login.
    }

    if (!mounted) return;
    setState(() {
      _pjOptions = options;
      _loadingPj = false;
      if (_pjId == null && current != null) {
        _pjId = current.idNumber;
        _pjName = current.name;
      }
    });
  }

  // ── Pickers ─────────────────────────────────────────────────────────────

  Future<void> _pickTanggal({required bool isEnd}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = isEnd ? (_tanggal ?? today) : today;
    final initial = isEnd
        ? (_tanggalSelesai ?? firstDate)
        : (_tanggal ?? firstDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 90)),
    );
    if (picked == null) return;

    setState(() {
      if (isEnd) {
        _tanggalSelesai = picked;
      } else {
        _tanggal = picked;
        if (_tanggalSelesai != null && _tanggalSelesai!.isBefore(picked)) {
          _tanggalSelesai = picked;
        }
      }
      _error = null;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_jamMulai ?? const TimeOfDay(hour: 8, minute: 0))
          : (_jamSelesai ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _jamMulai = picked;
      } else {
        _jamSelesai = picked;
      }
      _error = null;
    });
  }

  Future<void> _pickPenanggungJawab() async {
    var query = '';

    final selected = await showModalBottomSheet<_PjOption>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          final filtered = _pjOptions.where((o) {
            final q = query.trim().toLowerCase();
            if (q.isEmpty) return true;
            return o.name.toLowerCase().contains(q) ||
                o.idNumber.toLowerCase().contains(q);
          }).toList();

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        'Pilih Penanggung Jawab',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        onChanged: (value) => setSheet(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau NIM/NIP...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF6F9F8),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _loadingPj
                          ? const Center(child: CircularProgressIndicator())
                          : filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada hasil ditemukan',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final option = filtered[index];
                                final active = option.idNumber == _pjId;
                                return ListTile(
                                  key: ValueKey('pj-option-${option.idNumber}'),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    option.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: active
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  subtitle: Text(
                                    option.idNumber,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  trailing: active
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: _green,
                                          size: 20,
                                        )
                                      : null,
                                  onTap: () =>
                                      Navigator.pop(sheetContext, option),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (selected == null) return;
    setState(() {
      _pjId = selected.idNumber;
      _pjName = selected.name;
      _error = null;
    });
  }

  // ── Submit ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState?.validate() ?? false;
    String? message;
    if (!formValid) {
      message = 'Lengkapi data wajib terlebih dahulu.';
    } else if (_tanggal == null) {
      message = 'Pilih tanggal peminjaman.';
    } else if (_multiHari && _tanggalSelesai == null) {
      message = 'Pilih tanggal selesai peminjaman.';
    } else if (_multiHari && _dayCount > 30) {
      message = 'Peminjaman maksimal 30 hari sekaligus.';
    } else if (_jamMulai == null || _jamSelesai == null) {
      message = 'Pilih jam mulai dan jam selesai.';
    } else if (_minutes(_jamSelesai!) <= _minutes(_jamMulai!)) {
      message = 'Jam selesai harus setelah jam mulai.';
    } else if (_pjId == null || _pjId!.isEmpty) {
      message = 'Pilih penanggung jawab.';
    } else if (_facility.dbId == null) {
      message = 'Data fasilitas tidak valid. Muat ulang halaman.';
    }

    if (message != null) {
      setState(() => _error = message);
      return;
    }

    setState(() => _error = null);

    final confirmed = await _showConfirmation();
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);

    try {
      await SparaApi.instance.createPeminjaman(
        nameKegiatan: _nameController.text.trim(),
        jenisKegiatan: _jenisKegiatan,
        tanggal: _tanggal!,
        tanggalSelesai: _multiHari ? _tanggalSelesai : null,
        jamMulai: _fmtTime(_jamMulai!),
        jamSelesai: _fmtTime(_jamSelesai!),
        idNumberPenanggungJawab: _pjId!,
        idRuangan: _isRoom ? _facility.dbId : null,
        idAlat: _isRoom ? null : _facility.dbId,
        keterangan: _keteranganController.text.trim().isEmpty
            ? null
            : _keteranganController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _submitting = false);
      await _showSuccess();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
      await _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      const message = 'Gagal mengirim pengajuan. Silakan coba lagi.';
      setState(() {
        _submitting = false;
        _error = message;
      });
      await _showError(message);
    }
  }

  Future<bool?> _showConfirmation() {
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Konfirmasi Pengajuan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin mengirim pengajuan ini?',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F9F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  row(_isRoom ? 'Ruangan' : 'Peralatan', _facility.name),
                  row('Kegiatan', _nameController.text.trim()),
                  row('Jenis', _jenisKegiatan),
                  row('Tanggal', _dateLabel),
                  row(
                    'Jam',
                    '${_fmtTime(_jamMulai!)} - ${_fmtTime(_jamSelesai!)}',
                  ),
                  row('PJ', _pjName),
                  if (_keteranganController.text.trim().isNotEmpty)
                    row('Keterangan', _keteranganController.text.trim()),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textGrey),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const ValueKey('booking-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Kirim Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccess() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F3EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: _green, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pengajuan berhasil diajukan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pengajuan Anda akan ditinjau oleh admin/PIC. Status dapat '
              'dilihat pada halaman Riwayat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textGrey,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const ValueKey('booking-success-back'),
                onPressed: () => Navigator.pop(dialogContext),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showError(String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pengajuan gagal',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textGrey,
            height: 1.45,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.darkTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        title: const Text(
          'Ajukan Peminjaman',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            _sectionTitle('Jadwal Peminjaman'),
            const SizedBox(height: 12),
            _fieldLabel('Tanggal', required: true),
            _pickerField(
              key: const ValueKey('booking-date'),
              icon: Icons.calendar_month_outlined,
              hint: 'Pilih tanggal',
              value: _tanggal == null ? null : _fmtDate(_tanggal!),
              onTap: () => _pickTanggal(isEnd: false),
            ),
            _buildMultiDayToggle(),
            if (_multiHari) ...[
              const SizedBox(height: 12),
              _fieldLabel('Tanggal Selesai', required: true),
              _pickerField(
                key: const ValueKey('booking-end-date'),
                icon: Icons.event_available_outlined,
                hint: 'Pilih tanggal selesai',
                value: _tanggalSelesai == null
                    ? null
                    : _fmtDate(_tanggalSelesai!),
                onTap: () => _pickTanggal(isEnd: true),
              ),
              if (_dayCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _dayCount > 30
                        ? 'Durasi $_dayCount hari · maksimal 30 hari'
                        : 'Durasi $_dayCount hari',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _dayCount > 30
                          ? AppColors.error
                          : AppColors.accentTeal,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Jam Mulai', required: true),
                      _pickerField(
                        key: const ValueKey('booking-start-time'),
                        icon: Icons.schedule,
                        hint: 'Mulai',
                        value: _jamMulai == null ? null : _fmtTime(_jamMulai!),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Jam Selesai', required: true),
                      _pickerField(
                        key: const ValueKey('booking-end-time'),
                        icon: Icons.schedule,
                        hint: 'Selesai',
                        value: _jamSelesai == null
                            ? null
                            : _fmtTime(_jamSelesai!),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _sectionTitle('Detail Pengajuan'),
            const SizedBox(height: 12),
            _fieldLabel('Jenis Kegiatan', required: true),
            DropdownButtonFormField<String>(
              key: const ValueKey('booking-jenis'),
              initialValue: _jenisKegiatan,
              decoration: _inputDecoration(null),
              items: [
                for (final option in _jenisOptions)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() {
                      _jenisKegiatan = value ?? 'akademik';
                    }),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Nama Kegiatan', required: true),
            TextFormField(
              key: const ValueKey('booking-name'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Contoh: Seminar Himpunan'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kegiatan wajib diisi.';
                }
                if (value.trim().length > 255) {
                  return 'Nama kegiatan maksimal 255 karakter.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _fieldLabel('Penanggung Jawab', required: true),
            _buildPjField(),
            const SizedBox(height: 14),
            _fieldLabel('Keterangan'),
            TextFormField(
              key: const ValueKey('booking-keterangan'),
              controller: _keteranganController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Tuliskan keterangan tambahan jika diperlukan...',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const ValueKey('booking-submit'),
              onPressed: _submitting ? null : _submit,
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
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim Pengajuan'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isRoom ? Icons.meeting_room_outlined : Icons.devices_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _facility.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_facility.id} · ${_facility.building}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiDayToggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Switch(
            key: const ValueKey('booking-multi-day'),
            value: _multiHari,
            activeThumbColor: _green,
            onChanged: _submitting
                ? null
                : (value) => setState(() {
                    _multiHari = value;
                    if (!value) _tanggalSelesai = null;
                    _error = null;
                  }),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Lebih dari 1 hari',
              style: TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPjField() {
    final hasValue = _pjId != null && _pjId!.isNotEmpty;
    return InkWell(
      key: const ValueKey('booking-pj'),
      onTap: _submitting ? null : _pickPenanggungJawab,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? AppColors.accentTeal : const Color(0xFFE1E8E8),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: 20,
              color: AppColors.darkTeal,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasValue ? _pjName : 'Pilih penanggung jawab',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                      color: hasValue ? AppColors.textDark : Colors.grey,
                    ),
                  ),
                  if (hasValue)
                    Text(
                      _pjId!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                ],
              ),
            ),
            _loadingPj
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.expand_more,
                    size: 20,
                    color: AppColors.textGrey,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accentTeal,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(const Color(0xFFE1E8E8)),
      enabledBorder: border(const Color(0xFFE1E8E8)),
      focusedBorder: border(AppColors.accentTeal, 1.5),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 1.5),
    );
  }

  Widget _pickerField({
    required Key key,
    required IconData icon,
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    final filled = value != null;
    return InkWell(
      key: key,
      onTap: _submitting ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled ? AppColors.accentTeal : const Color(0xFFE1E8E8),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.darkTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
                  color: filled ? AppColors.textDark : Colors.grey,
                ),
              ),
            ),
            const Icon(Icons.expand_more, size: 20, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
