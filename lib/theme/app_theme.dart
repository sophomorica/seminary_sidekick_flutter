import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Seminary Sidekick — "Sacred Editorial" Design System
///
/// The Digital Sanctuary: A premium, leather-bound volume translated
/// into a digital medium. Organic Editorial layouts with intentional
/// asymmetry, large serif typography, and a "No-Line" philosophy
/// that relies on tonal depth rather than structural boxes.
class AppTheme {
  AppTheme._();

  // ─── Sacred Editorial Color Palette (Material Tokens) ──────────
  // Primary: active states, brand moments
  static const Color primary = Color(0xFF94492C);
  static const Color primaryContainer = Color(0xFFD9805F);
  static const Color primaryFixed = Color(0xFFFFDBCF);
  static const Color primaryFixedDim = Color(0xFFFFB59B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF581C03);
  static const Color onPrimaryFixed = Color(0xFF380D00);
  static const Color onPrimaryFixedVariant = Color(0xFF763218);

  // Secondary: steady, calming elements (progress tracking)
  static const Color secondary = Color(0xFF3B665F);
  static const Color secondaryContainer = Color(0xFFBEECE2);
  static const Color secondaryFixed = Color(0xFFBEECE2);
  static const Color secondaryFixedDim = Color(0xFFA3CFC6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF426C65);
  static const Color onSecondaryFixed = Color(0xFF00201C);
  static const Color onSecondaryFixedVariant = Color(0xFF234E47);

