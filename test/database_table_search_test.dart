import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:dio_network_inspector/src/features/database/domain/database_table_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tables = [
    DatabaseTable(name: 'report_recordings'),
    DatabaseTable(name: 'report_recording_totals'),
    DatabaseTable(name: 'users'),
  ];

  test('matches a case-insensitive substring anywhere in a table name', () {
    final result = DatabaseTableSearch.filter(tables, 'DINGS');

    expect(result.map((table) => table.name), ['report_recordings']);
  });

  test('returns the complete table list for an empty search', () {
    final result = DatabaseTableSearch.filter(tables, '   ');

    expect(
      result.map((table) => table.name),
      tables.map((table) => table.name),
    );
  });
}
