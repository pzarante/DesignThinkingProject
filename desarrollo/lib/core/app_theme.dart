import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The [AppTheme] defines light and dark themes for the app.
abstract final class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6500D9),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE9D8FF),
      onPrimaryContainer: Color(0xFF26005A),
      secondary: Color(0xFF6D28D9),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEDE2FF),
      onSecondaryContainer: Color(0xFF2A075F),
      surface: Color(0xFFFFFAFF),
      surfaceContainerHighest: Color(0xFFF1E8FF),
      onSurface: Color(0xFF211B24),
      onSurfaceVariant: Color(0xFF625A69),
      outline: Color(0xFF81798A),
      outlineVariant: Color(0xFFE5DDE9),
      error: Color(0xFFBA1A1A),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF9FF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFBFF),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFEDE7F4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F0FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6500D9), width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF6500D9),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1E8FF),
      selectedColor: const Color(0xFF6500D9),
      secondarySelectedColor: const Color(0xFF6500D9),
      labelStyle: const TextStyle(color: Color(0xFF3B2458)),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      indicatorColor: const Color(0xFF6500D9),
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFF625A69),
        );
      }),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFB98AFF),
      brightness: Brightness.dark,
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
