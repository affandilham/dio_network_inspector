import '../domain/database_query_history_entry.dart';

/// Private local persistence for executed database queries.
abstract interface class DatabaseQueryHistoryStore {
  Future<List<DatabaseQueryHistoryEntry>> read(String scope);
  Future<void> write(String scope, List<DatabaseQueryHistoryEntry> entries);
}
