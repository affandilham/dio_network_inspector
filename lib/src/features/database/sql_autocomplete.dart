import 'package:flutter/widgets.dart';

import 'database_models.dart';

enum SqlAutocompleteKind { keyword, table, column }

class SqlAutocompleteSuggestion {
  const SqlAutocompleteSuggestion({
    required this.value,
    required this.kind,
    this.detail,
  });

  final String value;
  final SqlAutocompleteKind kind;
  final String? detail;
}

/// Lightweight, session-only suggestions that never query MySQL while typing.
class SqlAutocomplete {
  static const _keywords = <String>[
    'SELECT',
    'FROM',
    'WHERE',
    'JOIN',
    'LEFT JOIN',
    'RIGHT JOIN',
    'INNER JOIN',
    'ON',
    'AS',
    'AND',
    'OR',
    'NOT',
    'IN',
    'LIKE',
    'IS NULL',
    'ORDER BY',
    'GROUP BY',
    'HAVING',
    'LIMIT',
    'OFFSET',
    'DISTINCT',
    'COUNT',
    'SHOW',
    'DESCRIBE',
    'EXPLAIN',
    'USER',
    'USE',
  ];

  static List<SqlAutocompleteSuggestion> suggestions({
    required TextEditingValue editingValue,
    required List<DatabaseTable> tables,
    required Map<String, List<DatabaseColumn>> columnsByTable,
    int maximumSuggestions = 8,
  }) {
    final range = _tokenRange(editingValue);
    final token = editingValue.text.substring(range.start, range.end);
    if (token.isEmpty) return const [];

    final dotIndex = token.lastIndexOf('.');
    final qualifier = dotIndex == -1 ? null : token.substring(0, dotIndex);
    final prefix = dotIndex == -1 ? token : token.substring(dotIndex + 1);
    final normalizedPrefix = prefix.toLowerCase();
    final results = <SqlAutocompleteSuggestion>[];

    if (qualifier == null) {
      for (final keyword in _keywords) {
        if (_matches(keyword, normalizedPrefix)) {
          results.add(
            SqlAutocompleteSuggestion(
              value: keyword,
              kind: SqlAutocompleteKind.keyword,
              detail: 'keyword',
            ),
          );
        }
      }
      for (final table in tables) {
        if (_matches(table.name, normalizedPrefix)) {
          results.add(
            SqlAutocompleteSuggestion(
              value: table.name,
              kind: SqlAutocompleteKind.table,
              detail: 'table',
            ),
          );
        }
      }
    }

    final aliases = _tableAliases(editingValue.text);
    final sources = qualifier == null
        ? columnsByTable.entries
        : _columnsForQualifier(qualifier, aliases, columnsByTable);
    for (final source in sources) {
      for (final column in source.value) {
        if (_matches(column.name, normalizedPrefix)) {
          results.add(
            SqlAutocompleteSuggestion(
              value: qualifier == null
                  ? column.name
                  : '$qualifier.${column.name}',
              kind: SqlAutocompleteKind.column,
              detail: '${source.key}.${column.type}',
            ),
          );
        }
      }
    }

    results.sort((first, second) {
      final firstExact = first.value.toLowerCase() == token.toLowerCase();
      final secondExact = second.value.toLowerCase() == token.toLowerCase();
      if (firstExact != secondExact) return firstExact ? 1 : -1;
      return first.value.compareTo(second.value);
    });
    return results.take(maximumSuggestions).toList(growable: false);
  }

  static TextEditingValue applySuggestion({
    required TextEditingValue editingValue,
    required String value,
  }) {
    final range = _tokenRange(editingValue);
    final text = editingValue.text.replaceRange(range.start, range.end, value);
    final cursor = range.start + value.length;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  static TextRange _tokenRange(TextEditingValue editingValue) {
    final text = editingValue.text;
    final cursor = editingValue.selection.isValid
        ? editingValue.selection.baseOffset.clamp(0, text.length)
        : text.length;
    var start = cursor;
    while (start > 0 && _isTokenCharacter(text[start - 1])) {
      start--;
    }
    var end = cursor;
    while (end < text.length && _isTokenCharacter(text[end])) {
      end++;
    }
    return TextRange(start: start, end: end);
  }

  static bool _isTokenCharacter(String character) =>
      RegExp(r'[A-Za-z0-9_.$]').hasMatch(character);

  static bool _matches(String candidate, String prefix) {
    final normalizedCandidate = candidate.toLowerCase();
    return normalizedCandidate.startsWith(prefix) &&
        normalizedCandidate != prefix;
  }

  static Map<String, String> _tableAliases(String sql) {
    final matches = RegExp(
      r'\b(?:from|join)\s+([A-Za-z0-9_$]+)(?:\s+(?:as\s+)?([A-Za-z0-9_$]+))?',
      caseSensitive: false,
    ).allMatches(sql);
    final aliases = <String, String>{};
    for (final match in matches) {
      final table = match.group(1);
      final alias = match.group(2);
      if (table != null && alias != null) aliases[alias.toLowerCase()] = table;
    }
    return aliases;
  }

  static Iterable<MapEntry<String, List<DatabaseColumn>>> _columnsForQualifier(
    String qualifier,
    Map<String, String> aliases,
    Map<String, List<DatabaseColumn>> columnsByTable,
  ) {
    final table = aliases[qualifier.toLowerCase()] ?? qualifier;
    final columns = columnsByTable[table];
    return columns == null ? const [] : [MapEntry(table, columns)];
  }
}
