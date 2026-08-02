import 'package:flutter/material.dart';
import '../core/theme/inspector_colors.dart';
import '../core/theme/inspector_typography.dart';

class BaseText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isMono;
  final Color? color;

  const BaseText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.isMono = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = InspectorColors.of(context);
    TextStyle baseStyle = isMono ? InspectorTypography.mono : InspectorTypography.body;

    // Resolve effective color: explicit prop > theme-aware default.
    final effectiveColor = color ?? (isMono ? null : colors.textPrimary);
    if (effectiveColor != null) {
      baseStyle = baseStyle.copyWith(color: effectiveColor);
    }

    if (style != null) {
      baseStyle = baseStyle.merge(style);
    }

    return Text(
      text,
      style: baseStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
