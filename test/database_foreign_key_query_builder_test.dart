import 'package:dio_network_inspector/src/features/database/domain/database_foreign_key_query_builder.dart';
import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const relationA = DatabaseForeignKey(
    table: 'order_lines',
    column: 'company_id',
    referencedTable: 'companies',
    referencedColumn: 'id',
    constraintName: 'order_lines_company_code_fk',
    ordinalPosition: 1,
  );
  const relationB = DatabaseForeignKey(
    table: 'order_lines',
    column: 'company_code',
    referencedTable: 'companies',
    referencedColumn: 'code',
    constraintName: 'order_lines_company_code_fk',
    ordinalPosition: 2,
  );
  const relations = [relationA, relationB];

  test('builds every predicate for a composite foreign-key lookup', () {
    final sql = DatabaseForeignKeyQueryBuilder.relatedSql(
      relation: relationB,
      allRelations: relations,
      row: const {'company_id': '42', 'company_code': "owner'\\code"},
      limit: 50,
    );

    expect(
      sql,
      "SELECT * FROM `companies` WHERE `id` = '42' AND `code` = "
      "'owner\\'\\\\code' LIMIT 50;",
    );
  });

  test('does not build a partial composite foreign-key lookup', () {
    final sql = DatabaseForeignKeyQueryBuilder.relatedSql(
      relation: relationA,
      allRelations: relations,
      row: const {'company_id': '42'},
      limit: 50,
    );

    expect(sql, isNull);
  });

  test('builds reverse navigation with every referenced row value', () {
    final sql = DatabaseForeignKeyQueryBuilder.referencingSql(
      relation: relationA,
      allRelations: relations,
      row: const {'id': '42', 'code': 'ACME'},
      limit: 50,
    );

    expect(
      sql,
      "SELECT * FROM `order_lines` WHERE `company_id` = '42' AND "
      "`company_code` = 'ACME' LIMIT 50;",
    );
  });
}
