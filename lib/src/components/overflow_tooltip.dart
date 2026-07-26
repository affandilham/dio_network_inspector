import 'package:flutter/material.dart';

/// Shows the full [message] on hover only when its child text is clipped.
class OverflowTooltip extends StatelessWidget {
  final String message;
  final TextStyle? style;
  final int maxLines;
  final Widget child;

  const OverflowTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isOverflowing = _isOverflowing(context, constraints);
        if (!isOverflowing) return child;
        return Tooltip(
          message: message,
          waitDuration: const Duration(milliseconds: 450),
          child: child,
        );
      },
    );
  }

  bool _isOverflowing(BuildContext context, BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return false;
    final textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      maxLines: maxLines,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: constraints.maxWidth);
    return textPainter.didExceedMaxLines;
  }
}
