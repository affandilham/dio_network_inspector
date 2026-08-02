/// A named read-only SQL draft saved privately on the current device.
class DatabaseSavedQuery {
  const DatabaseSavedQuery({
    required this.id,
    required this.scope,
    required this.name,
    required this.sql,
    required this.savedAt,
    this.folder = '',
  });

  final String id;
  final String scope;
  final String name;
  final String sql;
  final DateTime savedAt;
  final String folder;

  Map<String, Object> toJson() => {
    'id': id,
    'scope': scope,
    'name': name,
    'sql': sql,
    'savedAt': savedAt.toIso8601String(),
    'folder': folder,
  };

  static DatabaseSavedQuery? tryParse(Object? value) {
    if (value is! Map) return null;
    final id = value['id']?.toString().trim() ?? '';
    final scope = value['scope']?.toString().trim() ?? '';
    final name = value['name']?.toString().trim() ?? '';
    final sql = value['sql']?.toString().trim() ?? '';
    final folder = value['folder']?.toString().trim() ?? '';
    final savedAt = DateTime.tryParse(value['savedAt']?.toString() ?? '');
    if (id.isEmpty ||
        scope.isEmpty ||
        name.isEmpty ||
        sql.isEmpty ||
        savedAt == null) {
      return null;
    }
    return DatabaseSavedQuery(
      id: id,
      scope: scope,
      name: name,
      sql: sql,
      savedAt: savedAt,
      folder: folder,
    );
  }
}
