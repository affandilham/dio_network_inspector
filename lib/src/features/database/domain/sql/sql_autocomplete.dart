import 'package:flutter/widgets.dart';

import '../database_models.dart';
import 'sql_autocomplete_context.dart';

enum SqlAutocompleteKind { keyword, table, cte, column }

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
  static const _fallbackKeywords = <DatabaseKeyword>[
    DatabaseKeyword(word: 'SELECT', isReserved: true),
    DatabaseKeyword(word: 'FROM', isReserved: true),
    DatabaseKeyword(word: 'WHERE', isReserved: true),
    DatabaseKeyword(word: 'JOIN', isReserved: true),
    DatabaseKeyword(word: 'LEFT JOIN', isReserved: true),
    DatabaseKeyword(word: 'RIGHT JOIN', isReserved: true),
    DatabaseKeyword(word: 'INNER JOIN', isReserved: true),
    DatabaseKeyword(word: 'ON', isReserved: true),
    DatabaseKeyword(word: 'AS', isReserved: true),
    DatabaseKeyword(word: 'AND', isReserved: true),
    DatabaseKeyword(word: 'OR', isReserved: true),
    DatabaseKeyword(word: 'NOT', isReserved: true),
    DatabaseKeyword(word: 'IN', isReserved: true),
    DatabaseKeyword(word: 'LIKE', isReserved: true),
    DatabaseKeyword(word: 'IS NULL', isReserved: true),
    DatabaseKeyword(word: 'ORDER BY', isReserved: true),
    DatabaseKeyword(word: 'GROUP BY', isReserved: true),
    DatabaseKeyword(word: 'HAVING', isReserved: true),
    DatabaseKeyword(word: 'LIMIT', isReserved: true),
    DatabaseKeyword(word: 'OFFSET', isReserved: true),
    DatabaseKeyword(word: 'DISTINCT', isReserved: true),
    DatabaseKeyword(word: 'COUNT', isReserved: false),
    DatabaseKeyword(word: 'SHOW', isReserved: true),
    DatabaseKeyword(word: 'DESCRIBE', isReserved: true),
    DatabaseKeyword(word: 'EXPLAIN', isReserved: true),
    DatabaseKeyword(word: 'USER', isReserved: false),
    DatabaseKeyword(word: 'USE', isReserved: true),
  ];

  static List<SqlAutocompleteSuggestion> suggestions({
    required TextEditingValue editingValue,
    required List<DatabaseTable> tables,
    required Map<String, List<DatabaseColumn>> columnsByTable,
    List<DatabaseKeyword> keywords = const [],
    int? maximumSuggestions,
  }) {
    final range = _tokenRange(editingValue);
    final token = editingValue.text.substring(range.start, range.end);
    if (token.isEmpty) return const [];

    final dotIndex = token.lastIndexOf('.');
    final qualifier = dotIndex == -1 ? null : token.substring(0, dotIndex);
    final prefix = dotIndex == -1 ? token : token.substring(dotIndex + 1);
    final normalizedPrefix = prefix.toLowerCase();
    final results = <SqlAutocompleteSuggestion>[];

    final context = SqlAutocompleteContext.fromEditor(
      sql: editingValue.text,
      cursorOffset: editingValue.selection.isValid
          ? editingValue.selection.extentOffset.clamp(
              0,
              editingValue.text.length,
            )
          : editingValue.text.length,
      columnsByTable: columnsByTable,
    );

    if (qualifier == null) {
      for (final keyword in keywords.isEmpty ? _fallbackKeywords : keywords) {
        if (_matches(keyword.word, normalizedPrefix)) {
          results.add(
            SqlAutocompleteSuggestion(
              value: keyword.word,
              kind: SqlAutocompleteKind.keyword,
              detail: keyword.isReserved ? 'reserved keyword' : 'keyword',
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
      for (final cte in context.ctes.keys) {
        if (_matches(cte, normalizedPrefix)) {
          results.add(
            SqlAutocompleteSuggestion(
              value: cte,
              kind: SqlAutocompleteKind.cte,
              detail: 'common table expression',
            ),
          );
        }
      }
    }

    final sources = qualifier == null
        ? _columnsForSources(context.primarySources, context)
        : _columnsForQualifier(qualifier, context);
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

    final prefersColumns =
        qualifier != null ||
        (context.primarySources.isNotEmpty &&
            !_isSourceNamePosition(editingValue.text, range.start));
    results.sort((first, second) {
      final kindComparison = _kindPriority(
        first.kind,
        prefersColumns: prefersColumns,
      ).compareTo(_kindPriority(second.kind, prefersColumns: prefersColumns));
      if (kindComparison != 0) return kindComparison;
      final relevanceComparison = _matchScore(
        first.value,
        normalizedPrefix,
      ).compareTo(_matchScore(second.value, normalizedPrefix));
      if (relevanceComparison != 0) return relevanceComparison;
      // A shorter equally-relevant match is normally the intended identifier.
      // For example, `users` precedes `user_balance_projects` for `user`.
      final lengthComparison = first.value.length.compareTo(
        second.value.length,
      );
      if (lengthComparison != 0) return lengthComparison;
      return first.value.compareTo(second.value);
    });
    if (maximumSuggestions == null) {
      return results;
    }
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

  /// Returns the table referenced by the alias currently being typed, if any.
  static String? tableForActiveQualifier(TextEditingValue editingValue) {
    final range = _tokenRange(editingValue);
    final token = editingValue.text.substring(range.start, range.end);
    final dotIndex = token.lastIndexOf('.');
    if (dotIndex < 1) return null;
    final qualifier = token.substring(0, dotIndex);
    final context = SqlAutocompleteContext.fromEditor(
      sql: editingValue.text,
      cursorOffset: editingValue.selection.isValid
          ? editingValue.selection.extentOffset.clamp(
              0,
              editingValue.text.length,
            )
          : editingValue.text.length,
      columnsByTable: const {},
    );
    return context.sourceForQualifier(qualifier);
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
    if (prefix.isEmpty) return false;
    return _matchScore(candidate, prefix) < 3;
  }

  static int _matchScore(String candidate, String prefix) {
    final normalizedCandidate = candidate.toLowerCase();
    if (normalizedCandidate == prefix) return 3;
    if (normalizedCandidate.startsWith(prefix)) return 0;
    final matchIndex = normalizedCandidate.indexOf(prefix);
    if (matchIndex == -1) return 3;
    return _isIdentifierBoundary(candidate, matchIndex) ? 1 : 2;
  }

  static bool _isIdentifierBoundary(String value, int index) {
    if (index == 0) return true;
    final previous = value[index - 1];
    final current = value[index];
    if (!RegExp(r'[A-Za-z0-9]').hasMatch(previous)) return true;
    return previous.toLowerCase() == previous &&
        current.toUpperCase() == current &&
        current.toLowerCase() != current;
  }

  static int _kindPriority(
    SqlAutocompleteKind kind, {
    required bool prefersColumns,
  }) {
    if (prefersColumns) {
      return switch (kind) {
        SqlAutocompleteKind.column => 0,
        SqlAutocompleteKind.cte || SqlAutocompleteKind.table => 1,
        SqlAutocompleteKind.keyword => 2,
      };
    }
    return switch (kind) {
      SqlAutocompleteKind.cte || SqlAutocompleteKind.table => 0,
      SqlAutocompleteKind.keyword => 1,
      SqlAutocompleteKind.column => 2,
    };
  }

  static bool _isSourceNamePosition(String sql, int tokenStart) => RegExp(
    r'\b(?:from|join)\s*$',
    caseSensitive: false,
  ).hasMatch(sql.substring(0, tokenStart));

  static Iterable<MapEntry<String, List<DatabaseColumn>>> _columnsForSources(
    Iterable<String> tables,
    SqlAutocompleteContext context,
  ) sync* {
    for (final table in tables) {
      final columns = context.columnsFor(table);
      if (columns != null) yield MapEntry(table, columns);
    }
  }

  static Iterable<MapEntry<String, List<DatabaseColumn>>> _columnsForQualifier(
    String qualifier,
    SqlAutocompleteContext context,
  ) {
    final columns = context.columnsFor(qualifier);
    final source = context.aliases[qualifier.toLowerCase()] ?? qualifier;
    return columns == null ? const [] : [MapEntry(source, columns)];
  }
}
