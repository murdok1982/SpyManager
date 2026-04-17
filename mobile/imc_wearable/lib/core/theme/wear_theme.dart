import 'package:flutter/material.dart';
import 'wear_colors.dart';

class WearTheme {
  WearTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: WearColors.bgBase,
      colorScheme: const ColorScheme.dark(
        primary: WearColors.cyan,
        secondary: WearColors.green,
        error: WearColors.danger,
        surface: WearColors.bgCard,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: WearColors.textPrimary,
          letterSpacing: 1.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: WearColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          color: WearColors.textPrimary,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: WearColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 12,
          color: WearColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
