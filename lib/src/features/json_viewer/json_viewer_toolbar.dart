import 'package:flutter/material.dart';
import '../../components/base_text.dart';
import '../../components/base_icon_button.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import '../../core/theme/inspector_colors.dart';

class JsonViewerToolbarWidget extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final int matchCount;
  final int currentMatchIndex;
  final VoidCallback onPrevMatch;
  final VoidCallback onNextMatch;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final double zoomLevel;
  final bool hasShadow;

  const JsonViewerToolbarWidget({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.matchCount,
    required this.currentMatchIndex,
    required this.onPrevMatch,
    required this.onNextMatch,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.zoomLevel,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = InspectorColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InspectorDimensions.spacingM,
        vertical: InspectorDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: InspectorTypography.body.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Find in JSON...',
                  hintStyle: InspectorTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: InspectorDimensions.spacingS,
                    vertical: InspectorDimensions.spacingS,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: BorderSide(
                      color: colors.divider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: BorderSide(
                      color: colors.divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: BorderSide(
                      color: colors.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: colors.background,
                ),
              ),
            ),
          ),
          const SizedBox(width: InspectorDimensions.spacingS),
          if (matchCount > 0)
            BaseText(
              '${currentMatchIndex + 1}/$matchCount',
              color: colors.textSecondary,
            ),
          BaseIconButton(
            icon: Icons.keyboard_arrow_up,
            onPressed: matchCount == 0 ? null : onPrevMatch,
          ),
          BaseIconButton(
            icon: Icons.keyboard_arrow_down,
            onPressed: matchCount == 0 ? null : onNextMatch,
          ),
          const SizedBox(width: InspectorDimensions.spacingS),
          Container(width: 1, height: 16, color: colors.divider),
          const SizedBox(width: InspectorDimensions.spacingS),
          BaseIconButton(icon: Icons.remove, onPressed: onZoomOut),
          BaseText('${(zoomLevel * 100).toInt()}%'),
          BaseIconButton(icon: Icons.add, onPressed: onZoomIn),
        ],
      ),
    );
  }
}
