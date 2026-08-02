import '../domain/database_models.dart';

/// Low-level database operations used by the inspector session.
abstract interface class DatabaseInspectorClient {
  bool get isConnected;

  Future<void> connect();
  Future<void> disconnect();

  /// Stops the current server operation by closing the inspector session.
  Future<void> cancelActiveQuery();
  Future<List<DatabaseTable>> listTables();
  Future<List<DatabaseKeyword>> listKeywords();
  Future<List<DatabaseColumn>> listColumns(String table);
  Future<Map<String, List<DatabaseColumn>>> listAllColumns();
  Future<List<DatabaseForeignKey>> listForeignKeys();
  Future<List<DatabaseTableIndex>> listIndexes(String table);
  Future<List<DatabaseTableTrigger>> listTriggers(String table);
  Future<String?> showCreateTable(String table);
  Future<DatabasePage> fetchRows({
    required String table,
    required int offset,
    required int limit,
  });
  Future<DatabasePage> executeReadOnly(String sql);
}
