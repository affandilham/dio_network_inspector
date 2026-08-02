import 'package:dio_network_inspector/src/features/database/domain/sql/sql_syntax_highlighter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('colours keywords, strings, numbers, comments, and identifiers', () {
    const source = "SELECT `name`, 42 FROM users WHERE role = 'owner' -- note";

    final tokens = SqlSyntaxHighlighter.tokenize(source);

    expect(
      tokens.map((token) => token.kind),
      containsAll([
        SqlSyntaxKind.keyword,
        SqlSyntaxKind.identifier,
        SqlSyntaxKind.number,
        SqlSyntaxKind.string,
        SqlSyntaxKind.comment,
      ]),
    );
  });

  test(
    'does not treat keywords inside strings and comments as SQL keywords',
    () {
      const source = "SELECT 'FROM users' /* WHERE id = 1 */";

      final tokens = SqlSyntaxHighlighter.tokenize(source);

      expect(
        tokens.where((token) => token.kind == SqlSyntaxKind.keyword),
        hasLength(1),
      );
    },
  );
}
