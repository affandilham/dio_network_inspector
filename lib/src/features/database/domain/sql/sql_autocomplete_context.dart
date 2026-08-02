import 'package:flutter/services.dart';

import '../database_models.dart';
import 'sql_statement_parser.dart';

/// Schema sources visible to autocomplete in the statement at the cursor.
///
/// This is intentionally a lightweight reader, not a SQL validator. It covers
/// table aliases and common table expressions without changing query text.
class SqlAutocompleteContext {
  SqlAutocompleteContext._({
    required this.aliases,
    required this.primarySources,
    required this.ctes,
    required this.columnsByTable,
  });

  final Map<String, String> aliases;
  final List<String> primarySources;
  final Map<String, List<DatabaseColumn>> ctes;
  final Map<String, List<DatabaseColumn>> columnsByTable;

  factory SqlAutocompleteContext.fromEditor({
    required String sql,
    required int cursorOffset,
    required Map<String, List<DatabaseColumn>> columnsByTable,
  }) {
    final statement = SqlStatementParser.activeStatement(
      sql,
      TextSelection.collapsed(offset: cursorOffset),
    );
    final source = statement == null ? sql : statement.sourceFrom(sql);
    final parsedCtes = _parseCtes(source, columnsByTable);
    final query = source.substring(parsedCtes.mainQueryOffset);
    return SqlAutocompleteContext._(
      aliases: _aliasesFor(query),
      primarySources: _sourceNames(query),
      ctes: parsedCtes.columnsByName,
      columnsByTable: columnsByTable,
    );
  }

  List<DatabaseColumn>? columnsFor(String source) {
    final resolved = aliases[source.toLowerCase()] ?? source;
    return _lookup(resolved, ctes) ?? _lookup(resolved, columnsByTable);
  }

  String? sourceForQualifier(String qualifier) {
    final source = aliases[qualifier.toLowerCase()] ?? qualifier;
    return _lookup(source, ctes) == null ? source : null;
  }

  static List<DatabaseColumn>? _lookup(
    String name,
    Map<String, List<DatabaseColumn>> sources,
  ) {
    for (final entry in sources.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
    }
    return null;
  }
}

class _ParsedCtes {
  const _ParsedCtes({
    required this.columnsByName,
    required this.mainQueryOffset,
  });

  final Map<String, List<DatabaseColumn>> columnsByName;
  final int mainQueryOffset;
}

_ParsedCtes _parseCtes(
  String sql,
  Map<String, List<DatabaseColumn>> columnsByTable,
) {
  var index = _skipWhitespace(sql, 0);
  if (!_startsWithWord(sql, index, 'with')) {
    return const _ParsedCtes(columnsByName: {}, mainQueryOffset: 0);
  }
  index = _skipWhitespace(sql, index + 4);
  if (_startsWithWord(sql, index, 'recursive')) {
    index = _skipWhitespace(sql, index + 9);
  }

  final ctes = <String, List<DatabaseColumn>>{};
  while (index < sql.length) {
    final name = _readIdentifier(sql, index);
    if (name == null) break;
    index = _skipWhitespace(sql, name.end);
    final declaredColumns = <String>[];
    if (index < sql.length && sql[index] == '(') {
      final end = _matchingParenthesis(sql, index);
      if (end == null) break;
      declaredColumns.addAll(_identifiersIn(sql.substring(index + 1, end)));
      index = _skipWhitespace(sql, end + 1);
    }
    if (!_startsWithWord(sql, index, 'as')) break;
    index = _skipWhitespace(sql, index + 2);
    if (index >= sql.length || sql[index] != '(') break;
    final end = _matchingParenthesis(sql, index);
    if (end == null) break;
    final projected = _projectedColumns(
      sql.substring(index + 1, end),
      columnsByTable,
      ctes,
    );
    ctes[name.value] = declaredColumns.isEmpty
        ? projected
        : List.generate(
            declaredColumns.length,
            (columnIndex) => DatabaseColumn(
              name: declaredColumns[columnIndex],
              type: columnIndex < projected.length
                  ? projected[columnIndex].type
                  : 'expression',
            ),
          );
    index = _skipWhitespace(sql, end + 1);
    if (index >= sql.length || sql[index] != ',') {
      return _ParsedCtes(columnsByName: ctes, mainQueryOffset: index);
    }
    index = _skipWhitespace(sql, index + 1);
  }
  return _ParsedCtes(columnsByName: ctes, mainQueryOffset: index);
}

