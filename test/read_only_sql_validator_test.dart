import 'package:dio_network_inspector/src/features/database/read_only_sql_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadOnlySqlValidator', () {
    test('adds a result limit to SELECT queries without one', () {
      final result = ReadOnlySqlValidator.validate(
        'SELECT * FROM users',
        maximumRows: 50,
      );

      expect(result.isAllowed, isTrue);
      expect(result.executionSql, 'SELECT * FROM users LIMIT 50');
    });

    test('accepts a semicolon in a quoted string', () {
      final result = ReadOnlySqlValidator.validate(
        "SELECT ';' AS punctuation;",
      );

      expect(result.isAllowed, isTrue);
      expect(result.executionSql, "SELECT ';' AS punctuation LIMIT 100");
    });

    test('blocks write operations', () {
      final result = ReadOnlySqlValidator.validate(
        'UPDATE users SET name = "unsafe"',
      );

      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('not allowed'));
    });

    test('does not treat a write keyword inside a string as an operation', () {
      final result = ReadOnlySqlValidator.validate(
        "SELECT * FROM audit_log WHERE action = 'update'",
      );

      expect(result.isAllowed, isTrue);
    });

    test('blocks lock and file output clauses hidden in a SELECT', () {
      expect(
        ReadOnlySqlValidator.validate(
          'SELECT * FROM users FOR UPDATE',
        ).isAllowed,
        isFalse,
      );
      expect(
        ReadOnlySqlValidator.validate(
          "SELECT * FROM users INTO OUTFILE '/tmp/users.csv'",
        ).isAllowed,
        isFalse,
      );
    });

    test('blocks multiple SQL statements', () {
      final result = ReadOnlySqlValidator.validate(
        'SELECT * FROM users; DELETE FROM users',
      );

      expect(result.isAllowed, isFalse);
      expect(result.reason, contains('Only one active'));
    });

    test('ignores comments when splitting statements', () {
      final result = ReadOnlySqlValidator.validate(
        'SELECT 1 /* ; ignored */ -- ; ignored\n',
      );

      expect(result.isAllowed, isTrue);
      expect(result.executionSql, contains('LIMIT 100'));
    });
  });
}
