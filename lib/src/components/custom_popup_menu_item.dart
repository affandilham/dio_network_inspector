import 'package:flutter/material.dart';
import '../core/theme/inspector_colors.dart';
import '../core/theme/inspector_dimensions.dart';
import '../core/theme/inspector_typography.dart';
import 'base_text.dart';

class CustomPopupMenuItem<T> extends PopupMenuEntry<T> {
  final T value;
  final String text;
  final IconData? icon;
  final bool isSelected;

  const CustomPopupMenuItem({
    super.key,
    required this.value,
    required this.text,
    this.icon,
    this.isSelected = false,
  });

  @override
  double get height => 32.0;

  @override
  bool represents(T? value) => this.value == value;

  @override
  State<CustomPopupMenuItem<T>> createState() => _CustomPopupMenuItemState<T>();
}

class _CustomPopupMenuItemState<T> extends State<CustomPopupMenuItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = InspectorColors.of(context);
    final primaryColor = theme.colorScheme.primary;
    final hoverBgColor = theme.colorScheme.primaryContainer;

    final textColor = widget.isSelected
        ? primaryColor
        : (_isHovered ? primaryColor : colors.textPrimary);

    final iconColor = widget.isSelected
        ? primaryColor
        : (_isHovered ? primaryColor : colors.textBlueGrey);

    final bgColor = _isHovered
        ? hoverBgColor
        : Colors.transparent;

    return InkWell(
      onTap: () => Navigator.of(context).pop(widget.value),
      onHover: (value) => setState(() => _isHovered = value),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: InspectorDimensions.spacingXs,
            vertical: 2.0),
        padding: const EdgeInsets.symmetric(
            horizontal: InspectorDimensions.spacingS,
            vertical: 6.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(InspectorDimensions.radiusM),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: InspectorDimensions.iconM,
                color: iconColor,
              ),
              const SizedBox(width: InspectorDimensions.spacingS),
            ],
            BaseText(
              widget.text,
              style: InspectorTypography.body.copyWith(
                fontWeight: (_isHovered || widget.isSelected)
                    ? FontWeight.w600 : FontWeight.w500,
              ),
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}
