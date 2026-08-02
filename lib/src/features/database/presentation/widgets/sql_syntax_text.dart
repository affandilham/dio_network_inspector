import 'package:flutter/material.dart';

import '../../../../core/theme/inspector_colors.dart';
import '../../domain/sql/sql_syntax_highlighter.dart';

/// Builds a syntax-coloured SQL span for read-only inspector surfaces.
TextSpan sqlSyntaxTextSpan(
  String sql, {
  double fontSize = 13,
  double height = 1.5,
}) {
  final tokens = SqlSyntaxHighlighter.tokenize(sql);
  var offset = 0;
  final children = <InlineSpan>[];
  for (final token in tokens) {
    if (offset < token.start) {
      children.add(TextSpan(text: sql.substring(offset, token.start)));
    }
    children.add(
      TextSpan(
        text: sql.substring(token.start, token.end),
        style: switch (token.kind) {
          SqlSyntaxKind.keyword => const TextStyle(
            color: InspectorColors.primary,
            fontWeight: FontWeight.w600,
          ),
          SqlSyntaxKind.string => const TextStyle(
            color: InspectorColors.warning,
          ),
          SqlSyntaxKind.number => const TextStyle(color: Color(0xFF7C3AED)),
          SqlSyntaxKind.comment => const TextStyle(
            color: InspectorColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          SqlSyntaxKind.identifier => const TextStyle(color: Color(0xFF0F766E)),
        },
      ),
    );
    offset = token.end;
  }
  if (offset < sql.length) children.add(TextSpan(text: sql.substring(offset)));
  return TextSpan(
    style: TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: height,
      color: InspectorColors.textPrimary,
    ),
    children: children,
  );
}
