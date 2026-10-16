import 'package:flutter/material.dart';

class AppColors {
  static const Color darkTeal    = Color(0xFF1B4F4A);
  static const Color primary     = Color(0xFF126A64);
  static const Color midTeal     = Color(0xFF1D6C64);
  static const Color accentTeal  = Color(0xFF20A99A);
  static const Color lightTeal   = Color(0xFF13A695);
  static const Color navDark     = Color(0xFF061917);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [darkTeal, accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient loginGradient = LinearGradient(
    colors: [darkTeal, midTeal],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color backgroundWhite = Color(0xFFFBF7EE);
  static const Color cardBackground  = Colors.white;

  static const Color textDark  = Color(0xFF202B2D);
  static const Color textGrey  = Color(0xFF757575);

  static const Color warning = Color(0xFFFFC107);
  static const Color error   = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CAF50);
}