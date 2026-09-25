import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  static const _navy = Color(0xFF0B1F3A);
  static const _gold = Color(0xFFE4A800);
  static const _lightSurface = Color(0xFFFFFEFA);
  static const _darkSurface = Color(0xFF101A2B);

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeData get lightTheme => _buildTheme(
    ColorScheme.light(
      primary: _gold,
      onPrimary: _navy,
      secondary: _navy,
      onSecondary: Colors.white,
      surface: _lightSurface,
      onSurface: _navy,
      surfaceContainerHighest: const Color(0xFFF1F3F6),
      outline: const Color(0xFF667085),
    ),
  );

  ThemeData get darkTheme => _buildTheme(
    ColorScheme.dark(
      primary: _gold,
      onPrimary: _navy,
      secondary: const Color(0xFFB9C9E6),
      onSecondary: _navy,
      surface: _darkSurface,
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF1D2A40),
      outline: const Color(0xFF9EACC2),
    ),
  );

  ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDarkTheme = colorScheme.brightness == Brightness.dark;
    final baseTextTheme = isDarkTheme
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'Poppins',
      textTheme: baseTextTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDarkTheme ? colorScheme.surfaceContainerHighest : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkTheme
            ? colorScheme.surfaceContainerHighest
            : Colors.white,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _gold, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDarkTheme ? _gold : _navy,
          side: BorderSide(color: isDarkTheme ? _gold : _navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _gold,
        foregroundColor: _navy,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.35),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: _gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
