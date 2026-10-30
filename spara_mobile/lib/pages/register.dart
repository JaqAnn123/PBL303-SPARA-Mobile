import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/spara_api.dart';
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
  static const String _requiredFieldMessage = 'Isi data terlebih dahulu!';

  Map<String, List<Map<String, dynamic>>> _prodiByJurusan = {};
  bool _isLoadingProdi = true;
  String? _prodiError;

  final _formKey = GlobalKey<FormState>();
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

  List<String> get _jurusanList => _prodiByJurusan.keys.toList();
  List<String> get _prodiList => _jurusan == null
      ? const []
      : (_prodiByJurusan[_jurusan] ?? const [])
            .map((program) => '${program['study_program_name']}')
            .toList();

  int? get _selectedProdiId {
    if (_jurusan == null || _prodi == null) return null;
    for (final program in _prodiByJurusan[_jurusan] ?? const []) {
      if ('${program['study_program_name']}' == _prodi) {
        return int.tryParse('${program['study_program_id']}');
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadProgramStudi();
  }

  Future<void> _loadProgramStudi() async {
    setState(() {
      _isLoadingProdi = true;
      _prodiError = null;
    });
    try {
      final programs = await SparaApi.instance.getProgramStudi();
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final program in programs) {
        final department = '${program['department_name'] ?? 'Lainnya'}';
        grouped.putIfAbsent(department, () => []).add(program);
      }
      if (!mounted) return;
      setState(() {
        _prodiByJurusan = grouped;
        _isLoadingProdi = false;
        _prodiError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProdi = false;
        _prodiError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProdi = false;
        _prodiError = 'Gagal memuat program studi.';
      });
    }
  }

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

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _currentPage = 1);
  }

  void _back() => setState(() => _currentPage = 0);

  void _goToLogin() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.help_outline,
          color: AppColors.accentTeal,
          size: 32,
        ),
        content: const Text(
          'Apakah anda yakin data yang dimasukkan sudah benar?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Periksa Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, benar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final prodiId = _selectedProdiId;
    if (prodiId == null) {
      _showSnack('Pilih jurusan dan program studi terlebih dahulu.');
      return;
    }

    try {
      await SparaApi.instance.register(
        idNumber: _nimController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        studyProgramId: prodiId,
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      if (!mounted) return;
      _showSnack('Pendaftaran berhasil. Silakan masuk.');
      _goToLogin();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Pendaftaran gagal. Coba lagi.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(message),
        ),
      );
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _currentPage == 0
                                  ? _buildPageOne()
                                  : _buildPageTwo(),
                            ),
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
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        validator: _requiredFieldValidator,
        decoration: _inputDecoration(
          hint: 'Masukkan nama anda',
          prefixIcon: Icons.person_outline,
        ),
      ),
      const SizedBox(height: 16),
      _label('Email'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        validator: _requiredFieldValidator,
        decoration: _inputDecoration(
          hint: 'Masukkan email anda',
          prefixIcon: Icons.mail_outline,
        ),
      ),
      const SizedBox(height: 16),
      _label('Nomor Telepon'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        validator: _requiredFieldValidator,
        decoration: _inputDecoration(
          hint: 'Masukkan nomor telepon anda',
          prefixIcon: Icons.phone_outlined,
        ),
      ),
      const SizedBox(height: 16),
      if (_isLoadingProdi) ...[
        const LinearProgressIndicator(minHeight: 3),
        const SizedBox(height: 10),
      ],
      if (_prodiError != null) ...[
        TextButton.icon(
          onPressed: _loadProgramStudi,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text('$_prodiError Ketuk untuk mencoba lagi.'),
        ),
        const SizedBox(height: 8),
      ],
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
        onChanged: _jurusan == null ? null : (v) => setState(() => _prodi = v),
      ),
    ];
  }

  List<Widget> _buildPageTwo() {
    return [
      _label('Nomor Induk'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _nimController,
        keyboardType: TextInputType.number,
        validator: _requiredFieldValidator,
        decoration: _inputDecoration(
          hint: 'Masukkan nomor induk anda',
          prefixIcon: Icons.person_outline,
        ),
      ),
      const SizedBox(height: 16),
      _label('Kata Sandi'),
      const SizedBox(height: 8),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        validator: _requiredFieldValidator,
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
      TextFormField(
        controller: _confirmController,
        obscureText: _obscureConfirm,
        validator: _requiredFieldValidator,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _next,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Berikutnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                  side: const BorderSide(
                    color: AppColors.accentTeal,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
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
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textDark),
      decoration: _inputDecoration(
        hint: hint,
        prefixIcon: Icons.apartment_outlined,
      ),
      validator: (selectedValue) {
        if (selectedValue == null || selectedValue.isEmpty) {
          return _requiredFieldMessage;
        }
        return null;
      },
      hint: Text(
        hint,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String? _requiredFieldValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _requiredFieldMessage;
    }
    return null;
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
