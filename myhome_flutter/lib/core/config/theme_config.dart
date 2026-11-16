import 'package:flutter/material.dart';

class ThemeConfig {
  static const teal = Color(0xFF28545D);
  static ThemeData lightTheme({double viewportWidth = 390}) =>
      _theme(Brightness.light, viewportWidth);
  static ThemeData darkTheme({double viewportWidth = 390}) =>
      _theme(Brightness.dark, viewportWidth);
  static ThemeData _theme(Brightness brightness, double viewportWidth) {
    final dark = brightness == Brightness.dark;
    final wide = viewportWidth >= 1100;
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: brightness,
      primary: dark ? const Color(0xFF9BD2D5) : teal,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.typography.englishLike
        .merge(base.textTheme)
        .apply(fontSizeFactor: wide ? 1.18 : 1.06);
    final buttonSize = Size(0, wide ? 64 : 56);
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: wide ? 28 : 20,
      vertical: 16,
    );
    final buttonText = text.labelLarge!.copyWith(
      fontSize: wide ? 18 : 16,
      fontWeight: FontWeight.w600,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      iconTheme: IconThemeData(size: wide ? 28 : 24, color: scheme.onSurface),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        toolbarHeight: wide ? 80 : 68,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1C2A2F) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          textStyle: buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          textStyle: buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      chipTheme: base.chipTheme.copyWith(
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: text.labelLarge,
      ),
      listTileTheme: ListTileThemeData(minVerticalPadding: wide ? 16 : 12),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? scheme.surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
        ),
      ),
    );
  }
}
