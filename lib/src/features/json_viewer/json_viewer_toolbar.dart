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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InspectorDimensions.spacingM,
        vertical: InspectorDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: InspectorColors.background,
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
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Find in JSON...',
                  hintStyle: InspectorTypography.body.copyWith(
                    color: InspectorColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: InspectorColors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: InspectorDimensions.spacingS,
                    vertical: InspectorDimensions.spacingS,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: const BorderSide(
                      color: InspectorColors.divider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: const BorderSide(
                      color: InspectorColors.divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: const BorderSide(
                      color: InspectorColors.primary,
                    ),
                  ),
                  filled: true,
                  fillColor: InspectorColors.background,
                ),
                style: InspectorTypography.body,
              ),
            ),
          ),
          const SizedBox(width: InspectorDimensions.spacingS),
          if (matchCount > 0)
            BaseText(
              '${currentMatchIndex + 1}/$matchCount',
              color: InspectorColors.textSecondary,
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
          Container(width: 1, height: 16, color: InspectorColors.divider),
          const SizedBox(width: InspectorDimensions.spacingS),
          BaseIconButton(icon: Icons.remove, onPressed: onZoomOut),
          BaseText('${(zoomLevel * 100).toInt()}%'),
          BaseIconButton(icon: Icons.add, onPressed: onZoomIn),
        ],
      ),
    );
  }
}
