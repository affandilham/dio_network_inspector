import '../database_models.dart';

/// Conservative guard for the inspector SQL editor.
///
/// A query that cannot be proven read-only is blocked. This is deliberately
/// independent from MySQL permissions: a read-only database user remains the
/// primary protection.
class ReadOnlySqlValidator {
  const ReadOnlySqlValidator._();

  static ReadOnlySqlValidation validate(
    String source, {
    int maximumRows = 100,
  }) {
    if (maximumRows < 1) {
      return const ReadOnlySqlValidation.blocked(
        'The result limit must be greater than zero.',
      );
    }

    final statements = splitStatements(source);
    if (statements.isEmpty) {
      return const ReadOnlySqlValidation.blocked('Enter a SQL statement.');
    }
    if (statements.length != 1) {
      return const ReadOnlySqlValidation.blocked(
        'Only one active SQL statement can run at a time.',
      );
    }

    final statement = statements.single.trim();
    final firstKeyword = _firstKeyword(statement);
    if (firstKeyword == null) {
      return const ReadOnlySqlValidation.blocked('Enter a SQL statement.');
    }

    const allowed = {'select', 'show', 'describe', 'desc', 'explain', 'with'};
    if (!allowed.contains(firstKeyword)) {
      return ReadOnlySqlValidation.blocked(
        '$firstKeyword is not allowed: Database Inspector is read-only.',
      );
    }

    final code = _codeOnly(statement).toLowerCase();
    const blockedPatterns = [
      r'\binsert\b',
      r'\bupdate\b',
      r'\bdelete\b',
      r'\breplace\b',
      r'\bcreate\b',
      r'\balter\b',
      r'\bdrop\b',
      r'\btruncate\b',
      r'\brename\b',
      r'\bgrant\b',
      r'\brevoke\b',
      r'\bset\b',
      r'\buse\b',
      r'\bcall\b',
      r'\bdo\b',
      r'\bload\b',
      r'\bhandler\b',
      r'\binstall\b',
      r'\buninstall\b',
      r'\bkill\b',
      r'\bpurge\b',
      r'\block\b',
      r'\bunlock\b',
      r'\bstart\s+transaction\b',
      r'\bcommit\b',
      r'\brollback\b',
      r'\bsavepoint\b',
      r'\binto\s+(outfile|dumpfile)\b',
      r'\bfor\s+update\b',
      r'\block\s+in\s+share\s+mode\b',
    ];
    for (final pattern in blockedPatterns) {
      if (RegExp(pattern).hasMatch(code)) {
        return const ReadOnlySqlValidation.blocked(
          'This statement can modify data, files, or locks and is disabled.',
        );
      }
    }

    if (firstKeyword == 'with' && !RegExp(r'\bselect\b').hasMatch(code)) {
      return const ReadOnlySqlValidation.blocked(
        'A WITH statement must end in a read-only SELECT.',
      );
    }

    final needsLimit = firstKeyword == 'select' || firstKeyword == 'with';
    if (!needsLimit || RegExp(r'\blimit\b').hasMatch(code)) {
      return ReadOnlySqlValidation.allowed(statement);
    }
    return ReadOnlySqlValidation.allowed('$statement LIMIT $maximumRows');
  }

  /// Splits only on semicolons outside strings, quoted identifiers, and
  /// comments. Empty trailing statements are ignored.
  static List<String> splitStatements(String source) {
    final statements = <String>[];
    final buffer = StringBuffer();
    var index = 0;
    var quote = '';
    var lineComment = false;
    var blockComment = false;

    void commit() {
      final value = buffer.toString().trim();
      if (value.isNotEmpty) statements.add(value);
      buffer.clear();
    }

    while (index < source.length) {
      final char = source[index];
      final next = index + 1 < source.length ? source[index + 1] : '';

      if (lineComment) {
        if (char == '\n') {
          lineComment = false;
          buffer.write(char);
        }
        index++;
        continue;
      }
      if (blockComment) {
        if (char == '*' && next == '/') {
          blockComment = false;
          buffer.write(' ');
          index += 2;
        } else {
          index++;
        }
        continue;
      }
      if (quote.isNotEmpty) {
        buffer.write(char);
        if (char == '\\' && next.isNotEmpty) {
          buffer.write(next);
          index += 2;
          continue;
        }
        if (char == quote) {
          if (next == quote && quote.codeUnitAt(0) != 96) {
            buffer.write(next);
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
        buffer.write(' ');
        index += 2;
        continue;
      }
      if (char == '#') {
        lineComment = true;
        buffer.write(' ');
        index++;
        continue;
      }
      if (char == '/' && next == '*') {
        blockComment = true;
        buffer.write(' ');
        index += 2;
        continue;
      }
      if (char == '\'' || char == '"' || char.codeUnitAt(0) == 96) {
        quote = char;
        buffer.write(char);
        index++;
        continue;
      }
      if (char == ';') {
        commit();
        index++;
        continue;
      }
      buffer.write(char);
      index++;
    }
    commit();
    return statements;
  }

  static String? _firstKeyword(String statement) {
    final match = RegExp(r'^\s*([A-Za-z]+)').firstMatch(statement);
    return match?.group(1)?.toLowerCase();
  }

  static String _codeOnly(String source) {
    var code = splitStatements(source).join(' ');
    code = code.replaceAll(RegExp(r"'(?:\\.|''|[^'])*'"), "''");
    code = code.replaceAll(RegExp(r'"(?:\\.|""|[^"])*"'), '""');
    final identifierQuote = String.fromCharCode(96);
    final quotedIdentifier = RegExp(
      '$identifierQuote[^$identifierQuote]*$identifierQuote',
    );
    return code.replaceAll(quotedIdentifier, ' ');
  }
}
