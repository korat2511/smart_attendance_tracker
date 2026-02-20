import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Central typography (text styles) for the app.
/// Use with [ThemeData.textTheme] or directly where needed.
abstract class AppTypography {
  AppTypography._();

  static const String _fontFamily = 'Roboto';

  // --- Display ---
  static TextStyle displayLarge({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: fontWeight ?? FontWeight.w700,
        height: height ?? 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle displayMedium({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: height ?? 1.25,
        color: color,
      );

  static TextStyle displaySmall({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: height ?? 1.3,
        color: color,
      );

  // --- Headlines ---
  static TextStyle headlineLarge({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: height ?? 1.3,
        color: color,
      );

  static TextStyle headlineMedium({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: height ?? 1.35,
        color: color,
      );

  static TextStyle headlineSmall({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: height ?? 1.4,
        color: color,
      );

  // --- Title ---
  static TextStyle titleLarge({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: height ?? 1.4,
        letterSpacing: 0.15,
        color: color,
      );

  static TextStyle titleMedium({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: height ?? 1.45,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle titleSmall({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w600,
        height: height ?? 1.5,
        letterSpacing: 0.1,
        color: color,
      );

  // --- Body ---
  static TextStyle bodyLarge({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: height ?? 1.5,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle bodyMedium({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: height ?? 1.45,
        letterSpacing: 0.25,
        color: color,
      );

  static TextStyle bodySmall({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: height ?? 1.5,
        letterSpacing: 0.4,
        color: color,
      );

  // --- Label ---
  static TextStyle labelLarge({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: fontWeight ?? FontWeight.w500,
        height: height ?? 1.4,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w500,
        height: height ?? 1.4,
        letterSpacing: 0.5,
        color: color,
      );

  static TextStyle labelSmall({
    Color? color,
    FontWeight? fontWeight,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: 10,
        fontWeight: fontWeight ?? FontWeight.w500,
        height: height ?? 1.4,
        letterSpacing: 0.5,
        color: color,
      );

  /// Build a full [TextTheme] for light mode (colors applied in theme).
  static TextTheme textThemeLight() => TextTheme(
        displayLarge: displayLarge(color: AppColors.textPrimaryLight),
        displayMedium: displayMedium(color: AppColors.textPrimaryLight),
        displaySmall: displaySmall(color: AppColors.textPrimaryLight),
        headlineLarge: headlineLarge(color: AppColors.textPrimaryLight),
        headlineMedium: headlineMedium(color: AppColors.textPrimaryLight),
        headlineSmall: headlineSmall(color: AppColors.textPrimaryLight),
        titleLarge: titleLarge(color: AppColors.textPrimaryLight),
        titleMedium: titleMedium(color: AppColors.textPrimaryLight),
        titleSmall: titleSmall(color: AppColors.textPrimaryLight),
        bodyLarge: bodyLarge(color: AppColors.textPrimaryLight),
        bodyMedium: bodyMedium(color: AppColors.textPrimaryLight),
        bodySmall: bodySmall(color: AppColors.textSecondaryLight),
        labelLarge: labelLarge(color: AppColors.textPrimaryLight),
        labelMedium: labelMedium(color: AppColors.textSecondaryLight),
        labelSmall: labelSmall(color: AppColors.textSecondaryLight),
      );

  /// Build a full [TextTheme] for dark mode.
  static TextTheme textThemeDark() => TextTheme(
        displayLarge: displayLarge(color: AppColors.textPrimaryDark),
        displayMedium: displayMedium(color: AppColors.textPrimaryDark),
        displaySmall: displaySmall(color: AppColors.textPrimaryDark),
        headlineLarge: headlineLarge(color: AppColors.textPrimaryDark),
        headlineMedium: headlineMedium(color: AppColors.textPrimaryDark),
        headlineSmall: headlineSmall(color: AppColors.textPrimaryDark),
        titleLarge: titleLarge(color: AppColors.textPrimaryDark),
        titleMedium: titleMedium(color: AppColors.textPrimaryDark),
        titleSmall: titleSmall(color: AppColors.textPrimaryDark),
        bodyLarge: bodyLarge(color: AppColors.textPrimaryDark),
        bodyMedium: bodyMedium(color: AppColors.textPrimaryDark),
        bodySmall: bodySmall(color: AppColors.textSecondaryDark),
        labelLarge: labelLarge(color: AppColors.textPrimaryDark),
        labelMedium: labelMedium(color: AppColors.textSecondaryDark),
        labelSmall: labelSmall(color: AppColors.textSecondaryDark),
      );
}
