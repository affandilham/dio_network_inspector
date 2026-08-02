enum SqlSyntaxKind { keyword, string, number, comment, identifier }

class SqlSyntaxToken {
  const SqlSyntaxToken({
    required this.start,
    required this.end,
    required this.kind,
  });

  final int start;
  final int end;
  final SqlSyntaxKind kind;
}

/// Small lexer for colouring SQL without attempting to validate or execute it.
class SqlSyntaxHighlighter {
  const SqlSyntaxHighlighter._();

  static const defaultKeywords = <String>{
    'ADD',
    'ALL',
    'ALTER',
    'ANALYZE',
    'AND',
    'AS',
    'ASC',
    'BETWEEN',
    'BY',
    'CASE',
    'CAST',
    'COLLATE',
    'COUNT',
    'CONSTRAINT',
    'CREATE',
    'CROSS',
    'CURRENT_DATE',
    'CURRENT_TIME',
    'CURRENT_TIMESTAMP',
    'DATABASE',
    'DATABASES',
    'ENGINE',
    'DATE',
    'DEFAULT',
    'DELETE',
    'DESC',
    'DESCRIBE',
    'DISTINCT',
    'DROP',
    'ELSE',
    'END',
    'EXISTS',
    'EXPLAIN',
    'FALSE',
    'FETCH',
    'FROM',
    'FULL',
    'GROUP',
    'HAVING',
    'IN',
    'INNER',
    'INSERT',
    'INTERVAL',
    'INTO',
    'IS',
    'JOIN',
    'KEY',
    'AUTO_INCREMENT',
    'CHARACTER',
    'LEFT',
    'LIKE',
    'LIMIT',
    'LOCK',
    'NOT',
    'NULL',
    'OFFSET',
    'ON',
    'OR',
    'ORDER',
    'OUTER',
    'PRIMARY',
    'REFERENCES',
    'RIGHT',
    'SELECT',
    'SET',
    'SHOW',
    'TABLE',
    'TABLES',
    'THEN',
    'TRUE',
    'UNION',
    'UNIQUE',
    'UPDATE',
    'USE',
    'USING',
    'VALUES',
    'VIEW',
    'WHEN',
    'WHERE',
    'WITH',
  };

  static List<SqlSyntaxToken> tokenize(String source) {
    final tokens = <SqlSyntaxToken>[];
    var index = 0;
    while (index < source.length) {
      final character = source[index];
      if (_startsLineComment(source, index)) {
        final end = _lineEnd(source, index + 2);
        tokens.add(
          SqlSyntaxToken(start: index, end: end, kind: SqlSyntaxKind.comment),
        );
        index = end;
      } else if (character == '#') {
        final end = _lineEnd(source, index + 1);
        tokens.add(
          SqlSyntaxToken(start: index, end: end, kind: SqlSyntaxKind.comment),
        );
        index = end;
      } else if (_startsBlockComment(source, index)) {
        final closing = source.indexOf('*/', index + 2);
        final end = closing == -1 ? source.length : closing + 2;
        tokens.add(
          SqlSyntaxToken(start: index, end: end, kind: SqlSyntaxKind.comment),
        );
        index = end;
      } else if (character == '\'' || character == '"') {
        final end = _quotedEnd(source, index, character);
        tokens.add(
          SqlSyntaxToken(start: index, end: end, kind: SqlSyntaxKind.string),
        );
        index = end;
      } else if (character == '`') {
        final end = _quotedEnd(source, index, '`');
        tokens.add(
          SqlSyntaxToken(
            start: index,
            end: end,
            kind: SqlSyntaxKind.identifier,
          ),
        );
        index = end;
      } else if (_isDigit(character)) {
        final end = _numberEnd(source, index);
        tokens.add(
          SqlSyntaxToken(start: index, end: end, kind: SqlSyntaxKind.number),
        );
        index = end;
      } else if (_isWordStart(character)) {
        final end = _wordEnd(source, index);
        final word = source.substring(index, end).toUpperCase();
        if (defaultKeywords.contains(word)) {
          tokens.add(
            SqlSyntaxToken(start: index, end: end, kind: SqlSyntaxKind.keyword),
          );
        }
        index = end;
      } else {
        index++;
      }
    }
    return tokens;
  }

  static bool _startsLineComment(String source, int index) =>
      index + 2 <= source.length &&
      source.substring(index, index + 2) == '--' &&
      (index + 2 == source.length || _isWhitespace(source[index + 2]));

  static bool _startsBlockComment(String source, int index) =>
      index + 2 <= source.length && source.substring(index, index + 2) == '/*';

  static int _lineEnd(String source, int index) {
    final newline = source.indexOf('\n', index);
    return newline == -1 ? source.length : newline;
  }

  static int _quotedEnd(String source, int start, String quote) {
    var index = start + 1;
    while (index < source.length) {
      if (source[index] == '\\') {
        index += 2;
      } else if (source[index] == quote) {
        if (index + 1 < source.length && source[index + 1] == quote) {
          index += 2;
        } else {
          return index + 1;
        }
      } else {
        index++;
      }
    }
    return source.length;
  }

  static int _numberEnd(String source, int start) {
    var index = start;
    while (index < source.length &&
        (_isDigit(source[index]) || source[index] == '.')) {
      index++;
    }
    return index;
  }

  static int _wordEnd(String source, int start) {
    var index = start + 1;
    while (index < source.length && _isWordPart(source[index])) {
      index++;
    }
    return index;
  }

  static bool _isDigit(String value) =>
      value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;
  static bool _isWordStart(String value) =>
      RegExp(r'[A-Za-z_$]').hasMatch(value);
  static bool _isWordPart(String value) =>
      RegExp(r'[A-Za-z0-9_$]').hasMatch(value);
  static bool _isWhitespace(String value) => RegExp(r'\s').hasMatch(value);
}
