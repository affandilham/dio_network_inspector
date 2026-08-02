@Tags(['mysql-integration'])
library;

import 'dart:io';

import 'package:dio_network_inspector/src/features/database/data/mysql_database_client.dart';
import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// This suite never opts into a database by default.
///
/// Run it only against a disposable local fixture with
/// `MYSQL_INSPECTOR_INTEGRATION=1`. It deliberately rejects non-local hosts
/// and an environment labelled production before opening a socket.
void main() {
  final isEnabled = Platform.environment['MYSQL_INSPECTOR_INTEGRATION'] == '1';

  test(
    'connects to an explicitly configured local MySQL fixture read-only',
    () async {
      final config = _localFixtureConfig();
      final client = MySqlDatabaseClient(config);
      addTearDown(client.disconnect);

      await client.connect();
      expect(client.isConnected, isTrue);

      final tables = await client.listTables();
      expect(tables, isA<List<DatabaseTable>>());

      final page = await client.executeReadOnly('SELECT 1 AS inspector_probe');
      expect(page.rows.single['inspector_probe'], '1');
    },
    skip: isEnabled
        ? false
        : 'Set MYSQL_INSPECTOR_INTEGRATION=1 to run against a local fixture.',
  );
}

MySqlInspectorConfig _localFixtureConfig() {
  final environment =
      Platform.environment['MYSQL_INSPECTOR_ENVIRONMENT'] ?? 'development';
  if (environment.trim().toLowerCase() == 'production') {
    throw StateError(
      'The MySQL integration test never runs against production.',
    );
  }

  final host = Platform.environment['MYSQL_INSPECTOR_HOST'] ?? '';
  const allowedHosts = {'localhost', '127.0.0.1', '::1'};
  if (!allowedHosts.contains(host.trim().toLowerCase())) {
    throw StateError(
      'MYSQL_INSPECTOR_HOST must be localhost, 127.0.0.1, or ::1 for tests.',
    );
  }

  final missing = [
    for (final name in const [
      'MYSQL_INSPECTOR_PORT',
      'MYSQL_INSPECTOR_DATABASE',
      'MYSQL_INSPECTOR_USERNAME',
      'MYSQL_INSPECTOR_PASSWORD',
    ])
      if ((Platform.environment[name] ?? '').trim().isEmpty) name,
  ];
  if (missing.isNotEmpty) {
    throw StateError(
      'Missing integration-test variables: ${missing.join(', ')}',
    );
  }

  final port = int.tryParse(Platform.environment['MYSQL_INSPECTOR_PORT']!);
  if (port == null) throw StateError('MYSQL_INSPECTOR_PORT must be a number.');
  return MySqlInspectorConfig(
    host: host,
    port: port,
    database: Platform.environment['MYSQL_INSPECTOR_DATABASE']!,
    username: Platform.environment['MYSQL_INSPECTOR_USERNAME']!,
    password: Platform.environment['MYSQL_INSPECTOR_PASSWORD']!,
    sslMode: _sslMode(Platform.environment['MYSQL_INSPECTOR_SSL']),
    environmentLabel: environment,
  );
}

MySqlSslMode _sslMode(String? raw) => switch (raw?.toLowerCase()) {
  'disabled' => MySqlSslMode.disabled,
  'required' => MySqlSslMode.required,
  _ => MySqlSslMode.preferred,
};
