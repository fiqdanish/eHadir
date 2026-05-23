import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// eHadir design tokens & theme.
class EHadirTheme {
  EHadirTheme._();

  // ─── Brand colours ────────────────────────────────────────
  static const Color primary      = Color(0xFF3F51B5); // Indigo
  static const Color primaryDark  = Color(0xFF1A237E); // Deep Indigo
  static const Color accent       = Color(0xFF00BFA5); // Teal accent
  static const Color surface      = Color(0xFF121228); // Dark surface
  static const Color surfaceLight = Color(0xFF1E1E3F); // Elevated surface
  static const Color card         = Color(0xFF252547); // Card surface
  static const Color cardHover    = Color(0xFF2D2D55);
  static const Color background   = Color(0xFF0D0D1F); // Deepest background
  static const Color textPrimary  = Color(0xFFF0F0FF);
  static const Color textSecondary= Color(0xFF9E9EBF);
  static const Color divider      = Color(0xFF2A2A4A);

  // ─── Status colours ───────────────────────────────────────
  static const Color pending  = Color(0xFFFFA726); // Amber
  static const Color approved = Color(0xFF66BB6A); // Emerald
  static const Color rejected = Color(0xFFEF5350); // Rose

  // ─── Gradient ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3F51B5), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3F51B5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF252547), Color(0xFF1E1E3F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Border radius ────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ─── Shadows ──────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── Status helpers ───────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending review':
        return pending;
      case 'approved':
        return approved;
      case 'rejected':
        return rejected;
      default:
        return textSecondary;
    }
  }

  static IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending review':
        return Icons.schedule_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  THEME DATA
  // ═══════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: rejected,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        outline: divider,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        labelStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.outfit(color: textSecondary.withValues(alpha: 0.6), fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primary.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.outfit(color: textPrimary, fontSize: 13),
        side: BorderSide(color: divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: GoogleFonts.outfit(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        titleTextStyle: GoogleFonts.outfit(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 15),
      ),
    );
  }
}
