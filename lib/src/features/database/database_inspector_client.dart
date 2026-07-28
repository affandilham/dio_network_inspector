import 'database_models.dart';

abstract interface class DatabaseInspectorClient {
  bool get isConnected;

  Future<void> connect();
  Future<void> disconnect();
  Future<List<DatabaseTable>> listTables();
  Future<List<DatabaseColumn>> listColumns(String table);
  Future<DatabasePage> fetchRows({
    required String table,
    required int offset,
    required int limit,
    DatabaseTableFilter? filter,
  });
  Future<DatabasePage> executeReadOnly(String sql);
}
