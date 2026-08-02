import 'package:flutter/services.dart';

import '../../domain/sql/sql_statement_parser.dart';

/// Inserts a history query without overwriting the current editor draft.
class DatabaseQueryHistoryInserter {
  const DatabaseQueryHistoryInserter._();

  static TextEditingValue insert(
    TextEditingValue current, {
    required String historySql,
  }) {
    final sql = _withClosingDelimiter(historySql);
    if (sql.isEmpty) return current;
    return _selectionOverlapsStatement(current)
        ? _append(current, sql)
        : _insertAtFocus(current, sql);
  }

  static bool _selectionOverlapsStatement(TextEditingValue current) {
    final selection = current.selection;
    if (!selection.isValid) return false;
    final start = selection.start.clamp(0, current.text.length);
    final end = selection.end.clamp(0, current.text.length);
    for (final statement in SqlStatementParser.statements(current.text)) {
      if (selection.isCollapsed) {
        if (statement.containsCursor(start)) return true;
      } else if (statement.start < end && statement.end > start) {
        return true;
      }
    }
    return false;
  }

  static TextEditingValue _append(TextEditingValue current, String sql) {
    final source = current.text;
    final trimmedSource = source.trimRight();
    final needsDelimiter =
        trimmedSource.isNotEmpty && !trimmedSource.endsWith(';');
    final separator = trimmedSource.isEmpty
        ? ''
        : needsDelimiter
        ? ';\n\n'
        : '\n\n';
    final text = '$trimmedSource$separator$sql';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  static TextEditingValue _insertAtFocus(TextEditingValue current, String sql) {
    final source = current.text;
    final offset = current.selection.isValid
        ? current.selection.start.clamp(0, source.length)
        : source.length;
    final before = source.substring(0, offset);
    final after = source.substring(offset);
    final prefix = _needsLineBreakBefore(before) ? '\n' : '';
    final suffix = _needsLineBreakAfter(after) ? '\n' : '';
    final text = '$before$prefix$sql$suffix$after';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: offset + prefix.length + sql.length,
      ),
    );
  }

  static bool _needsLineBreakBefore(String value) =>
      value.isNotEmpty && !RegExp(r'\s$').hasMatch(value);

  static bool _needsLineBreakAfter(String value) =>
      value.isNotEmpty && !RegExp(r'^\s').hasMatch(value);

  /// Saved/history entries become complete editor statements when inserted.
  ///
  /// Existing delimiters are preserved; missing ones are added so the active
  /// statement highlight and subsequent SQL can be separated reliably.
  static String _withClosingDelimiter(String value) {
    final sql = value.trim();
    if (sql.isEmpty || sql.endsWith(';')) return sql;
    return '$sql;';
  }
}
