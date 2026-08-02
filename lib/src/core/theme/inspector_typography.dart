import 'package:flutter/material.dart';

/// Defines standard typography styles for dio_network_inspector.
/// Colors are deliberately omitted here so text components (like [BaseText])
/// and theme hierarchies can dynamically resolve colors based on dark/light mode context.
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
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: fontFamilyMenlo,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
  );
}
