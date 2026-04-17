import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.robotoMono(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 2.0,
      );

  static TextStyle get headlineMedium => GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get titleMedium => GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      );

  static TextStyle get labelSmall => GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 1.5,
      );

  // Monospace styles for operational data
  static TextStyle get monoLarge => GoogleFonts.robotoMono(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.accentCyan,
        letterSpacing: 1.5,
      );

  static TextStyle get monoMedium => GoogleFonts.robotoMono(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.accentCyan,
        letterSpacing: 1.0,
      );

  static TextStyle get monoSmall => GoogleFonts.robotoMono(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle get classified => GoogleFonts.robotoMono(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppColors.topSecret,
        letterSpacing: 2.0,
      );
}
