import 'package:flutter/material.dart';

class InspectorTypography {
  static const String fontFamilyMenlo = 'Menlo';
  static const List<String> fontFamilyFallback = ['Consolas', 'Courier New', 'monospace'];

  static const TextStyle title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle body = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );
  
  static const TextStyle mono = TextStyle(
    fontFamily: fontFamilyMenlo,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
  );
}
