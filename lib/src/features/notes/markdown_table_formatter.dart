/// Normalises a Markdown table into a readable, consistently aligned form.
///
/// The function accepts a complete table block and returns `null` when the
/// selection is not a table. A missing delimiter row is added after the first
/// row, matching the table format emitted by GitLab's editor.
String? formatMarkdownTableBlock(String source) {
  final hasTrailingNewline = source.endsWith('\n');
  final rawLines = source.split('\n');
  if (hasTrailingNewline) rawLines.removeLast();

  if (rawLines.length < 2 || rawLines.any((line) => !_isTableLine(line))) {
    return null;
  }

  final rows = rawLines.map(_cellsForLine).toList();
  final columnCount = rows.fold<int>(
    0,
    (count, row) => count > row.length ? count : row.length,
  );
  if (columnCount == 0) return null;

  for (final row in rows) {
    row.addAll(List<String>.filled(columnCount - row.length, ''));
  }

  var dividerIndex = rows.indexWhere((row) => row.every(_isDelimiterCell));
  if (dividerIndex == -1) {
    rows.insert(1, List<String>.filled(columnCount, '---'));
    dividerIndex = 1;
  }

  final widths = List<int>.filled(columnCount, 3);
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    if (rowIndex == dividerIndex) continue;
    for (var column = 0; column < columnCount; column++) {
      widths[column] = widths[column] > rows[rowIndex][column].length
          ? widths[column]
          : rows[rowIndex][column].length;
    }
  }

  final formattedRows = <String>[];
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    final cells = <String>[];
    for (var column = 0; column < columnCount; column++) {
      final value = row[column];
      cells.add(
        rowIndex == dividerIndex
            ? _formatDelimiter(value, widths[column])
            : value.padRight(widths[column]),
      );
    }
    formattedRows.add('| ${cells.join(' | ')} |');
  }

  return '${formattedRows.join('\n')}${hasTrailingNewline ? '\n' : ''}';
}

bool _isTableLine(String line) => line.trim().contains('|');

List<String> _cellsForLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var escaped = false;

  for (final rune in line.runes) {
    final character = String.fromCharCode(rune);
    if (escaped) {
      buffer.write(character);
      escaped = false;
    } else if (character == '\\') {
      buffer.write(character);
      escaped = true;
    } else if (character == '|') {
      cells.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(character);
    }
  }
  cells.add(buffer.toString().trim());

  if (line.trimLeft().startsWith('|') && cells.isNotEmpty) cells.removeAt(0);
  if (line.trimRight().endsWith('|') && cells.isNotEmpty) cells.removeLast();
  return cells;
}

bool _isDelimiterCell(String cell) => RegExp(r'^:?-+:?$').hasMatch(cell.trim());

String _formatDelimiter(String source, int width) {
  final trimmed = source.trim();
  final alignLeft = trimmed.startsWith(':');
  final alignRight = trimmed.endsWith(':');
  final colonCount = (alignLeft ? 1 : 0) + (alignRight ? 1 : 0);
  final dashCount = width - colonCount < 3 ? 3 : width - colonCount;
  return '${alignLeft ? ':' : ''}${'-' * dashCount}${alignRight ? ':' : ''}';
}