  // Tertiary/Gold: RESERVED for "Sacred Moments" — achievements,
  // scripture mastery milestones, premium features
  static const Color tertiary = Color(0xFF735C00);
  static const Color tertiaryContainer = Color(0xFFCCA72F);
  static const Color tertiaryFixed = Color(0xFFFFE088);
  static const Color tertiaryFixedDim = Color(0xFFE9C349);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF4E3D00);
  static const Color onTertiaryFixed = Color(0xFF241A00);
  static const Color onTertiaryFixedVariant = Color(0xFF574500);

  // Surface hierarchy — "stacked sheets of fine, translucent paper"
  static const Color surface = Color(0xFFFFF8F6);         // Base "paper"
  static const Color surfaceBright = Color(0xFFFFF8F6);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);  // Floating (lifted)
  static const Color surfaceContainerLow = Color(0xFFFFF1EC);     // Sections
  static const Color surfaceContainer = Color(0xFFFBEBE6);
  static const Color surfaceContainerHigh = Color(0xFFF5E5E0);
  static const Color surfaceContainerHighest = Color(0xFFEFDFDA);
  static const Color surfaceDim = Color(0xFFE6D7D2);
  static const Color surfaceVariant = Color(0xFFEFDFDA);
  static const Color surfaceTint = Color(0xFF94492C);

  // On-surface text
  static const Color onSurface = Color(0xFF221A17);
  static const Color onSurfaceVariant = Color(0xFF54433D);
  static const Color onBackground = Color(0xFF221A17);

  // Outline
  static const Color outline = Color(0xFF87736C);
  static const Color outlineVariant = Color(0xFFDAC1B9);

  // Inverse
  static const Color inverseSurface = Color(0xFF372E2B);
  static const Color inverseOnSurface = Color(0xFFFEEDE8);
  static const Color inversePrimary = Color(0xFFFFB59B);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ─── Legacy Aliases (backward compatibility) ────────────────────
  static const Color primaryDark = Color(0xFF763218);
  static const Color primaryLight = Color(0xFFFFB59B);
  static const Color secondaryDark = Color(0xFF234E47);
  static const Color secondaryLight = Color(0xFFA3CFC6);
  static const Color accent = Color(0xFF5B8ABF);
  static const Color accentLight = Color(0xFF89B4DB);
  static const Color dark = Color(0xFF221A17);       // on-surface
  static const Color darkSurface = Color(0xFF54433D); // on-surface-variant
  static const Color cream = Color(0xFFFFF1EC);       // surface-container-low
  // "offWhite" is now "surface"
  static const Color offWhite = Color(0xFFFFF8F6);

  // ─── Game Feedback Colors ───────────────────────────────────────
  static const Color success = Color(0xFF66BB6A);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFA726);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color gold = Color(0xFF735C00);  // aligned with tertiary

  // ─── Premium / Upgrade Colors (now tertiary-aligned) ────────────
  static const Color premiumGold = Color(0xFFCCA72F);
  static const Color premiumGoldLight = Color(0xFFFFE088);
  static const Color premiumGradientStart = Color(0xFFCCA72F);
  static const Color premiumGradientEnd = Color(0xFFE9C349);

  // ─── Mastery Level Colors ───────────────────────────────────────
  static const Color masteryNew = Color(0xFF9E9E9E);
  static const Color masteryLearning = Color(0xFFFF8A65);
  static const Color masteryFamiliar = Color(0xFFFFD54F);
  static const Color masteryMemorized = Color(0xFF81C784);
  static const Color masteryMastered = Color(0xFF64B5F6);
  static const Color masteryEternal = Color(0xFFCCA72F);  // Sacred gold

  // ─── Book Colors ────────────────────────────────────────────────
  static const Color oldTestamentColor = Color(0xFF8D6E63);
  static const Color newTestamentColor = Color(0xFF5C6BC0);
  static const Color bookOfMormonColor = Color(0xFF26A69A);
  static const Color doctrineCovenants = Color(0xFFAB47BC);

  // ─── Dark Mode — "Deep Grove" (green-slate, matching app logo) ──
  static const Color darkBackground = Color(0xFF1A2226);
  static const Color darkCard = Color(0xFF222E32);
  static const Color darkSurfaceColor = Color(0xFF1E2A2E);
  static const Color darkOnSurface = Color(0xFFE2EBE8); // cool sage-tinted white
  static const Color darkSurfaceContainerLow = Color(0xFF263236);
  static const Color darkSurfaceContainer = Color(0xFF2E3A3E);
  static const Color darkSurfaceContainerHigh = Color(0xFF384448);

  // ─── Spacing ────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ─── Border Radius (Sacred Editorial: smooth stones) ────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;   // 1rem — default
  static const double radiusLg = 24.0;   // 1.5rem
  static const double radiusXl = 32.0;   // 2rem — cards
  static const double radiusXxl = 48.0;  // 3rem — hero sections
  static const double radiusRound = 9999.0;

  // ─── Ambient Shadows (tinted, never pure black) ─────────────────
  static const List<BoxShadow> editorialShadow = [
    BoxShadow(
      color: Color(0x0F221A17), // on-surface at 6%
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x0A221A17), // on-surface at 4%
      blurRadius: 40,
      offset: Offset(0, 12),
    ),
  ];

  // ─── Light Theme ────────────────────────────────────────────────
  static ThemeData getLightTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
      surfaceTint: surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: surface,
      textTheme: _buildTextTheme(onSurface),
      appBarTheme: _buildAppBarTheme(onSurface),
      cardTheme: _buildCardTheme(surfaceContainerLowest),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      navigationBarTheme: _buildNavigationBarTheme(
        bgColor: surface,
        labelColor: onSurfaceVariant,
      ),
      chipTheme: _buildChipTheme(
        bgColor: surfaceContainerLow,
        labelColor: onSurface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0,  // No-Line philosophy
        space: 48,     // Use whitespace instead
      ),
    );
  }

  // ─── Dark Theme — "Deep Grove" ───────────────────────────────────
  static ThemeData getDarkTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryFixedDim,
      onPrimary: darkBackground,
      primaryContainer: primary,
      onPrimaryContainer: primaryFixed,
      secondary: secondaryFixedDim,
      onSecondary: darkBackground,
      secondaryContainer: secondaryDark,
      onSecondaryContainer: secondaryFixed,
      tertiary: tertiaryFixedDim,
      onTertiary: darkBackground,
      tertiaryContainer: tertiary,
      onTertiaryContainer: tertiaryFixed,
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: darkBackground,
      onSurface: darkOnSurface,
      surfaceContainerLowest: darkBackground,
      surfaceContainerLow: darkSurfaceContainerLow,
      surfaceContainer: darkSurfaceContainer,
      surfaceContainerHigh: darkSurfaceContainerHigh,
      surfaceContainerHighest: Color(0xFF425054),  // green-slate highest
      onSurfaceVariant: Color(0xFFB9CFC8),         // sage-tinted muted text
      outline: Color(0xFF6C8780),                   // green-tinted outline
      outlineVariant: Color(0xFF3D5450),            // subtle green border
      inverseSurface: Color(0xFFE2EBE8),            // light sage
      onInverseSurface: Color(0xFF1A2226),          // dark on light
      inversePrimary: primary,
      surfaceTint: secondaryFixedDim,               // green tint instead of brown
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
        bgColor: darkBackground,
        labelColor: darkOnSurface,
      ),
      chipTheme: _buildChipTheme(
        bgColor: darkCard,
        labelColor: darkOnSurface,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBackground,
        selectedItemColor: primaryFixedDim,
        unselectedItemColor: darkOnSurface.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0,
        space: 48,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    final mutedColor = textColor.withValues(alpha: 0.7);
    return TextTheme(
      // Display: Scriptural voice — large, generous leading
      displayLarge: GoogleFonts.merriweather(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.merriweather(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.2,
        letterSpacing: -0.3,
      ),
      displaySmall: GoogleFonts.merriweather(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.25,
      ),
      // Headlines: Noto Serif / Merriweather for editorial authority
      headlineLarge: GoogleFonts.merriweather(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.merriweather(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
      ),
      // Titles & Body: Inter — the "Guide" voice
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
        height: 1.6,
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
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: mutedColor,
        letterSpacing: 1.0,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: mutedColor,
        letterSpacing: 1.5,
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
        fontStyle: FontStyle.italic,
      ),
    );
  }

  static CardThemeData _buildCardTheme(Color cardColor) {
    return CardThemeData(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),  // 2rem — "smooth stones"
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
          borderRadius: BorderRadius.circular(radiusRound), // Fully rounded — "Soulful" buttons
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
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
          borderRadius: BorderRadius.circular(radiusRound),
        ),
        side: BorderSide(color: outlineVariant.withValues(alpha: 0.15)), // Ghost border
      ),
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme({
    required Color bgColor,
    required Color labelColor,
  }) {
    return NavigationBarThemeData(
      backgroundColor: bgColor,
      elevation: 0,
      indicatorColor: primary.withValues(alpha: 0.10),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusRound),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: primary,
            letterSpacing: 1.5,
          );
        }
        return GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: labelColor.withValues(alpha: 0.6),
          letterSpacing: 1.5,
        );
      }),
    );
  }

  static ChipThemeData _buildChipTheme({
    required Color bgColor,
    required Color labelColor,
  }) {
    return ChipThemeData(
      backgroundColor: bgColor,
      selectedColor: primary.withValues(alpha: 0.15),
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

  // ─── Sidekick Colors (dark-mode-aware) ───────────────────────────
  static Color sidekickColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? secondaryFixedDim
        : premiumGold;
  }

  static List<Color> sidekickGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [secondary, secondaryFixedDim]
        : [premiumGradientStart, premiumGradientEnd];
  }

  static Color sidekickTint(BuildContext context, [double alpha = 0.12]) {
    return sidekickColor(context).withValues(alpha: alpha);
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
