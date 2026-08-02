import 'package:dio_network_inspector/src/features/database/domain/sql/sql_error_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts a MySQL error line number', () {
    expect(SqlErrorLine.fromMessage('Syntax error near SELECT at line 5'), 5);
  });

  test('returns null when error has no line number', () {
    expect(SqlErrorLine.fromMessage('Connection refused'), isNull);
  });

  test('maps a statement-relative MySQL error line to the editor', () {
    expect(
      SqlErrorLine.editorLine(
        message: 'Syntax error near SELECT at line 2',
        statementStartLine: 4,
      ),
      5,
    );
  });
}
