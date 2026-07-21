import 'package:flutter/material.dart';
import '../core/theme/inspector_dimensions.dart';
import '../core/theme/inspector_colors.dart';

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
    this.color = InspectorColors.textBlueGrey,
    this.size = InspectorDimensions.iconM,
    this.tooltip,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 16,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: padding,
    );
  }
}
