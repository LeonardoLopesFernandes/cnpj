import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ─── Brand Colors (cnpj.ws) ───────────────────────────────
  static const Color primary = Color(0xFF0A6CFF);
  static const Color accent = Color(0xFF0A6CFF);
  static const Color surface = Color(0xFFF4F6FA);
  static const Color card = Colors.white;
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color textPrimary = Color(0xFF0B1B33);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // ─── Material 3 Color Scheme ────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDCE9FF),
    onPrimaryContainer: Color(0xFF0B1B33),
    secondary: accent,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFDCE9FF),
    onSecondaryContainer: Color(0xFF0B1B33),
    surface: surface,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    error: error,
    onError: Colors.white,
    errorContainer: Color(0xFFFDE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    outline: border,
    outlineVariant: Color(0xFFCBD5E1),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF0B1B33),
    inversePrimary: Color(0xFF7FB2FF),
  );

  // ─── Text Theme ─────────────────────────────────────────
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      color: textPrimary,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      color: textPrimary,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    displaySmall: TextStyle(
      color: textPrimary,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    headlineLarge: TextStyle(
      color: textPrimary,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      color: textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      color: textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      color: textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      color: textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      color: textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      color: textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      color: textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      color: textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      color: textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      color: textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      color: textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  // ─── AppBar Theme ───────────────────────────────────────
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: card,
    foregroundColor: textPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: textPrimary),
  );

  // ─── Card Theme ─────────────────────────────────────────
  static const CardThemeData _cardTheme = CardThemeData(
    color: card,
    elevation: 1,
    shadowColor: Colors.black12,
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  // ─── Elevated Button Theme ──────────────────────────────
  static const ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(accent),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
      elevation: WidgetStatePropertyAll(0),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

  // ─── Outlined Button Theme ──────────────────────────────
  static const OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(accent),
      side: WidgetStatePropertyAll(BorderSide(color: accent, width: 1.5)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

  // ─── Text Button Theme ──────────────────────────────────
  static const TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(accent),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

  // ─── Input Decoration Theme ─────────────────────────────
  static const InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: card,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: TextStyle(color: textSecondary, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: border, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: accent, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: error, width: 2),
    ),
    labelStyle: TextStyle(color: textSecondary, fontSize: 14),
    floatingLabelStyle: TextStyle(color: accent, fontSize: 12),
  );

  // ─── Bottom Navigation Bar Theme ────────────────────────
  static const BottomNavigationBarThemeData _bottomNavTheme =
      BottomNavigationBarThemeData(
    backgroundColor: card,
    selectedItemColor: accent,
    unselectedItemColor: textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  );

  // ─── Divider Theme ──────────────────────────────────────
  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: border,
    thickness: 1,
    space: 1,
  );

  // ─── Icon Theme ─────────────────────────────────────────
  static const IconThemeData _iconTheme = IconThemeData(
    color: textPrimary,
    size: 24,
  );

  // ─── Scaffold Background ────────────────────────────────
  static const Color _scaffoldBackgroundColor = surface;

  // ─── Main ThemeData ─────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: _scaffoldBackgroundColor,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      bottomNavigationBarTheme: _bottomNavTheme,
      dividerTheme: _dividerTheme,
      iconTheme: _iconTheme,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primary,
        labelStyle: TextStyle(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return border;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: border,
        thumbColor: accent,
        overlayColor: accent.withAlpha(30),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
