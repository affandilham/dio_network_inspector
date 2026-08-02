import 'package:dio_network_inspector/src/core/settings/inspector_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database result eviction is disabled by default', () {
    const settings = InspectorSettings();

    expect(settings.releaseInactiveDatabaseQueryResults, isFalse);
  });

  test('copies a global setting without mutating the original', () {
    const settings = InspectorSettings();
    final updated = settings.copyWith(
      releaseInactiveDatabaseQueryResults: true,
    );

    expect(settings.releaseInactiveDatabaseQueryResults, isFalse);
    expect(updated.releaseInactiveDatabaseQueryResults, isTrue);
  });

  test('idle database disconnect is optional and keeps its interval', () {
    const settings = InspectorSettings();
    final updated = settings.copyWith(
      enableDatabaseIdleDisconnect: true,
      databaseIdleDisconnectTimeout: Duration(minutes: 15),
    );

    expect(settings.enableDatabaseIdleDisconnect, isFalse);
    expect(updated.enableDatabaseIdleDisconnect, isTrue);
    expect(updated.databaseIdleDisconnectTimeout, const Duration(minutes: 15));
  });
}
