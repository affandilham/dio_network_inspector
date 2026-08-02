import 'package:dio_network_inspector/src/features/database/domain/sql/sql_statement_parser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds only the statement containing the cursor', () {
    const source = 'SELECT * FROM users;\n\nSELECT * FROM companies;';
    final secondStart = source.indexOf('SELECT', 1);
    final active = SqlStatementParser.activeStatement(
      source,
      TextSelection.collapsed(offset: secondStart + 3),
    );

    expect(active?.sourceFrom(source), 'SELECT * FROM companies');
    expect(active?.startLineIn(source), 3);
  });

  test('keeps the statement active immediately after its delimiter', () {
    const source = 'SELECT 1;\n\nSELECT 2;';
    final active = SqlStatementParser.activeStatement(
      source,
      TextSelection.collapsed(offset: source.indexOf('\n')),
    );

    expect(active?.sourceFrom(source), 'SELECT 1');
  });

  test('keeps the statement active after a colon inside SQL', () {
    const source = 'SELECT * FROM users WHERE user_id = :';
    final active = SqlStatementParser.activeStatement(
      source,
      TextSelection.collapsed(offset: source.length),
    );

    expect(active?.sourceFrom(source), source);
  });

  test('returns no active statement in whitespace between statements', () {
    const source = 'SELECT 1;\n\nSELECT 2;';
    final active = SqlStatementParser.activeStatement(
      source,
      TextSelection.collapsed(offset: source.indexOf('\n') + 1),
    );

    expect(active, isNull);
  });

  test('does not split on semicolons inside quoted text or comments', () {
    const source = "SELECT ';' AS text /* ; */; -- ; ignored\nSELECT 2;";

    final statements = SqlStatementParser.statements(
      source,
    ).map((statement) => statement.sourceFrom(source)).toList();

    expect(statements, hasLength(2));
    expect(statements.first, contains("';'"));
    expect(statements.last, contains('SELECT 2'));
  });

  test('includes only the closing delimiter in the visual range', () {
    const source = 'SELECT * FROM users;\n\nSELECT 2;';

    final statement = SqlStatementParser.statements(source).first;

    expect(statement.sourceFrom(source), 'SELECT * FROM users');
    expect(
      source.substring(statement.start, statement.highlightEnd),
      'SELECT * FROM users;',
    );
  });
}
