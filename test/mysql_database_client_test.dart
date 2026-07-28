import 'package:dio_network_inspector/src/features/database/mysql_database_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MySqlDatabaseClient.parseEnumValues', () {
    test('parses MySQL enum metadata', () {
      expect(
        MySqlDatabaseClient.parseEnumValues(
          "enum('own-farm','mitra','makloon-chbh')",
        ),
        ['own-farm', 'mitra', 'makloon-chbh'],
      );
    });

    test('preserves escaped and comma values', () {
      expect(
        MySqlDatabaseClient.parseEnumValues(
          "enum('ready,now','farmer\\'s choice')",
        ),
        ['ready,now', "farmer's choice"],
      );
    });

    test('returns an empty list for a non-enum type', () {
      expect(MySqlDatabaseClient.parseEnumValues('varchar(255)'), isEmpty);
    });
  });
}
