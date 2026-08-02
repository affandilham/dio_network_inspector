/// Preferences that apply to the entire inspector window.
///
/// These are intentionally session-only. They do not contain credentials and
/// are not included in an exported network-inspector session.
class InspectorSettings {
  const InspectorSettings({
    this.releaseInactiveDatabaseQueryResults = false,
    this.storeDatabaseQueryHistoryInProduction = false,
    this.enableDatabaseIdleDisconnect = false,
    this.databaseIdleDisconnectTimeout = const Duration(minutes: 5),
  });

  /// Releases result pages held by inactive database query tabs.
  ///
  /// This can substantially reduce memory use for large result sets, but a
  /// released tab must execute its SQL again to show its rows.
  final bool releaseInactiveDatabaseQueryResults;
  final bool storeDatabaseQueryHistoryInProduction;

  /// Disconnects a MySQL inspector session after no database activity.
  ///
  /// Disabled by default so opening the inspector never unexpectedly closes a
  /// connection. The timeout only applies while this setting is enabled.
  final bool enableDatabaseIdleDisconnect;
  final Duration databaseIdleDisconnectTimeout;

  InspectorSettings copyWith({
    bool? releaseInactiveDatabaseQueryResults,
    bool? storeDatabaseQueryHistoryInProduction,
    bool? enableDatabaseIdleDisconnect,
    Duration? databaseIdleDisconnectTimeout,
  }) => InspectorSettings(
    releaseInactiveDatabaseQueryResults:
        releaseInactiveDatabaseQueryResults ??
        this.releaseInactiveDatabaseQueryResults,
    storeDatabaseQueryHistoryInProduction:
        storeDatabaseQueryHistoryInProduction ??
        this.storeDatabaseQueryHistoryInProduction,
    enableDatabaseIdleDisconnect:
        enableDatabaseIdleDisconnect ?? this.enableDatabaseIdleDisconnect,
    databaseIdleDisconnectTimeout:
        databaseIdleDisconnectTimeout ?? this.databaseIdleDisconnectTimeout,
  );
}
