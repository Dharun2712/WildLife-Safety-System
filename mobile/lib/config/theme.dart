import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ForestGuard — Official Google Stitch Design System Palette & Theme
/// High-fidelity implementation of the Stitch Material 3 design spec.
class AppTheme {
  // ─── Stitch Material 3 Color Tokens ─────────────────────────
  static const Color primary = Color(0xFF012D1D); // Deep Forest Dark Green
  static const Color forestGreen = Color(0xFF012D1D); // Alias for primary
  static const Color primaryContainer = Color(0xFF1B4332);
  static const Color primaryFixed = Color(0xFFC1ECD4);
  static const Color primaryFixedDim = Color(0xFFA5D0B9);
  
  static const Color secondary = Color(0xFF006C48);
  static const Color secondaryContainer = Color(0xFF92F7C3);
  static const Color onSecondaryContainer = Color(0xFF00734D);
  static const Color secondaryFixedDim = Color(0xFF75DAA8);

  static const Color surface = Color(0xFFF9FAF6); // Soft Sage Light Surface
  static const Color surfaceContainerLow = Color(0xFFF3F4F0);
  static const Color surfaceContainer = Color(0xFFEDEEEA);
  static const Color surfaceContainerHigh = Color(0xFFE7E9E5);
  static const Color surfaceContainerHighest = Color(0xFFE2E3DF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE2E3DF);

  static const Color error = Color(0xFFBA1A1A); // Stitch Emergency Red
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color tertiaryFixedDim = Color(0xFFFFBA27); // Amber Warning
  static const Color tertiaryContainer = Color(0xFF503700);

  static const Color onSurface = Color(0xFF1A1C1A);
  static const Color onSurfaceVariant = Color(0xFF414844);
  static const Color outline = Color(0xFF717973);
  static const Color outlineVariant = Color(0xFFC1C8C2);
  static const Color inverseSurface = Color(0xFF2E312F);

  // Quick Semantic Helpers
  static const Color safeGreen = Color(0xFF006C48);
  static const Color approachingAmber = Color(0xFFD89B00);
  static const Color dangerRed = Color(0xFFBA1A1A);
  static const Color infoBlue = Color(0xFF1D4ED8);
  static const Color rangerBlue = Color(0xFF0D47A1);

  // Animal Accent Colors
  static const Map<String, Color> animalColors = {
    'tiger': Color(0xFFFF6F00),
    'elephant': Color(0xFF5D4037),
    'lion': Color(0xFFBF360C),
    'leopard': Color(0xFF4E342E),
    'bear': Color(0xFF37474F),
  };

  // ─── Stitch Gradients ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF012D1D), Color(0xFF1B4332)],
  );

  static const LinearGradient emeraldGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF012D1D), Color(0xFF006C48)],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBA1A1A), Color(0xFF93000A)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF006C48), Color(0xFF00734D)],
  );

  static const LinearGradient rangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
  );

  // ─── Stitch Elevation & Ambient Shadows ───────────────────────
  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.25}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ];
  }

  // ─── Stitch Elevation & Ambient Shadows ───────────────────────
  static List<BoxShadow> ambientShadow = [
    BoxShadow(
      color: const Color(0xFF1B4332).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> sosShadow = [
    BoxShadow(
      color: const Color(0xFFBA1A1A).withValues(alpha: 0.35),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── Status Color Helper ──────────────────────────────────────
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return safeGreen;
      case 'approaching':
      case 'needs_verification':
        return approachingAmber;
      case 'inside':
      case 'active':
      case 'danger':
        return dangerRed;
      case 'acknowledged':
      case 'monitoring':
        return infoBlue;
      default:
        return onSurfaceVariant;
    }
  }

  // ─── Flutter ThemeData (Google Stitch Specification) ─────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: const Color(0xFF86AF99),
      secondary: secondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      error: error,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: surfaceContainerLowest,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLowest.withValues(alpha: 0.8),
        foregroundColor: primary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceContainerLowest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerLowest.withValues(alpha: 0.9),
        elevation: 8,
        indicatorColor: secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: onSecondaryContainer);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: onSecondaryContainer, size: 24);
          }
          return const IconThemeData(color: onSurfaceVariant, size: 24);
        }),
      ),
    );
  }
}
