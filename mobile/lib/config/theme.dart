import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ForestGuard Material 3 Theme
/// Forest Green + Safety palette with professional typography.
class AppTheme {
  // Brand Colors
  static const Color forestGreen = Color(0xFF1B5E20);
  static const Color emerald = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);

  // Safety Colors
  static const Color safeGreen = Color(0xFF22C55E);
  static const Color approachingAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Neutral
  static const Color surfaceLight = Color(0xFFF8FAF9);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Animal Colors
  static const Map<String, Color> animalColors = {
    'tiger': Color(0xFFFF6F00),
    'elephant': Color(0xFF5D4037),
    'lion': Color(0xFFBF360C),
    'leopard': Color(0xFF4E342E),
    'bear': Color(0xFF37474F),
  };

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return safeGreen;
      case 'approaching':
        return approachingAmber;
      case 'inside':
      case 'active':
      case 'danger':
        return dangerRed;
      default:
        return infoBlue;
    }
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: forestGreen,
      brightness: Brightness.light,
      primary: forestGreen,
      secondary: emerald,
      error: dangerRed,
      surface: surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceLight,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: const Color(0xFF1A1A2E),
        displayColor: const Color(0xFF1A1A2E),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: forestGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: forestGreen,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
