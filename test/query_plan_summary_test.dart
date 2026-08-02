import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:dio_network_inspector/src/features/database/domain/query_plan_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summarizes MySQL EXPLAIN rows and flags full scans', () {
    const page = DatabasePage(
      columns: [
        DatabaseColumn(name: 'table', type: 'VARCHAR'),
        DatabaseColumn(name: 'type', type: 'VARCHAR'),
        DatabaseColumn(name: 'rows', type: 'BIGINT'),
        DatabaseColumn(name: 'key', type: 'VARCHAR'),
        DatabaseColumn(name: 'Extra', type: 'VARCHAR'),
      ],
      rows: [
        {
          'table': 'users',
          'type': 'ALL',
          'rows': '1200',
          'key': null,
          'Extra': 'Using where',
        },
      ],
      offset: 0,
      limit: 100,
      hasMore: false,
    );

    final summary = DatabaseQueryPlanSummary.tryFrom(page);

    expect(summary?.estimatedRows, 1200);
    expect(summary?.fullTableScans.single.table, 'users');
  });

  test('does not treat an ordinary result as a query plan', () {
    const page = DatabasePage(
      columns: [DatabaseColumn(name: 'id', type: 'BIGINT')],
      rows: [
        {'id': '1'},
      ],
      offset: 0,
      limit: 100,
      hasMore: false,
    );

    expect(DatabaseQueryPlanSummary.tryFrom(page), isNull);
  });
}
