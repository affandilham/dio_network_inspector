import 'package:flutter/services.dart';

/// A source range for one non-empty SQL statement in an editor draft.
class SqlStatementRange {
  const SqlStatementRange({
    required this.start,
    required this.end,
    int? highlightEnd,
  }) : highlightEnd = highlightEnd ?? end;

  /// Inclusive start offset in the editor source.
  final int start;

  /// Exclusive end offset in the editor source, before its delimiter.
  final int end;

  /// Exclusive visual end offset. A closing statement delimiter is included
  /// here but deliberately excluded from [sourceFrom].
  final int highlightEnd;

  String sourceFrom(String value) => value.substring(start, end);

  /// Returns the 1-based line where this statement begins in [source].
  int startLineIn(String source) {
    final safeStart = start.clamp(0, source.length);
    return '\n'.allMatches(source.substring(0, safeStart)).length + 1;
  }

  /// A collapsed cursor immediately after a closing delimiter still belongs to
  /// this statement. This makes the visual highlight and Run action remain
  /// available while the caret sits after `;`.
  bool containsCursor(int offset) => offset >= start && offset <= highlightEnd;
}

/// Splits SQL editor text without treating semicolons inside quoted text or
/// comments as delimiters. This is deliberately small and only provides the
/// statement-boundary behaviour required by the read-only inspector.
class SqlStatementParser {
  const SqlStatementParser._();

  static List<SqlStatementRange> statements(String source) {
    final ranges = <SqlStatementRange>[];
    var segmentStart = 0;
    var index = 0;
    var quote = '';
    var lineComment = false;
    var blockComment = false;

    void commit(int delimiterOffset) {
      var start = segmentStart;
      var end = delimiterOffset;
      while (start < end && _isWhitespace(source[start])) {
        start++;
      }
      while (end > start && _isWhitespace(source[end - 1])) {
        end--;
      }
      if (start != end) {
        ranges.add(
          SqlStatementRange(
            start: start,
            end: end,
            highlightEnd: delimiterOffset < source.length
                ? delimiterOffset + 1
                : end,
          ),
        );
      }
      segmentStart = delimiterOffset + 1;
    }

    while (index < source.length) {
      final char = source[index];
      final next = index + 1 < source.length ? source[index + 1] : '';

      if (lineComment) {
        if (char == '\n' || char == '\r') lineComment = false;
        index++;
        continue;
      }
      if (blockComment) {
        if (char == '*' && next == '/') {
          blockComment = false;
          index += 2;
        } else {
          index++;
        }
        continue;
      }
      if (quote.isNotEmpty) {
        if (char == '\\' && next.isNotEmpty) {
          index += 2;
          continue;
        }
        if (char == quote) {
          if (next == quote && quote != '`') {
            index += 2;
            continue;
          }
          quote = '';
        }
        index++;
        continue;
      }

      if (char == '-' && next == '-') {
        lineComment = true;
        index += 2;
        continue;
      }
      if (char == '#') {
        lineComment = true;
        index++;
        continue;
      }
      if (char == '/' && next == '*') {
        blockComment = true;
        index += 2;
        continue;
      }
      if (char == '\'' || char == '"' || char == '`') {
        quote = char;
        index++;
        continue;
      }
      if (char == ';') {
        commit(index);
      }
      index++;
    }
    commit(source.length);
    return ranges;
  }

  static SqlStatementRange? activeStatement(
    String source,
    TextSelection selection,
  ) {
    if (!selection.isValid) return null;
    final cursor = selection.extentOffset.clamp(0, source.length);
    for (final statement in statements(source)) {
      if (statement.containsCursor(cursor)) return statement;
    }
    return null;
  }

  static bool _isWhitespace(String value) => RegExp(r'\s').hasMatch(value);
}
