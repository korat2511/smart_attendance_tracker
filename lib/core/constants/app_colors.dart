import 'package:flutter/material.dart';

/// Central color constants for the Smart Attendance Tracker app.
/// Use these with [AppTheme] for light/dark variants where applicable.
abstract class AppColors {
  AppColors._();

  // --- Brand & Primary ---
  /// Primary Blue - Modern, Google-style (buttons, links, primary actions)
  static const Color primaryBlue = Color(0xFF1A73E8);

  /// Primary Blue light (hover, pressed states)
  static const Color primaryBlueLight = Color(0xFF4285F4);

  /// Primary Blue dark (darker shade for contrast)
  static const Color primaryBlueDark = Color(0xFF1557B0);

  // --- Secondary / Slate ---
  /// Secondary Slate - Text and icons
  static const Color secondarySlate = Color(0xFF455A64);

  /// Slate light (muted text)
  static const Color slateLight = Color(0xFF607D8B);

  /// Slate dark (emphasis text)
  static const Color slateDark = Color(0xFF37474F);

  // --- Status (Attendance) ---
  /// Success Green - "Present" markings
  static const Color successGreen = Color(0xFF2E7D32);

  /// Success Green light
  static const Color successGreenLight = Color(0xFF4CAF50);

  /// Warning Red - "Absent" markings
  static const Color warningRed = Color(0xFFD32F2F);

  /// Warning Red light (late / partial)
  static const Color warningRedLight = Color(0xFFE53935);

  /// Info / Pending - "On Leave" or pending status
  static const Color infoBlue = Color(0xFF1976D2);

  /// Neutral / Unmarked
  static const Color neutralGrey = Color(0xFF757575);

  // --- Backgrounds (Light theme) ---
  /// Clean off-white background
  static const Color backgroundLight = Color(0xFFF8F9FA);

  /// Surface (cards, dialogs)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Surface variant (e.g. list tile background)
  static const Color surfaceVariantLight = Color(0xFFF1F3F4);

  // --- Backgrounds (Dark theme) ---
  static const Color backgroundDark = Color(0xFF121212);

  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color surfaceVariantDark = Color(0xFF2C2C2C);

  // --- Text ---
  static const Color textPrimaryLight = Color(0xFF202124);

  static const Color textSecondaryLight = Color(0xFF5F6368);

  static const Color textPrimaryDark = Color(0xFFE8EAED);

  static const Color textSecondaryDark = Color(0xFF9AA0A6);

  // --- Borders & Dividers ---
  static const Color borderLight = Color(0xFFDADCE0);

  static const Color borderDark = Color(0xFF3C4043);

  // --- Other ---
  static const Color error = Color(0xFFB00020);

  static const Color disabledLight = Color(0xFFBDBDBD);

  static const Color disabledDark = Color(0xFF5F6368);

  /// Splash / overlay
  static const Color splashLight = Color(0x1A1A73E8);

  static const Color splashDark = Color(0x331A73E8);
}
