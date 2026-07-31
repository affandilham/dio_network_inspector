import 'package:flutter/material.dart';
import 'base_text.dart';
import '../core/theme/inspector_typography.dart';
import '../core/theme/inspector_colors.dart';
import '../core/theme/inspector_dimensions.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = InspectorColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: InspectorDimensions.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: BaseText(
              label,
              style: InspectorTypography.body.copyWith(fontWeight: FontWeight.w600),
              color: colors.textSecondary,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: InspectorTypography.body.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
