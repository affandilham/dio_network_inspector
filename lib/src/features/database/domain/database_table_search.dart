import 'database_models.dart';

/// Filters the cached schema table list for the database sidebar.
///
/// Matching is case-insensitive and may occur anywhere in the table name, so
/// a partial suffix such as `dings` finds `report_recordings`.
class DatabaseTableSearch {
  const DatabaseTableSearch._();

  static List<DatabaseTable> filter(
    Iterable<DatabaseTable> tables,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return List.unmodifiable(tables);

    return List.unmodifiable(
      tables.where(
        (table) => table.name.toLowerCase().contains(normalizedQuery),
      ),
    );
  }
}
