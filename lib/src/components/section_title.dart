import 'package:flutter/material.dart';
import 'base_text.dart';
import '../core/theme/inspector_typography.dart';
import '../core/theme/inspector_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const SectionTitle(
    this.title, {
    super.key,
    this.color = InspectorColors.textPrimary,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: BaseText(
        title,
        style: InspectorTypography.sectionTitle,
        color: color,
      ),
    );
  }
}
