import 'package:flutter/material.dart';
import 'inspector_colors.dart';

class InspectorTypography {
  static const String fontFamilyMenlo = 'Menlo';
  static const List<String> fontFamilyFallback = [
    'Consolas',
    'Courier New',
    'monospace',
  ];

  static const TextStyle title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: InspectorColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: InspectorColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: InspectorColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: InspectorColors.textSecondary,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: fontFamilyMenlo,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
  );
}
