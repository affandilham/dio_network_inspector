import 'package:dio_network_inspector/src/features/database/database_models.dart';
import 'package:dio_network_inspector/src/features/database/sql_autocomplete.dart';
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
