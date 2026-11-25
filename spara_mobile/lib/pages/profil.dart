import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/notification_center.dart';
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
  bool _isUploadingPhoto = false;

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

  String? get _photoUrl =>
      ApiClient.instance.mediaUrl(_user?.profilePicture);

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
    NotificationCenter.instance.stop();
    await Session.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _changePhoto() async {
    if (_isUploadingPhoto) return;

    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Tidak dapat membuka galeri.',
        icon: Icons.error_outline,
      );
      return;
    }
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      if (!mounted) return;
      _showMessage(
        'Ukuran foto maksimal 2 MB.',
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final updated = await SparaApi.instance.uploadProfilePhoto(
        bytes: bytes,
        filename: file.name.isEmpty ? 'profile.jpg' : file.name,
      );
      await Session.instance.updateUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      _showMessage(
        'Foto profil berhasil diperbarui.',
        icon: Icons.check_circle_outline,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, icon: Icons.error_outline);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Gagal mengunggah foto profil.', icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
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
                      suffix: eye(
                        obscureCurrent,
                        () => obscureCurrent = !obscureCurrent,
                      ),
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
                        obscureConfirm,
                        () => obscureConfirm = !obscureConfirm,
                      ),
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
      _showMessage('Gagal memperbarui kata sandi.', icon: Icons.error_outline);
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
                            ),
                            const _TileDivider(),
                            _ProfileTile(
                              icon: Icons.mail_outline,
                              label: 'Alamat Email',
                              value: _email,
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
                onTap: _changePhoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: _buildAvatarImage(),
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
                        child: _isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.photo_library_outlined,
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

  Widget _buildAvatarImage() {
    final photo = _photoUrl;
    final fallback = Container(
      color: const Color(0xFFDDF3EF),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (photo == null) return fallback;

    return Stack(
      fit: StackFit.expand,
      children: [
        fallback,
        Image.network(
          photo,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
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
    this.onEdit,
    this.editKey,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final Key? editKey;

  @override
  Widget build(BuildContext context) {
    final editable = onEdit != null;
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
            if (editable) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: AppColors.accentTeal,
                      size: 14,
                    ),
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

