import '../domain/database_saved_query.dart';

abstract interface class DatabaseSavedQueryStore {
  Future<List<DatabaseSavedQuery>> read(String scope);
  Future<void> write(String scope, List<DatabaseSavedQuery> entries);
}
