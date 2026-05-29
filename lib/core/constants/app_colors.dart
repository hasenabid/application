import 'package:flutter/material.dart';

class AppColors {
  // Hardware Theme Colors
  static const Color background = Color(0xFFE0E0E0); // Light grey for the metal box
  static const Color panelBackground = Color(0xFFF5F5F5); // Off-white for the front panel
  
  // LCD Colors
  static const Color lcdBackground = Color(0xFFA9C2E3); // Light blue LCD background
  static const Color lcdText = Color(0xFF1B2E4B); // Dark blue/black LCD text
  
  // LED Status Colors
  static const Color ledOk = Color(0xFF4CAF50); // Bright Green
  static const Color ledHigh = Color(0xFFF44336); // Red
  static const Color ledLow = Color(0xFFFF9800); // Orange
  static const Color ledOff = Color(0xFF9E9E9E); // Grey (unlit)
  static const Color ledBlack = Color(0xFF212121); // Black (some LEDs in the pic are dark)
  
  // Other Elements
  static const Color buttonGrey = Color(0xFFBDBDBD);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);

  // Fallback for older components (if any left)
  static const Color primary = Color(0xFF1B2E4B);
  static const Color secondary = Color(0xFF455A64);
  static const Color success = ledOk;
  static const Color warning = ledLow;
  static const Color error = ledHigh;
}
