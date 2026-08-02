import 'dart:convert';

import '../database_models.dart';

enum DatabaseResultExportFormat { csv, json }

/// Serializes the already-loaded result page without issuing another query.
class DatabaseResultExporter {
  const DatabaseResultExporter._();

  static String encode(DatabasePage page, DatabaseResultExportFormat format) =>
      switch (format) {
        DatabaseResultExportFormat.csv => _encodeCsv(page),
        DatabaseResultExportFormat.json => _encodeJson(page),
      };

  static String extensionFor(DatabaseResultExportFormat format) =>
      switch (format) {
        DatabaseResultExportFormat.csv => 'csv',
        DatabaseResultExportFormat.json => 'json',
      };

  static String mimeTypeFor(DatabaseResultExportFormat format) =>
      switch (format) {
        DatabaseResultExportFormat.csv => 'text/csv',
        DatabaseResultExportFormat.json => 'application/json',
      };

  static String _encodeCsv(DatabasePage page) {
    final lines = <String>[
      // Excel follows the macOS locale separator unless this directive is
      // present, which would otherwise place an entire comma-delimited row in
      // column A for locales that expect semicolons.
      'sep=,',
      page.columns.map((column) => _csvField(column.name)).join(','),
      ...page.rows.map(
        (row) => page.columns
            .map((column) => _excelTextField(row[column.name] ?? ''))
            .join(','),
      ),
    ];
    return '\uFEFF${lines.join('\r\n')}';
  }

  static String _encodeJson(DatabasePage page) =>
      const JsonEncoder.withIndent('  ').convert([
        for (final row in page.rows)
          {for (final column in page.columns) column.name: row[column.name]},
      ]);

  static String _csvField(String value) => '"${value.replaceAll('"', '""')}"';

  /// Excel otherwise interprets decimal dots using the current macOS locale.
  /// A string-literal formula retains the exact value, while doubling quotes
  /// keeps database text inside that literal and prevents formula injection.
  static String _excelTextField(String value) =>
      _csvField('="${value.replaceAll('"', '""')}"');
}
