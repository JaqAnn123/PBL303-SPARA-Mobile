import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color _cardColor = Color(0xFFFAF5EC);
  static const int _totalPages = 2;

  int _currentPage = 0;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _jurusan;
  String? _prodi;

  static const Map<String, List<String>> _prodiByJurusan = {
    'Manajemen Bisnis': [
      'D2 Distribusi Barang',
      'D3 Akuntansi',
      'D4 Administrasi Bisnis Terapan',
      'D4 Akuntansi Manajerial',
      'D4 Logistik Perdagangan Internasional',
    ],
    'Teknik Elektro': [
      'D3 Teknik Elektronika Manufaktur',
      'D3 Teknik Instrumentasi',
      'D4 Teknologi Rekayasa Elektronika',
      'D4 Teknik Mekatronika',
      'D4 Teknologi Rekayasa Pembangkit Energi',
      'D4 Teknik Robotika',
    ],
    'Teknik Informatika': [
      'D3 Teknik Informatika',
      'D3 Teknologi Geomatika',
      'D4 Animasi',
      'D4 Teknologi Rekayasa Multimedia',
      'D4 Rekayasa Keamanan Siber',
      'D4 Teknologi Rekayasa Perangkat Lunak',
      'D4 Teknologi Permainan',
    ],
    'Teknik Mesin': [
      'D3 Teknik Mesin',
      'D3 Teknik Perawatan Pesawat Udara',
      'D4 Teknologi Rekayasa Konstruksi Perkapalan',
      'D4 Teknologi Rekayasa Pengelasan dan Fabrikasi',
    ],
  };

  List<String> get _jurusanList => _prodiByJurusan.keys.toList();
  List<String> get _prodiList =>
      _jurusan == null ? const [] : _prodiByJurusan[_jurusan]!;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nimController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _next() => setState(() => _currentPage = 1);
  void _back() => setState(() => _currentPage = 0);

  void _goToLogin() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

  void _submit() {
    // TODO: kirim data pendaftaran ke server
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.loginGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/logo_spara/logo_gelap.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Daftar Akun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Isi data di bawah ini dengan baik dan benar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _currentPage == 0
                                ? _buildPageOne()
                                : _buildPageTwo(),
                          ),
                        ),
                      ),
                      _buildBottomActions(),
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

  List<Widget> _buildPageOne() {
    return [
      _label('Nama'),
      const SizedBox(height: 8),
      TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: _inputDecoration(
          hint: 'Masukkan nama anda',
          prefixIcon: Icons.person_outline,
        ),
      ),
      const SizedBox(height: 16),
      _label('Email'),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: _inputDecoration(
          hint: 'Masukkan email anda',
          prefixIcon: Icons.mail_outline,
        ),
      ),
      const SizedBox(height: 16),
      _label('Nomor Telepon'),
      const SizedBox(height: 8),
      TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: _inputDecoration(
          hint: 'Masukkan nomor telepon anda',
          prefixIcon: Icons.phone_outlined,
        ),
      ),
      const SizedBox(height: 16),
      _label('Jurusan'),
      const SizedBox(height: 8),
      _dropdown(
        value: _jurusan,
        hint: 'Pilih jurusan anda',
        items: _jurusanList,
        onChanged: (v) => setState(() {
          _jurusan = v;
          _prodi = null;
        }),
      ),
      const SizedBox(height: 16),
      _label('Program Studi'),
      const SizedBox(height: 8),
      _dropdown(
        key: ValueKey(_jurusan),
        value: _prodi,
        hint: _jurusan == null
            ? 'Pilih jurusan terlebih dahulu'
            : 'Pilih program studi anda',
        items: _prodiList,
        onChanged:
            _jurusan == null ? null : (v) => setState(() => _prodi = v),
      ),
    ];
  }

  List<Widget> _buildPageTwo() {
    return [
      _label('Nomor Induk'),
      const SizedBox(height: 8),
      TextField(
        controller: _nimController,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration(
          hint: 'Masukkan nomor induk anda',
          prefixIcon: Icons.person_outline,
        ),
      ),
      const SizedBox(height: 16),
      _label('Kata Sandi'),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: _inputDecoration(
          hint: 'Masukkan kata sandi anda',
          prefixIcon: Icons.lock_open_outlined,
          suffix: _visibilityButton(
            obscure: _obscurePassword,
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _label('Konfimasi Kata Sandi'),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmController,
        obscureText: _obscureConfirm,
        decoration: _inputDecoration(
          hint: 'Konfirmasi kata sandi anda',
          prefixIcon: Icons.lock_open_outlined,
          suffix: _visibilityButton(
            obscure: _obscureConfirm,
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
    ];
  }

  Widget _buildBottomActions() {
    final bool isFirst = _currentPage == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Halaman ${_currentPage + 1} dari $_totalPages',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (isFirst)
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _next,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Berikutnya',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentTeal,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.accentTeal, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _back,
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _submit,
                child: const Text(
                  'Daftar akun',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sudah memiliki akun? ',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                GestureDetector(
                  onTap: _goToLogin,
                  child: const Text(
                    'Masuk',
                    style: TextStyle(
                      color: AppColors.darkTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _visibilityButton({
    required bool obscure,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.grey,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }

  Widget _dropdown({
    Key? key,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      value: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
      decoration: _inputDecoration(
        hint: hint,
        prefixIcon: Icons.apartment_outlined,
      ),
      hint: Text(
        hint,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.grey, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5),
      ),
    );
  }
}