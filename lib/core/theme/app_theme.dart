import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // ─── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DarkColors.accent,
        brightness: Brightness.dark,
        primary: DarkColors.accent,
        onPrimary: const Color(0xFF381E72),
        secondary: DarkColors.accentSecondary,
        surface: DarkColors.surface,
        onSurface: DarkColors.textPrimary,
        surfaceContainerHighest: DarkColors.surfaceVariant,
        background: DarkColors.background,
        error: DarkColors.expenseRed,
      ),
      scaffoldBackgroundColor: DarkColors.background,
      textTheme:
          _buildTextTheme(DarkColors.textPrimary, DarkColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: DarkColors.background,
        elevation: 0,
        scrolledUnderElevation: 2,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: DarkColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: DarkColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DarkColors.surface,
        elevation: 0,
        indicatorColor: DarkColors.accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DarkColors.textPrimary,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DarkColors.accent,
          foregroundColor: const Color(0xFF381E72),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(
        DarkColors.surface,
        DarkColors.divider,
        DarkColors.textPrimary,
        DarkColors.textSecondary,
        DarkColors.accent,
      ),
      dividerTheme: const DividerThemeData(color: DarkColors.divider, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DarkColors.surface,
        modalBackgroundColor: DarkColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: DarkColors.surface,
        surfaceTintColor: DarkColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  // ─── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LightColors.accent,
        brightness: Brightness.light,
        primary: LightColors.accent,
        onPrimary: Colors.white,
        secondary: LightColors.accentSecondary,
        surface: LightColors.surface,
        onSurface: LightColors.textPrimary,
        surfaceContainerHighest: LightColors.surfaceVariant,
        background: LightColors.background,
        error: LightColors.expenseRed,
      ),
      scaffoldBackgroundColor: LightColors.background,
      textTheme:
          _buildTextTheme(LightColors.textPrimary, LightColors.textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: LightColors.background,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: LightColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: LightColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LightColors.surface,
        elevation: 0,
        indicatorColor: LightColors.accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LightColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(
        LightColors.background,
        LightColors.divider,
        LightColors.textPrimary,
        LightColors.textSecondary,
        LightColors.accent,
      ),
      dividerTheme:
          const DividerThemeData(color: LightColors.divider, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LightColors.surface,
        modalBackgroundColor: LightColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LightColors.surface,
        surfaceTintColor: LightColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      cardTheme: CardThemeData(
        color: LightColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: LightColors.divider, width: 1),
        ),
      ),
    );
  }

  // ─── Shared Text Theme ───────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return GoogleFonts.plusJakartaSansTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 57, fontWeight: FontWeight.w700, color: primary),
      displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 45, fontWeight: FontWeight.w700, color: primary),
      displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 36, fontWeight: FontWeight.w700, color: primary),
      headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w600, color: primary),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w700, color: primary),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }

  // ─── Shared Input Theme ──────────────────────────────────────────────────────
  static InputDecorationTheme _buildInputTheme(
    Color fill,
    Color border,
    Color text,
    Color hint,
    Color focus,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: focus, width: 2),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(color: hint, fontSize: 14),
      labelStyle: GoogleFonts.plusJakartaSans(color: hint, fontSize: 14),
      prefixIconColor: hint,
      suffixIconColor: hint,
    );
  }
}
