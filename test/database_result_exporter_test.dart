import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:dio_network_inspector/src/features/database/domain/export/database_result_exporter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const page = DatabasePage(
    columns: [
      DatabaseColumn(name: 'id', type: 'int'),
      DatabaseColumn(name: 'name', type: 'varchar'),
    ],
    rows: [
      {'id': '1', 'name': 'Kevin, "Estre"'},
      {'id': '2', 'name': null},
    ],
    offset: 0,
    limit: 50,
    hasMore: false,
  );

  test('exports loaded rows as RFC-style escaped CSV', () {
    final csv = DatabaseResultExporter.encode(
      page,
      DatabaseResultExportFormat.csv,
    );

    expect(csv, startsWith('\uFEFFsep=,\r\n"id","name"\r\n'));
    expect(csv, contains('"=""1""","=""Kevin, """"Estre"""""""'));
  });

  test('exports loaded rows as JSON while preserving null values', () {
    expect(
      DatabaseResultExporter.encode(page, DatabaseResultExportFormat.json),
      '[\n'
      '  {\n'
      '    "id": "1",\n'
      '    "name": "Kevin, \\"Estre\\""\n'
      '  },\n'
      '  {\n'
      '    "id": "2",\n'
      '    "name": null\n'
      '  }\n'
      ']',
    );
  });
}
