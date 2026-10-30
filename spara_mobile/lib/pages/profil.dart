import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import '../services/spara_api.dart';
import '../theme/app_colors.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _pageBackground = Color(0xFFF4F7F6);

  AppUser? _user = Session.instance.user;
  String? _loadError;

  String get _name => _user?.name ?? 'Pengguna SPARA';
  String get _studentId => _user?.idNumber ?? '-';
  String get _studyProgram => _user?.roleLabel ?? '-';
  String get _department => 'SPARA · Politeknik Negeri Batam';
  String get _phone {
    final value = _user?.phoneNumber.trim() ?? '';
    return value.isEmpty ? '-' : value;
  }

  String get _email {
    final value = _user?.email.trim() ?? '';
    return value.isEmpty ? '-' : value;
  }

  String get _initials => _user?.initials ?? 'SP';

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    if (!Session.instance.isLoggedIn) return;
    try {
      final user = await SparaApi.instance.me();
      await Session.instance.updateUser(user);
      if (!mounted) return;
      setState(() {
        _user = user;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        await _logout();
        return;
      }
      setState(() => _loadError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Gagal memuat data profil.');
    }
  }

  Future<void> _logout() async {
    await SparaApi.instance.logout();
    await Session.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _changeContact({required bool changePhone}) async {
    final formKey = GlobalKey<FormState>();
    var enteredValue = '';
    var verificationMethod = 'WhatsApp';

    final newValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              _DialogIcon(
                icon: changePhone ? Icons.call_outlined : Icons.mail_outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  changePhone ? 'Ganti Nomor Telepon' : 'Ganti Email',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    changePhone
                        ? 'Masukkan nomor baru untuk akun Anda.'
                        : 'Masukkan alamat email baru untuk akun Anda.',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _formField(
                    label: changePhone ? 'Nomor Telepon Baru' : 'Email Baru',
                    hint: changePhone ? '+62 812-3456-7890' : 'nama@email.com',
                    prefixIcon: changePhone
                        ? Icons.phone_outlined
                        : Icons.alternate_email,
                    onChanged: (value) => enteredValue = value.trim(),
                    keyboardType: changePhone
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Isi data terlebih dahulu!';
                      }
                      if (!changePhone &&
                          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())) {
                        return 'Masukkan alamat email yang valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    changePhone ? 'Pilih Metode Verifikasi' : 'Email Saat Ini',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (changePhone) ...[
                    const SizedBox(height: 10),
                    _verificationOption(
                      title: 'WhatsApp',
                      subtitle: 'Kirim kode verifikasi ke nomor baru',
                      icon: Icons.chat_bubble_outline,
                      selected: verificationMethod == 'WhatsApp',
                      onTap: () =>
                          setDialogState(() => verificationMethod = 'WhatsApp'),
                    ),
                    const SizedBox(height: 8),
                    _verificationOption(
                      title: 'SMS',
                      subtitle: 'Kirim kode verifikasi melalui SMS',
                      icon: Icons.sms_outlined,
                      selected: verificationMethod == 'SMS',
                      onTap: () =>
                          setDialogState(() => verificationMethod = 'SMS'),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      _email,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const _PrototypeNotice(
                    text:
                        'Pratinjau frontend: kode verifikasi belum dikirim oleh server.',
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: _dialogOutlinedStyle,
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, enteredValue);
                }
              },
              style: _dialogFilledStyle,
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      ),
    );

    if (newValue == null || !mounted) return;
    final verifiedInPreview = await _verifyCode(
      destination: newValue,
      channel: changePhone ? verificationMethod : 'email',
    );
    if (!verifiedInPreview || !mounted) return;

    if (!changePhone) {
      try {
        final updated = await SparaApi.instance.updateEmail(newValue);
        await Session.instance.updateUser(updated);
        if (!mounted) return;
        setState(() => _user = updated);
        _showMessage(
          'Email berhasil diperbarui.',
          icon: Icons.check_circle_outline,
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        _showMessage(e.message, icon: Icons.error_outline);
      } catch (_) {
        if (!mounted) return;
        _showMessage(
          'Gagal memperbarui email.',
          icon: Icons.error_outline,
        );
      }
      return;
    }

    try {
      final updated = await SparaApi.instance.updatePhone(newValue);
      await Session.instance.updateUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      _showMessage(
        'Nomor telepon berhasil diperbarui.',
        icon: Icons.check_circle_outline,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, icon: Icons.error_outline);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Gagal memperbarui nomor telepon.',
        icon: Icons.error_outline,
      );
    }
  }

  Future<bool> _verifyCode({
    required String destination,
    required String channel,
  }) async {
    final formKey = GlobalKey<FormState>();
    final verified = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            _DialogIcon(
              icon: channel == 'email'
                  ? Icons.mail_outline
                  : Icons.verified_user_outlined,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Verifikasi Kode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan kode 6 digit untuk $destination.',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                  color: AppColors.textDark,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '••••••',
                  counterText: '',
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
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Masukkan kode 6 digit.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const _PrototypeNotice(
                text:
                    'Verifikasi kode belum tersedia di server. Kode apa pun '
                    'akan dilanjutkan dan perubahan langsung disimpan.',
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: _dialogOutlinedStyle,
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            style: _dialogFilledStyle,
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
    return verified ?? false;
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    var currentPassword = '';
    var newPassword = '';
    var confirmPassword = '';
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    final updatedPassword = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget eye(bool obscured, VoidCallback toggle) => IconButton(
                tooltip: obscured ? 'Tampilkan' : 'Sembunyikan',
                onPressed: () => setDialogState(toggle),
                icon: Icon(
                  obscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              );

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Row(
              children: [
                _DialogIcon(icon: Icons.key_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ganti Kata Sandi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _formField(
                      label: 'Kata Sandi Saat Ini',
                      prefixIcon: Icons.lock_outline,
                      obscureText: obscureCurrent,
                      onChanged: (value) => currentPassword = value,
                      suffix:
                          eye(obscureCurrent, () => obscureCurrent = !obscureCurrent),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Isi data terlebih dahulu!';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _formField(
                      label: 'Kata Sandi Baru',
                      prefixIcon: Icons.lock_reset_outlined,
                      obscureText: obscureNew,
                      onChanged: (value) => newPassword = value,
                      suffix: eye(obscureNew, () => obscureNew = !obscureNew),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Isi data terlebih dahulu!';
                        }
                        if (value.length < 8) {
                          return 'Gunakan minimal 8 karakter.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _formField(
                      label: 'Konfirmasi Kata Sandi',
                      prefixIcon: Icons.verified_user_outlined,
                      obscureText: obscureConfirm,
                      onChanged: (value) => confirmPassword = value,
                      suffix: eye(
                          obscureConfirm, () => obscureConfirm = !obscureConfirm),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Isi data terlebih dahulu!';
                        }
                        if (confirmPassword != newPassword) {
                          return 'Konfirmasi kata sandi tidak sama.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    const _PrototypeNotice(
                      text:
                          'Kata sandi saat ini akan diperiksa oleh server '
                          'sebelum perubahan disimpan.',
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: _dialogOutlinedStyle,
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                style: _dialogFilledStyle,
                child: const Text('Ganti'),
              ),
            ],
          );
        },
      ),
    );

    if (updatedPassword != true || !mounted) return;

    try {
      await SparaApi.instance.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmation: confirmPassword,
      );
      if (!mounted) return;
      _showMessage(
        'Kata sandi berhasil diperbarui.',
        icon: Icons.check_circle_outline,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, icon: Icons.error_outline);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Gagal memperbarui kata sandi.',
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, color: AppColors.error, size: 26),
        ),
        title: const Text(
          'Keluar dari akun?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Anda perlu masuk kembali untuk mengakses layanan SPARA Mobile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: _dialogOutlinedStyle,
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: _dialogFilledStyle.copyWith(
              backgroundColor: const WidgetStatePropertyAll(AppColors.error),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;
    await _logout();
  }

  Future<void> _copyStudentId() async {
    await Clipboard.setData(ClipboardData(text: _studentId));
    if (!mounted) return;
    _showMessage('NIM disalin ke papan klip.', icon: Icons.copy_all_outlined);
  }

  void _showMessage(String message, {IconData icon = Icons.info_outline}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  ButtonStyle get _dialogOutlinedStyle => OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        foregroundColor: AppColors.textDark,
        side: const BorderSide(color: Color(0xFFD8E2E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  ButtonStyle get _dialogFilledStyle => FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  if (_loadError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _loadError!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Muat ulang',
                            onPressed: _refreshProfile,
                            icon: const Icon(Icons.refresh, size: 18),
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      children: [
                        _SectionCard(
                          title: 'Informasi Kontak',
                          children: [
                            _ProfileTile(
                              icon: Icons.call_outlined,
                              label: 'Nomor Telepon',
                              value: _phone,
                              onEdit: () => _changeContact(changePhone: true),
                              editKey: const Key('profile-edit-phone'),
                            ),
                            const _TileDivider(),
                            _ProfileTile(
                              icon: Icons.mail_outline,
                              label: 'Alamat Email',
                              value: _email,
                              onEdit: () => _changeContact(changePhone: false),
                              editKey: const Key('profile-edit-email'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Keamanan',
                          children: [
                            _ProfileTile(
                              icon: Icons.lock_outline,
                              label: 'Kata Sandi',
                              value: '••••••••',
                              onEdit: _changePassword,
                              editKey: const Key('profile-edit-password'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildLogoutBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkTeal, AppColors.primary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'lib/assets/images/logo_spara/logo_gelap.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.account_balance,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SPARA MOBILE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Profil Akun',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              GestureDetector(
                key: const Key('profile-avatar'),
                onTap: () => _showMessage(
                  'Ubah foto profil belum tersedia di pratinjau.',
                  icon: Icons.photo_camera_outlined,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFDDF3EF),
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _studyProgram,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
              Text(
                _department,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  key: const Key('profile-copy-nim'),
                  borderRadius: BorderRadius.circular(20),
                  onTap: _copyStudentId,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'NIM: $_studentId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.copy_outlined,
                          color: Colors.white70,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutBar() {
    return Container(
      color: _pageBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              key: const Key('profile-logout'),
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Keluar dari Akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB3261E),
                backgroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: const Color(0xFFB3261E).withValues(alpha: 0.25),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField({
    TextEditingController? controller,
    required String label,
    String hint = '',
    IconData? prefixIcon,
    required String? Function(String?) validator,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF6F9F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _verificationOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FAF8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accentTeal : const Color(0xFFE1E8E8),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : Colors.grey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 70, endIndent: 16);
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
    required this.editKey,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;
  final Key editKey;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: editKey,
      onTap: onEdit,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined,
                      color: AppColors.accentTeal, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Ubah',
                    style: TextStyle(
                      color: AppColors.accentTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
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

class _DialogIcon extends StatelessWidget {
  const _DialogIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFEAF6F4),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _PrototypeNotice extends StatelessWidget {
  const _PrototypeNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 16, color: Color(0xFF4B5BD6)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}