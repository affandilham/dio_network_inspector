import 'package:dio_network_inspector/src/features/database/domain/database_foreign_key_resolver.dart';
import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefers the declared foreign key for a table result', () {
    final relation = DatabaseForeignKeyResolver.resolve(
      columnName: 'kandang_id',
      selectedTable: 'kandang_projects',
      tables: const [
        DatabaseTable(name: 'kandang_projects'),
        DatabaseTable(name: 'kandangs'),
      ],
      foreignKeys: const [
        DatabaseForeignKey(
          table: 'kandang_projects',
          column: 'kandang_id',
          referencedTable: 'kandangs',
          referencedColumn: 'id',
        ),
      ],
    );

    expect(relation!.referencedTable, 'kandangs');
  });

  test('infers an unambiguous plural table for query result id columns', () {
    final relation = DatabaseForeignKeyResolver.resolve(
      columnName: 'kandang_id',
      selectedTable: null,
      tables: const [DatabaseTable(name: 'kandangs')],
      foreignKeys: const [],
    );

    expect(relation!.referencedTable, 'kandangs');
    expect(relation.referencedColumn, 'id');
  });

  test('accepts same-name query relations that share one target', () {
    final relation = DatabaseForeignKeyResolver.resolve(
      columnName: 'kandang_id',
      selectedTable: null,
      tables: const [DatabaseTable(name: 'kandangs')],
      foreignKeys: const [
        DatabaseForeignKey(
          table: 'kandang_projects',
          column: 'kandang_id',
          referencedTable: 'kandangs',
          referencedColumn: 'id',
        ),
        DatabaseForeignKey(
          table: 'kandang_schedules',
          column: 'kandang_id',
          referencedTable: 'kandangs',
          referencedColumn: 'id',
        ),
      ],
    );

    expect(relation!.referencedTable, 'kandangs');
  });

  test('does not infer a relation when multiple targets are possible', () {
    final relation = DatabaseForeignKeyResolver.resolve(
      columnName: 'user_id',
      selectedTable: null,
      tables: const [
        DatabaseTable(name: 'user'),
        DatabaseTable(name: 'users'),
      ],
      foreignKeys: const [],
    );

    expect(relation, isNull);
  });
}
