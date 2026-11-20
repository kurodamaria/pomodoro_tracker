import 'package:flutter/material.dart';

/// Central theme tokens and `ThemeData` factories for the app.
///
/// Every color used across screens and widgets should come from here so that
/// light and dark themes stay in sync.
class AppTheme {
  const AppTheme._();

  /// Primary accent used for focus/pomodoro moments.
  static const Color brandCrimson = Color(0xFFC94A4A);

  /// Accent for short breaks.
  static const Color breakTeal = Color(0xFF4C9195);

  /// Accent for long breaks.
  static const Color longBreakBlue = Color(0xFF457CA3);

  /// Accent for positive/confirm actions.
  static const Color actionGreen = Color(0xFF4CAF50);

  /// Background used for text inputs in the light theme.
  static const Color lightInputBg = Color(0xFFF5F5F5);

  /// Corner radius for cards and modal surfaces.
  static const double cardRadius = 6.0;

  /// Corner radius for buttons, inputs, chips, and other controls.
  static const double controlRadius = 4.0;

  static const Color _lightDivider = Color(0xFFE0E0E0);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandCrimson,
      brightness: Brightness.light,
    ).copyWith(
      primary: brandCrimson,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      dividerColor: _lightDivider,
      dividerTheme: const DividerThemeData(
        color: _lightDivider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(controlRadius),
            ),
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandCrimson,
      brightness: Brightness.dark,
    ).copyWith(
      primary: brandCrimson,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(controlRadius),
            ),
          ),
        ),
      ),
    );
  }
}
