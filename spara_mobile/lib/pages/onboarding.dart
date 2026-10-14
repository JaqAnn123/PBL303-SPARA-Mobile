import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  double _scrollPosition = 0.0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Fasilitas Kampus\nDalam Genggaman',
      'subtitle':
          'Temukan dan lakukan peminjaman alat dan ruangan kampus secara cepat dan praktis.',
      'image': 'lib/assets/images/obscreen_spara/1.png',
    },
    {
      'title': 'Pilih Sarana Kampus\nSesuai Kebutuhan',
      'subtitle':
          'Fasilitas lengkap kampus dengan fitur pencarian CETAR (Cepat dan Pintar).',
      'image': 'lib/assets/images/obscreen_spara/2.png',
    },
    {
      'title': 'Pantau Status\nSecara Real Time',
      'subtitle':
          'Lihat proses persetujuan peminjaman multilevel secara aktual dan faktual.',
      'image': 'lib/assets/images/obscreen_spara/3.png',
    },
  ];

  static const _gradientCream = LinearGradient(
    colors: [AppColors.backgroundWhite, AppColors.backgroundWhite],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _gradientTeal = LinearGradient(
    colors: [AppColors.darkTeal, AppColors.accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient _currentGradient() {
    if (_scrollPosition <= 1.0) {
      return LinearGradient.lerp(_gradientCream, _gradientTeal, _scrollPosition)!;
    } else {
      return LinearGradient.lerp(_gradientTeal, _gradientCream, _scrollPosition - 1.0)!;
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _scrollPosition = (_pageController.page ?? 0.0).clamp(0.0, 2.0);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double t =
        _scrollPosition <= 1.0 ? _scrollPosition : 1.0 - (_scrollPosition - 1.0);
    final double tClamped = t.clamp(0.0, 1.0);

    final Color titleColor =
        Color.lerp(AppColors.textDark, Colors.white, tClamped)!;
    final Color subtitleColor =
        Color.lerp(AppColors.textGrey, Colors.white70, tClamped)!;
    final Color labelColor =
        Color.lerp(AppColors.midTeal, Colors.white60, tClamped)!;

    final Color skipColor =
        Color.lerp(AppColors.darkTeal, Colors.white, tClamped)!;

    final Color dotActiveColor =
        Color.lerp(AppColors.accentTeal, Colors.white, tClamped)!;

    final Color btnBgColor =
        Color.lerp(AppColors.accentTeal, Colors.white24, tClamped)!;

    final double logoTerangOpacity = tClamped;
    final double logoGelapOpacity  = 1.0 - tClamped;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(gradient: _currentGradient()),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 64,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Opacity(
                            opacity: logoGelapOpacity,
                            child: Image.asset(
                              'lib/assets/images/logo_spara/logo_gelap.png',
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Opacity(
                            opacity: logoTerangOpacity,
                            child: Image.asset(
                              'lib/assets/images/logo_spara/logo_terang.png',
                              height: 64,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      child: Text(
                        'Lewati',
                        style: TextStyle(
                          color: skipColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) {
                    return LayoutBuilder(
                      builder: (ctx, constraints) {
                        final imageHeight = constraints.maxHeight * 0.45;
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Center(
                                child: Image.asset(
                                  onboardingData[index]['image']!,
                                  height: imageHeight,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'SELAMAT DATANG DI SPARA MOBILE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: labelColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                onboardingData[index]['title']!,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                onboardingData[index]['subtitle']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingData.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? dotActiveColor
                          : Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnBgColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginPage()),
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == onboardingData.length - 1
                          ? 'Masuk ➔'
                          : 'Berikutnya ➔',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
}