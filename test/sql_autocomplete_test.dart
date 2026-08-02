import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:dio_network_inspector/src/features/database/domain/sql/sql_autocomplete.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tables = [
    DatabaseTable(name: 'users'),
    DatabaseTable(name: 'user_roles'),
  ];
  const columnsByTable = {
    'users': [
      DatabaseColumn(name: 'id', type: 'bigint'),
      DatabaseColumn(name: 'price', type: 'decimal(18,2)'),
    ],
  };

  test('suggests keywords and known tables for the active token', () {
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: 'use',
        selection: TextSelection.collapsed(offset: 3),
      ),
      tables: tables,
      columnsByTable: columnsByTable,
    );

    expect(
      suggestions.map((suggestion) => suggestion.value),
      containsAll(['USER', 'users']),
    );
  });

  test('ranks the shortest matching table before longer table names', () {
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: 'user',
        selection: TextSelection.collapsed(offset: 4),
      ),
      tables: const [
        DatabaseTable(name: 'user_balance_projects'),
        DatabaseTable(name: 'users'),
      ],
      columnsByTable: const {},
    );

    expect(
      suggestions
          .where((suggestion) => suggestion.kind == SqlAutocompleteKind.table)
          .map((suggestion) => suggestion.value),
      orderedEquals(['users', 'user_balance_projects']),
    );
  });

  test('uses dynamically loaded MySQL keywords when available', () {
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: 'win',
        selection: TextSelection.collapsed(offset: 3),
      ),
      tables: tables,
      columnsByTable: columnsByTable,
      keywords: const [
        DatabaseKeyword(word: 'WINDOW', isReserved: true),
        DatabaseKeyword(word: 'WITH', isReserved: true),
      ],
    );

    expect(suggestions.single.value, 'WINDOW');
    expect(suggestions.single.detail, 'reserved keyword');
  });

  test('does not suggest columns before a source table is selected', () {
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: 'SELECT * FROM p',
        selection: TextSelection.collapsed(offset: 15),
      ),
      tables: tables,
      columnsByTable: columnsByTable,
    );

    expect(
      suggestions.map((suggestion) => suggestion.kind),
      isNot(contains(SqlAutocompleteKind.column)),
    );
  });

  test('suggests unqualified columns only from selected source tables', () {
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: 'SELECT * FROM users WHERE pr',
        selection: TextSelection.collapsed(offset: 28),
      ),
      tables: tables,
      columnsByTable: columnsByTable,
    );

    expect(suggestions.single.value, 'price');
    expect(suggestions.single.detail, 'users.decimal(18,2)');
  });

  test('matches snake-case column segments and prioritizes source columns', () {
    const sql = 'SELECT * FROM purchase_order_details WHERE price';
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: sql,
        selection: TextSelection.collapsed(offset: sql.length),
      ),
      tables: const [DatabaseTable(name: 'price_todays')],
      columnsByTable: const {
        'purchase_order_details': [
          DatabaseColumn(name: 'supplier_price', type: 'decimal(18,2)'),
          DatabaseColumn(name: 'supplier_unit_price', type: 'decimal(18,2)'),
        ],
      },
    );

    expect(
      suggestions.take(2).map((suggestion) => suggestion.value),
      orderedEquals(['supplier_price', 'supplier_unit_price']),
    );
  });

  test('does not mix unqualified columns from joined tables', () {
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text:
            'SELECT * FROM users JOIN orders ON orders.user_id = users.id WHERE pr',
        selection: TextSelection.collapsed(offset: 69),
      ),
      tables: const [
        DatabaseTable(name: 'users'),
        DatabaseTable(name: 'orders'),
      ],
      columnsByTable: const {
        'users': [DatabaseColumn(name: 'name', type: 'varchar')],
        'orders': [DatabaseColumn(name: 'price', type: 'decimal')],
      },
    );

    expect(suggestions, isEmpty);
  });

  test('keeps every matching column from a selected source table', () {
    final columns = List.generate(
      12,
      (index) => DatabaseColumn(name: 'field_$index', type: 'varchar'),
    );
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: 'SELECT * FROM orders WHERE field',
        selection: TextSelection.collapsed(offset: 32),
      ),
      tables: const [DatabaseTable(name: 'orders')],
      columnsByTable: {'orders': columns},
    );

    expect(suggestions, hasLength(12));
  });

  test('suggests cached columns through a table alias', () {
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: 'SELECT u.pr FROM users AS u',
        selection: TextSelection.collapsed(offset: 11),
      ),
      tables: tables,
      columnsByTable: columnsByTable,
    );

    expect(suggestions.single.value, 'u.price');
    expect(suggestions.single.detail, 'users.decimal(18,2)');
  });

  test('finds the table for the alias at the cursor', () {
    final table = SqlAutocomplete.tableForActiveQualifier(
      const TextEditingValue(
        text: 'SELECT U.ph FROM users AS U',
        selection: TextSelection.collapsed(offset: 11),
      ),
    );

    expect(table, 'users');
  });

  test('suggests a common table expression as a source', () {
    const sql =
        'WITH active_users AS (SELECT id, price FROM users) SELECT * FROM act';
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: sql,
        selection: TextSelection.collapsed(offset: sql.length),
      ),
      tables: tables,
      columnsByTable: columnsByTable,
    );

    expect(
      suggestions.where((item) => item.kind == SqlAutocompleteKind.cte).single,
      isA<SqlAutocompleteSuggestion>()
          .having((item) => item.value, 'value', 'active_users')
          .having((item) => item.detail, 'detail', 'common table expression'),
    );
  });

  test('suggests projected CTE columns through an alias', () {
    const sql =
        'WITH active_users AS (SELECT id, price FROM users) '
        'SELECT au.pr FROM active_users AS au';
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: sql,
        selection: TextSelection.collapsed(offset: 63),
      ),
      tables: tables,
      columnsByTable: columnsByTable,
    );

    expect(suggestions.single.value, 'au.price');
    expect(suggestions.single.detail, 'active_users.decimal(18,2)');
  });

  test('uses declared CTE output names for suggestions', () {
    const sql =
        'WITH active_users (user_id) AS (SELECT id FROM users) '
        'SELECT au.us FROM active_users au';
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: sql,
        selection: TextSelection.collapsed(offset: 66),
      ),
      tables: tables,
      columnsByTable: columnsByTable,
    );

    expect(suggestions.single.value, 'au.user_id');
    expect(suggestions.single.detail, 'active_users.bigint');
  });

  test('uses aliases from the statement at the cursor only', () {
    const sql = 'SELECT u.na FROM users u; SELECT o.pr FROM orders o';
    final suggestions = SqlAutocomplete.suggestions(
      editingValue: const TextEditingValue(
        text: sql,
        selection: TextSelection.collapsed(offset: 37),
      ),
      tables: const [
        DatabaseTable(name: 'users'),
        DatabaseTable(name: 'orders'),
      ],
      columnsByTable: const {
        'users': [DatabaseColumn(name: 'name', type: 'varchar')],
        'orders': [DatabaseColumn(name: 'price', type: 'decimal')],
      },
    );

    expect(suggestions.single.value, 'o.price');
  });

  test('replaces only the active token when applying a suggestion', () {
    final result = SqlAutocomplete.applySuggestion(
      editingValue: const TextEditingValue(
        text: 'SELECT u.pr FROM users AS u',
        selection: TextSelection.collapsed(offset: 11),
      ),
      value: 'u.price',
    );

    expect(result.text, 'SELECT u.price FROM users AS u');
    expect(result.selection.baseOffset, 14);
  });
}
