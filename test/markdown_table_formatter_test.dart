import 'package:dio_network_inspector/src/features/notes/markdown_table_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aligns a Markdown table and preserves column alignment', () {
    expect(
      formatMarkdownTableBlock('''
| Name|Status |
|:--|--:|
|Dio Network Inspector|Ready|
'''),
      '''
| Name                  | Status |
| :-------------------- | -----: |
| Dio Network Inspector | Ready  |
''',
    );
  });

  test('adds a delimiter row when formatting plain table rows', () {
    expect(
      formatMarkdownTableBlock('| Feature | Done |\n| Save | Yes |'),
      '| Feature | Done |\n| ------- | ---- |\n| Save    | Yes  |',
    );
  });

  test('does not format text that is not a table', () {
    expect(formatMarkdownTableBlock('Only one | separator'), isNull);
  });
}