List<DatabaseColumn> _projectedColumns(
  String sql,
  Map<String, List<DatabaseColumn>> columnsByTable,
  Map<String, List<DatabaseColumn>> ctes,
) {
  final select = RegExp(r'\bselect\b', caseSensitive: false).firstMatch(sql);
  final from = RegExp(r'\bfrom\b', caseSensitive: false).firstMatch(sql);
  if (select == null || from == null || from.start < select.end) {
    return const [];
  }
  final query = sql.substring(select.end, from.start).trim();
  final source = _sourceNames(sql).firstOrNull;
  final available = source == null
      ? const <DatabaseColumn>[]
      : SqlAutocompleteContext._lookup(source, ctes) ??
            SqlAutocompleteContext._lookup(source, columnsByTable) ??
            const <DatabaseColumn>[];
  final columns = <DatabaseColumn>[];
  for (final expression in _splitTopLevel(query, ',')) {
    final cleaned = expression.trim().replaceFirst(
      RegExp(r'^distinct\s+', caseSensitive: false),
      '',
    );
    if (cleaned == '*') {
      columns.addAll(available);
      continue;
    }
    final outputName = _outputName(cleaned);
    if (outputName == null) continue;
    final sourceName = cleaned
        .replaceFirst(RegExp(r'\s+as\s+[^\s]+$', caseSensitive: false), '')
        .split('.')
        .last
        .replaceAll('`', '')
        .trim();
    final sourceColumn = available.where((column) => column.name == sourceName);
    columns.add(
      DatabaseColumn(
        name: outputName,
        type: sourceColumn.isEmpty ? 'expression' : sourceColumn.first.type,
      ),
    );
  }
  return columns;
}

Map<String, String> _aliasesFor(String sql) {
  final aliases = <String, String>{};
  final pattern = RegExp(
    r'\b(?:from|join)\s+`?([A-Za-z0-9_$]+)`?(?:\s+(?:as\s+)?`?([A-Za-z0-9_$]+)`?)?',
    caseSensitive: false,
  );
  for (final match in pattern.allMatches(sql)) {
    final source = match.group(1);
    final alias = match.group(2);
    if (source != null &&
        alias != null &&
        !_clauseWords.contains(alias.toLowerCase())) {
      aliases[alias.toLowerCase()] = source;
    }
  }
  return aliases;
}

List<String> _sourceNames(String sql) {
  final names = <String>[];
  final pattern = RegExp(
    r'\bfrom\s+`?([A-Za-z0-9_$]+)`?',
    caseSensitive: false,
  );
  for (final match in pattern.allMatches(sql)) {
    final name = match.group(1);
    if (name != null &&
        !names.any((item) => item.toLowerCase() == name.toLowerCase())) {
      names.add(name);
    }
  }
  return names;
}

const _clauseWords = {
  'where',
  'join',
  'left',
  'right',
  'inner',
  'outer',
  'cross',
  'on',
  'group',
  'order',
  'limit',
  'having',
  'union',
  'offset',
  'for',
  'use',
};

class _Identifier {
  const _Identifier(this.value, this.end);
  final String value;
  final int end;
}

_Identifier? _readIdentifier(String source, int start) {
  if (start >= source.length) return null;
  if (source[start] == '`') {
    final end = source.indexOf('`', start + 1);
    return end == -1
        ? null
        : _Identifier(source.substring(start + 1, end), end + 1);
  }
  final match = RegExp(
    r'[A-Za-z_$][A-Za-z0-9_$]*',
  ).matchAsPrefix(source, start);
  return match == null ? null : _Identifier(match.group(0)!, match.end);
}

List<String> _identifiersIn(String source) => RegExp(
  r'`?([A-Za-z_$][A-Za-z0-9_$]*)`?',
).allMatches(source).map((match) => match.group(1)!).toList(growable: false);

String? _outputName(String expression) {
  final alias = RegExp(
    r'\s+as\s+`?([A-Za-z_$][A-Za-z0-9_$]*)`?$',
    caseSensitive: false,
  ).firstMatch(expression);
  if (alias != null) return alias.group(1);
  final identifier = RegExp(
    r'`?([A-Za-z_$][A-Za-z0-9_$]*)`?$',
  ).firstMatch(expression);
  return identifier?.group(1);
}

int _skipWhitespace(String source, int index) {
  while (index < source.length && RegExp(r'\s').hasMatch(source[index])) {
    index++;
  }
  return index;
}

bool _startsWithWord(String source, int index, String word) {
  final end = index + word.length;
  if (end > source.length ||
      source.substring(index, end).toLowerCase() != word) {
    return false;
  }
  return end == source.length ||
      !RegExp(r'[A-Za-z0-9_$]').hasMatch(source[end]);
}

int? _matchingParenthesis(String source, int start) {
  var depth = 0;
  var quote = '';
  for (var index = start; index < source.length; index++) {
    final char = source[index];
    if (quote.isNotEmpty) {
      if (char == '\\') {
        index++;
      } else if (char == quote) {
        quote = '';
      }
      continue;
    }
    if (char == '\'' || char == '"' || char == '`') {
      quote = char;
    } else if (char == '(') {
      depth++;
    } else if (char == ')' && --depth == 0) {
      return index;
    }
  }
  return null;
}

List<String> _splitTopLevel(String source, String separator) {
  final parts = <String>[];
  var start = 0;
  var depth = 0;
  for (var index = 0; index < source.length; index++) {
    if (source[index] == '(') depth++;
    if (source[index] == ')') depth--;
    if (source[index] == separator && depth == 0) {
      parts.add(source.substring(start, index));
      start = index + 1;
    }
  }
  parts.add(source.substring(start));
  return parts;
}

extension on Iterable<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
