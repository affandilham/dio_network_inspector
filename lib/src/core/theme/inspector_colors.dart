import 'package:flutter/material.dart';

/// Holds the full color palette for a single brightness (light or dark).
class InspectorColorsData {
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color tertiary;

  final Color background;
  final Color surface;
  final Color surfaceDark;

  final Color textPrimary;
  final Color textSecondary;
  final Color textBlueGrey;

  final Color divider;

  final Color success;
  final Color error;
  final Color warning;

  final Color jsonKey;
  final Color jsonString;
  final Color jsonNumber;
  final Color jsonNull;

  const InspectorColorsData({
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.tertiary,
    required this.background,
    required this.surface,
    required this.surfaceDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textBlueGrey,
    required this.divider,
    required this.success,
    required this.error,
    required this.warning,
    required this.jsonKey,
    required this.jsonString,
    required this.jsonNumber,
    required this.jsonNull,
  });
}

class InspectorColors {
  // ─── Light palette ──────────────────────────────────────────────────────────
  static const InspectorColorsData light = InspectorColorsData(
    primary: Color(0xFF2563EB),
    primaryContainer: Color(0xFFEFF6FF),
    secondary: Color(0xFF64748B),
    tertiary: Color(0xFF94A3B8),

    background: Color(0xFFFCFCFC),
    surface: Color(0xFFF8FAFC),
    surfaceDark: Color(0xFFF1F5F9),

    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    textBlueGrey: Color(0xFF64748B),

    divider: Color(0xFFE5E7EB),

    success: Color(0xFF15803D),
    error: Color(0xFFDC2626),
    warning: Color(0xFFB45309),

    jsonKey: Color(0xFF334155),
    jsonString: Color(0xFFB45309),
    jsonNumber: Color(0xFF2563EB),
    jsonNull: Color(0xFF94A3B8),
  );

  // ─── Dark palette ───────────────────────────────────────────────────────────
  static const InspectorColorsData dark = InspectorColorsData(
    primary: Color(0xFF60A5FA),
    primaryContainer: Color(0xFF1E3A5F),
    secondary: Color(0xFF94A3B8),
    tertiary: Color(0xFF64748B),

    background: Color(0xFF1A1D23),
    surface: Color(0xFF21252E),
    surfaceDark: Color(0xFF2A2F3A),

    textPrimary: Color(0xFFE2E8F0),
    textSecondary: Color(0xFF94A3B8),
    textBlueGrey: Color(0xFF8BA5BF),

    divider: Color(0xFF2D3748),

    success: Color(0xFF4ADE80),
    error: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),

    jsonKey: Color(0xFF93C5FD),
    jsonString: Color(0xFFFBBF24),
    jsonNumber: Color(0xFF60A5FA),
    jsonNull: Color(0xFF64748B),
  );

  // ─── Context-aware accessor ──────────────────────────────────────────────────
  /// Returns the appropriate [InspectorColorsData] based on the current
  /// [Theme.of(context).brightness]. Falls back to platform brightness when the
  /// widget tree has no explicit theme ancestor.
  static InspectorColorsData of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }

  // ─── Legacy static helpers (Light values, kept for backward compat) ──────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryContainer = Color(0xFFEFF6FF);
  static const Color secondary = Color(0xFF64748B);
  static const Color tertiary = Color(0xFF94A3B8);

  static const Color background = Color(0xFFFCFCFC);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textBlueGrey = Color(0xFF64748B);

  static const Color divider = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF15803D);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFB45309);

  static const Color jsonKey = Color(0xFF334155);
  static const Color jsonString = Color(0xFFB45309);
  static const Color jsonNumber = Color(0xFF2563EB);
  static const Color jsonNull = Color(0xFF94A3B8);
}
