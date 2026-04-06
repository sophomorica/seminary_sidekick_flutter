import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Seminary Sidekick design system.
///
/// Warm, inviting palette refined for mobile with high contrast
/// and game-friendly vibrancy.
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ───────────────────────────────────────────────
  static const Color primary = Color(0xFFD9805F);       // Warm rust/terracotta
  static const Color primaryDark = Color(0xFFB8654A);
  static const Color primaryLight = Color(0xFFE8A48D);

  static const Color secondary = Color(0xFF618C84);     // Sage green
  static const Color secondaryDark = Color(0xFF4A6E68);
  static const Color secondaryLight = Color(0xFF8BB5AD);

  static const Color accent = Color(0xFF5B8ABF);        // Calm blue
  static const Color accentLight = Color(0xFF89B4DB);

  static const Color dark = Color(0xFF2D3142);           // Deep blue-gray
  static const Color darkSurface = Color(0xFF4F5A6B);
  static const Color cream = Color(0xFFF2EDD0);          // Warm cream
  static const Color surface = Color(0xFFF5F0E1);
  static const Color offWhite = Color(0xFFFAF8F0);

  // ─── Dark Mode Surface Colors ─────────────────────────────────
  static const Color darkBackground = Color(0xFF1A1B2E);   // Deep night blue
  static const Color darkCard = Color(0xFF242640);          // Raised surface
  static const Color darkSurfaceColor = Color(0xFF1F2035);  // Slightly lifted
  static const Color darkOnSurface = Color(0xFFE8E6F0);    // Light text on dark

  // ─── Game Feedback Colors ───────────────────────────────────────
  static const Color success = Color(0xFF66BB6A);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFC75050);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFA726);
  static const Color gold = Color(0xFFD4A843);

  // ─── Premium / Upgrade Colors ────────────────────────────────────
  static const Color premiumGold = Color(0xFFD4A843);        // Premium badge
  static const Color premiumGoldLight = Color(0xFFF5E6B8);   // Premium bg tint
  static const Color premiumGradientStart = Color(0xFFD4A843);
  static const Color premiumGradientEnd = Color(0xFFE8C86A);

  // ─── Mastery Level Colors ───────────────────────────────────────
  static const Color masteryNew = Color(0xFF9E9E9E);
  static const Color masteryLearning = Color(0xFFFF8A65);
  static const Color masteryFamiliar = Color(0xFFFFD54F);
  static const Color masteryMemorized = Color(0xFF81C784);
  static const Color masteryMastered = Color(0xFF64B5F6);
  static const Color masteryEternal = Color(0xFFFFD700);  // Gold — permanent

  // ─── Book Colors (for visual distinction) ───────────────────────
  static const Color oldTestamentColor = Color(0xFF8D6E63);  // Brown
  static const Color newTestamentColor = Color(0xFF5C6BC0);  // Indigo
  static const Color bookOfMormonColor = Color(0xFF26A69A);  // Teal
  static const Color doctrineCovenants = Color(0xFFAB47BC);  // Purple

  // ─── Spacing ────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ─── Border Radius ──────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 100.0;

  // ─── Light Theme ────────────────────────────────────────────────
  static ThemeData getLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      tertiary: gold,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: dark,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: offWhite,
      textTheme: _buildTextTheme(dark),
      appBarTheme: _buildAppBarTheme(dark),
      cardTheme: _buildCardTheme(Colors.white),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      navigationBarTheme: _buildNavigationBarTheme(
        bgColor: Colors.white,
        labelColor: dark,
      ),
      chipTheme: _buildChipTheme(
        bgColor: cream,
        labelColor: dark,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: dark.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // ─── Dark Theme ─────────────────────────────────────────────────
  static ThemeData getDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primaryLight,
      secondary: secondaryLight,
      tertiary: gold,
      surface: darkSurfaceColor,
      error: error,
      onPrimary: darkBackground,
      onSecondary: darkBackground,
      onSurface: darkOnSurface,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: darkBackground,
      textTheme: _buildTextTheme(darkOnSurface),
      appBarTheme: _buildAppBarTheme(darkOnSurface),
      cardTheme: _buildCardTheme(darkCard),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      navigationBarTheme: _buildNavigationBarTheme(
        bgColor: darkCard,
        labelColor: darkOnSurface,
      ),
      chipTheme: _buildChipTheme(
        bgColor: darkCard,
        labelColor: darkOnSurface,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryLight,
        unselectedItemColor: darkOnSurface.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    final mutedColor = textColor.withValues(alpha: 0.7);
    return TextTheme(
      displayLarge: GoogleFonts.merriweather(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.merriweather(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.merriweather(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.merriweather(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: mutedColor,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color foreground) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: foreground,
      centerTitle: false,
      titleTextStyle: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    );
  }

  static CardThemeData _buildCardTheme(Color cardColor) {
    return CardThemeData(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      margin: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        side: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme({
    required Color bgColor,
    required Color labelColor,
  }) {
    return NavigationBarThemeData(
      backgroundColor: bgColor,
      elevation: 8,
      indicatorColor: primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: labelColor,
        ),
      ),
    );
  }

  static ChipThemeData _buildChipTheme({
    required Color bgColor,
    required Color labelColor,
  }) {
    return ChipThemeData(
      backgroundColor: bgColor,
      selectedColor: primary.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: spacingSm, vertical: spacingXs),
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: labelColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusRound),
      ),
      side: BorderSide.none,
    );
  }

  // ─── Helper: Get color for a scripture book ─────────────────────
  static Color bookColor(String bookKey) {
    return switch (bookKey) {
      'oldTestament' || 'Old Testament' => oldTestamentColor,
      'newTestament' || 'New Testament' => newTestamentColor,
      'bookOfMormon' || 'Book of Mormon' => bookOfMormonColor,
      'doctrineAndCovenants' || 'Doctrine & Covenants' => doctrineCovenants,
      _ => primary,
    };
  }

  static Color masteryColor(int levelIndex) {
    return switch (levelIndex) {
      0 => masteryNew,
      1 => masteryLearning,
      2 => masteryFamiliar,
      3 => masteryMemorized,
      4 => masteryMastered,
      5 => masteryEternal,
      _ => masteryNew,
    };
  }
}
