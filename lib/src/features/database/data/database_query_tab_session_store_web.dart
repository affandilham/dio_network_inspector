import '../contracts/database_query_tab_session_store.dart';
import '../domain/database_query_tab_session.dart';

/// Web fallback keeps tab drafts private to the active inspector process.
class LocalDatabaseQueryTabSessionStore
    implements DatabaseQueryTabSessionStore {
  final Map<String, List<DatabaseQueryTabSession>> _sessions = {};

  @override
  Future<List<DatabaseQueryTabSession>> read(String scope) async =>
      List.unmodifiable(_sessions[scope] ?? const []);

  @override
  Future<void> write(String scope, List<DatabaseQueryTabSession> tabs) async {
    _sessions[scope] = List.unmodifiable(tabs);
  }
}
