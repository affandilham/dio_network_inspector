import '../contracts/database_saved_query_store.dart';
import '../domain/database_saved_query.dart';

class LocalDatabaseSavedQueryStore implements DatabaseSavedQueryStore {
  List<DatabaseSavedQuery> _entries = const [];

  @override
  Future<List<DatabaseSavedQuery>> read(String scope) async =>
      _entries.where((entry) => entry.scope == scope).toList(growable: false);

  @override
  Future<void> write(String scope, List<DatabaseSavedQuery> entries) async {
    _entries = List.unmodifiable([
      ..._entries.where((entry) => entry.scope != scope),
      ...entries,
    ]);
  }
}
