import '../domain/database_query_tab_session.dart';

/// Private local persistence for query-tab names and drafts.
abstract interface class DatabaseQueryTabSessionStore {
  Future<List<DatabaseQueryTabSession>> read(String scope);
  Future<void> write(String scope, List<DatabaseQueryTabSession> tabs);
}
