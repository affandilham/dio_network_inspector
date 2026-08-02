import 'package:dio_network_inspector/src/features/database/presentation/result/database_json_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats valid JSON for a read-only preview', () {
    expect(
      DatabaseJsonPreview.tryFormat('{"farm":{"id":7}}'),
      '{\n  "farm": {\n    "id": 7\n  }\n}',
    );
  });

  test('does not create a preview for invalid or empty JSON', () {
    expect(DatabaseJsonPreview.tryFormat('not-json'), isNull);
    expect(DatabaseJsonPreview.tryFormat('  '), isNull);
  });
}
