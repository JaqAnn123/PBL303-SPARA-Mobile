import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'theme/app_colors.dart';
import 'pages/onboarding.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spara Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        
        fontFamily: GoogleFonts.poppins().fontFamily, 
      ),
      home: const OnboardingPage(),
    );
  }
}