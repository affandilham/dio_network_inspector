/// Extracts a 1-based SQL line number from common MySQL error messages.
class SqlErrorLine {
  const SqlErrorLine._();

  static int? fromMessage(String? message) {
    if (message == null) return null;
    final match = RegExp(
      r'\bat\s+line\s+(\d+)\b',
      caseSensitive: false,
    ).firstMatch(message);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Converts MySQL's statement-relative line number to an editor line.
  static int? editorLine({
    required String? message,
    required int statementStartLine,
  }) {
    final statementLine = fromMessage(message);
    if (statementLine == null || statementStartLine < 1) return null;
    return statementStartLine + statementLine - 1;
  }
}
