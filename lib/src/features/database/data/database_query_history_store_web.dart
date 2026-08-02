import '../contracts/database_query_history_store.dart';
import '../domain/database_query_history_entry.dart';

/// Web fallback keeps history private to the current inspector process.
class LocalDatabaseQueryHistoryStore implements DatabaseQueryHistoryStore {
  List<DatabaseQueryHistoryEntry> _entries = const [];

  @override
  Future<List<DatabaseQueryHistoryEntry>> read(String scope) async =>
      _entries.where((entry) => entry.scope == scope).toList(growable: false);

  @override
  Future<void> write(
    String scope,
    List<DatabaseQueryHistoryEntry> entries,
  ) async {
    _entries = List.unmodifiable([
      ..._entries.where((entry) => entry.scope != scope),
      ...entries,
    ]);
  }
}
