import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ForestGuard Premium Design System
/// Dark forest atmosphere with glassmorphism, glow effects,
/// and curated color palette for a hackathon-winning product.
class AppTheme {
  // ─── Brand Colors ─────────────────────────────────────────
  static const Color forestGreen = Color(0xFF1B5E20);
  static const Color emerald = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color canopyGreen = Color(0xFF0A3D0A);

  // Deep Forest Atmosphere
  static const Color forestDark = Color(0xFF0D1B0F);
  static const Color forestDeep = Color(0xFF0A1F0C);
  static const Color forestMist = Color(0xFF1A2E1C);
  static const Color forestSurface = Color(0xFF162218);

  // ─── Safety Colors ────────────────────────────────────────
  static const Color safeGreen = Color(0xFF22C55E);
  static const Color approachingAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color rangerBlue = Color(0xFF1565C0);

  // ─── Neutrals ─────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF8FAF9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);

  // ─── Animal Colors ────────────────────────────────────────
  static const Map<String, Color> animalColors = {
    'tiger': Color(0xFFFF6F00),
    'elephant': Color(0xFF5D4037),
    'lion': Color(0xFFBF360C),
    'leopard': Color(0xFF4E342E),
    'bear': Color(0xFF37474F),
  };

  // ─── Premium Gradients ────────────────────────────────────
  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2B0F), Color(0xFF1B5E20), Color(0xFF2E7D32)],
  );

  static const LinearGradient darkForestGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1F0C), Color(0xFF0D1B0F), Color(0xFF162218)],
  );

  static const LinearGradient emeraldGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF00C853)],
  );

  static const LinearGradient rangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB71C1C), Color(0xFFEF4444)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE65100), Color(0xFFF59E0B)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.5, -0.3),
    end: Alignment(1.5, 0.3),
    colors: [
      Color(0x00FFFFFF),
      Color(0x33FFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  // ─── Glassmorphism ────────────────────────────────────────

  /// Frosted glass decoration for cards and containers
  static BoxDecoration frostedGlass({
    double opacity = 0.08,
    double borderRadius = 20,
    Color? borderColor,
    double borderWidth = 1,
    Color? glowColor,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.12),
        width: borderWidth,
      ),
      boxShadow: glowColor != null
          ? [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }

  /// Dark frosted glass for overlays on light backgrounds
  static BoxDecoration darkFrostedGlass({
    double opacity = 0.6,
    double borderRadius = 20,
    Color? glowColor,
  }) {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1,
      ),
      boxShadow: glowColor != null
          ? [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.15),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }

  // ─── Premium Shadows ──────────────────────────────────────

  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.25}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 20,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: color.withValues(alpha: intensity * 0.5),
        blurRadius: 40,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  // ─── Status Helpers ───────────────────────────────────────

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
      case 'needs_verification':
        return approachingAmber;
      case 'acknowledged':
      case 'monitoring':
        return infoBlue;
      case 'closed':
      case 'rejected':
        return textSecondary;
      default:
        return infoBlue;
    }
  }

  static LinearGradient getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return const LinearGradient(colors: [Color(0xFF059669), Color(0xFF22C55E)]);
      case 'approaching':
        return amberGradient;
      case 'inside':
      case 'active':
      case 'danger':
        return dangerGradient;
      default:
        return const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]);
    }
  }

  // ─── Theme Data ───────────────────────────────────────────

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
        bodyColor: textPrimary,
        displayColor: textPrimary,
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestGreen,
          side: BorderSide(color: forestGreen.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F4F1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: forestGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        prefixIconColor: textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: forestGreen.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: forestGreen);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: forestGreen, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
    );
  }
}
