import 'package:flutter/material.dart';

import '../../domain/sql/sql_statement_parser.dart';
import '../../domain/sql/sql_syntax_highlighter.dart';

/// A plain SQL editor controller that visually marks the active statement.
class ActiveStatementTextEditingController extends TextEditingController {
  TextRange? _activeRange;
  TextRange? _errorRange;

  void setActiveStatement(SqlStatementRange? statement) {
    var visualEnd = statement?.highlightEnd;
    // Keep this defensive check at the rendering boundary: a statement range
    // may come from a parser version that still ends immediately before `;`.
    if (visualEnd != null &&
        visualEnd < text.length &&
        text[visualEnd] == ';') {
      visualEnd++;
    }
    final nextRange = statement == null || visualEnd == null
        ? null
        : TextRange(start: statement.start, end: visualEnd);
    if (_activeRange == nextRange) return;
    _activeRange = nextRange;
    notifyListeners();
  }

  void setErrorLine(int? lineNumber) {
    final nextRange = _rangeForLine(lineNumber);
    if (_errorRange == nextRange) return;
    _errorRange = nextRange;
  }

  /// The active statement is painted behind the editable selection so a user
  /// selection remains the top-most visual layer.
  TextRange? get activeRange => _validRange(_activeRange);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final errorRange = _validRange(_errorRange);
    final composingRange = withComposing ? _validRange(value.composing) : null;
    final syntaxTokens = SqlSyntaxHighlighter.tokenize(text);
    final offsets = <int>{0, text.length};
    for (final range in [errorRange, composingRange].whereType<TextRange>()) {
      offsets
        ..add(range.start)
        ..add(range.end);
    }
    for (final token in syntaxTokens) {
      offsets
        ..add(token.start)
        ..add(token.end);
    }
    final orderedOffsets = offsets.toList()..sort();
    return TextSpan(
      style: style,
      children: [
        for (var index = 0; index < orderedOffsets.length - 1; index++)
          TextSpan(
            text: text.substring(
              orderedOffsets[index],
              orderedOffsets[index + 1],
            ),
            style: _spanStyle(
              errorRange: errorRange,
              composingRange: composingRange,
              syntaxTokens: syntaxTokens,
              start: orderedOffsets[index],
              end: orderedOffsets[index + 1],
            ),
          ),
      ],
    );
  }

  TextRange? _validRange(TextRange? range) =>
      range == null || range.end > text.length || range.isCollapsed
      ? null
      : range;

  TextStyle? _spanStyle({
    required TextRange? errorRange,
    required TextRange? composingRange,
    required List<SqlSyntaxToken> syntaxTokens,
    required int start,
    required int end,
  }) {
    final syntax = _syntaxStyleFor(syntaxTokens, start, end);
    final background = _overlaps(errorRange, start, end)
        ? const Color(0x33F44336)
        : null;
    final composing = _overlaps(composingRange, start, end);
    if (syntax == null && background == null && !composing) return null;
    return (syntax ?? const TextStyle()).copyWith(
      backgroundColor: background,
      decoration: composing ? TextDecoration.underline : null,
    );
  }

  TextStyle? _syntaxStyleFor(List<SqlSyntaxToken> tokens, int start, int end) {
    for (final token in tokens) {
      if (token.start < end && token.end > start) {
        return switch (token.kind) {
          SqlSyntaxKind.keyword => const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
          SqlSyntaxKind.string => const TextStyle(color: Color(0xFFB45309)),
          SqlSyntaxKind.number => const TextStyle(color: Color(0xFF7C3AED)),
          SqlSyntaxKind.comment => const TextStyle(
            color: Color(0xFF64748B),
            fontStyle: FontStyle.italic,
          ),
          SqlSyntaxKind.identifier => const TextStyle(color: Color(0xFF0F766E)),
        };
      }
    }
    return null;
  }

  bool _overlaps(TextRange? range, int start, int end) =>
      range != null && range.start < end && range.end > start;

  TextRange? _rangeForLine(int? lineNumber) {
    if (lineNumber == null || lineNumber < 1) return null;
    var line = 1;
    var start = 0;
    for (var index = 0; index < text.length; index++) {
      if (line == lineNumber && text[index] == '\n') {
        return TextRange(start: start, end: index);
      }
      if (text[index] == '\n') {
        line++;
        start = index + 1;
      }
    }
    return line == lineNumber
        ? TextRange(start: start, end: text.length)
        : null;
  }
}
