import 'package:flutter/material.dart';
import '../core/theme/inspector_colors.dart';
import '../core/theme/inspector_dimensions.dart';

class BaseIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  const BaseIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = InspectorDimensions.iconM,
    this.tooltip,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve color: explicit prop > theme-aware default.
    final effectiveColor = color ?? InspectorColors.of(context).textBlueGrey;
    return IconButton(
      icon: Icon(icon, color: effectiveColor, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 16,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: padding,
    );
  }
}
