import 'package:flutter/material.dart';

import '../models/facility_model.dart';
import '../theme/app_colors.dart';
import 'booking_form_page.dart';

/// Halaman detail fasilitas (ruangan/peralatan) yang dibuka dari pencarian.
///
/// Tombol "Ajukan Peminjaman" membuka form pengajuan pada halaman baru.
/// Bila pengajuan berhasil dikirim, halaman ini ikut ditutup dengan hasil
/// `true` agar dashboard dapat kembali ke tab utama.
class FacilityDetailPage extends StatefulWidget {
  const FacilityDetailPage({super.key, required this.facility});

  final Facility facility;

  @override
  State<FacilityDetailPage> createState() => _FacilityDetailPageState();
}

class _FacilityDetailPageState extends State<FacilityDetailPage> {
  static const Color _pageBackground = Color(0xFFF4F7F6);
  static const Color _green = Color(0xFF197B47);

  bool _openingForm = false;

  Facility get _facility => widget.facility;
  bool get _isRoom => _facility.type == 'Ruangan';
  bool get _isAvailable => _facility.status == 'Tersedia';

  Color get _statusColor {
    switch (_facility.status) {
      case 'Maintenance':
        return const Color(0xFFB26A00);
      case 'Dipinjam':
        return const Color(0xFFB3261E);
      default:
        return _green;
    }
  }

  Future<void> _openBookingForm() async {
    if (_openingForm) return;
    setState(() => _openingForm = true);

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BookingFormPage(facility: _facility)),
    );

    if (!mounted) return;
    setState(() => _openingForm = false);
    if (created == true) Navigator.of(context).pop(true);
  }

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
          'Detail Fasilitas',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _buildHero(),
          const SizedBox(height: 16),
          Text(
            _facility.name,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kode ${_facility.id}',
            style: const TextStyle(
              fontSize: 12.5,
              color: _green,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(),
          if ((_facility.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildDescriptionCard(),
          ],
          if (_isRoom && _facility.facilities.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildFacilitiesCard(),
          ],
          const SizedBox(height: 14),
          _buildNoteCard(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHero() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4F4A), Color(0xFF2C7A72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _isRoom ? Icons.meeting_room_outlined : Icons.devices_outlined,
              size: 64,
              color: Colors.white38,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: _statusColor),
                  const SizedBox(width: 6),
                  Text(
                    _facility.status,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          _infoRow(Icons.apartment_outlined, 'Gedung', _facility.building),
          if (_isRoom)
            _infoRow(Icons.layers_outlined, 'Lantai', _facility.floor),
          if (_isRoom)
            _infoRow(Icons.people_outline, 'Kapasitas', _facility.capacity),
          _infoRow(Icons.category_outlined, 'Kategori', _facility.type),
          _infoRow(
            Icons.badge_outlined,
            'Penanggung Jawab',
            (_facility.pic ?? '').trim().isEmpty ? '-' : _facility.pic!,
          ),
          _infoRow(
            Icons.verified_outlined,
            'Status',
            _facility.status,
            valueColor: _statusColor,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                  style: TextStyle(
                    color: valueColor ?? AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Deskripsi'),
          const SizedBox(height: 8),
          Text(
            _facility.description!.trim(),
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Fasilitas Ruangan'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in _facility.facilities)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F3EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: _green,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.darkTeal),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pengajuan peminjaman akan dikirim ke admin/PIC untuk ditinjau '
              'sebelum disetujui.',
              style: TextStyle(
                color: AppColors.darkTeal,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: const ValueKey('facility-detail-borrow'),
                onPressed: _isAvailable && !_openingForm
                    ? _openBookingForm
                    : null,
                icon: const Icon(Icons.assignment_outlined, size: 19),
                label: Text(
                  _isAvailable ? 'Ajukan Peminjaman' : 'Tidak Tersedia',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: const Color(0xFFB8C4C1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (!_isAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'Fasilitas berstatus ${_facility.status} sehingga belum dapat '
                'diajukan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
