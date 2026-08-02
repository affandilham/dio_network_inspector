/// A locally stored read-only query. It never contains credentials or rows.
class DatabaseQueryHistoryEntry {
  const DatabaseQueryHistoryEntry({
    required this.scope,
    required this.sql,
    required this.executedAt,
  });

  final String scope;
  final String sql;
  final DateTime executedAt;

  Map<String, Object> toJson() => {
    'scope': scope,
    'sql': sql,
    'executedAt': executedAt.toIso8601String(),
  };

  static DatabaseQueryHistoryEntry? tryParse(Object? value) {
    if (value is! Map) return null;
    final scope = value['scope']?.toString().trim() ?? '';
    final sql = value['sql']?.toString().trim() ?? '';
    final executedAt = DateTime.tryParse(value['executedAt']?.toString() ?? '');
    if (scope.isEmpty || sql.isEmpty || executedAt == null) return null;
    return DatabaseQueryHistoryEntry(
      scope: scope,
      sql: sql,
      executedAt: executedAt,
    );
  }
}
