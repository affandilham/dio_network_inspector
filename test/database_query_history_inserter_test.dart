import 'package:dio_network_inspector/src/features/database/application/query/database_query_history_inserter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'appends history without overwriting when focus overlaps a statement',
    () {
      const source = 'SELECT * FROM users;\nSELECT * FROM companies;';
      final result = DatabaseQueryHistoryInserter.insert(
        const TextEditingValue(
          text: source,
          selection: TextSelection.collapsed(offset: 8),
        ),
        historySql: 'SELECT * FROM roles',
      );

      expect(result.text, '$source\n\nSELECT * FROM roles;');
      expect(result.selection.baseOffset, result.text.length);
    },
  );

  test('adds a delimiter before appending to an unterminated statement', () {
    final result = DatabaseQueryHistoryInserter.insert(
      const TextEditingValue(
        text: 'SELECT * FROM users',
        selection: TextSelection.collapsed(offset: 4),
      ),
      historySql: 'SELECT * FROM roles',
    );

    expect(result.text, 'SELECT * FROM users;\n\nSELECT * FROM roles;');
  });

  test('inserts history at focus when cursor is between statements', () {
    const source = 'SELECT * FROM users;\n\nSELECT * FROM companies;';
    final offset = source.indexOf('\n') + 1;
    final result = DatabaseQueryHistoryInserter.insert(
      TextEditingValue(
        text: source,
        selection: TextSelection.collapsed(offset: offset),
      ),
      historySql: 'SELECT * FROM roles;',
    );

    expect(
      result.text,
      'SELECT * FROM users;\nSELECT * FROM roles;\nSELECT * FROM companies;',
    );
  });

  test('does not duplicate the closing delimiter from a saved query', () {
    final result = DatabaseQueryHistoryInserter.insert(
      const TextEditingValue(),
      historySql: 'SELECT * FROM saved_queries;',
    );

    expect(result.text, 'SELECT * FROM saved_queries;');
    expect(result.selection.baseOffset, result.text.length);
  });
}
