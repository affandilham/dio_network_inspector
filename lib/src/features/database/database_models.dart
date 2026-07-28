enum MySqlSslMode { disabled, preferred, required }

/// Connection details supplied by the host application.
///
/// Keep instances local to the host app. The inspector never exports this
/// object, stores it on disk, or includes it in network session exports.
class MySqlInspectorConfig {
  const MySqlInspectorConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.sslMode = MySqlSslMode.preferred,
    this.environmentLabel = 'development',
    this.pageSize = 50,
    this.maxPageSize = 100,
    this.connectTimeout = const Duration(seconds: 10),
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final MySqlSslMode sslMode;
  final String environmentLabel;
  final int pageSize;
  final int maxPageSize;
  final Duration connectTimeout;

  String? get validationError {
    if (host.trim().isEmpty) return 'Database host is required.';
    if (port < 1 || port > 65535) return 'Database port must be 1–65535.';
    if (database.trim().isEmpty) return 'Database name is required.';
    if (username.trim().isEmpty) return 'Database username is required.';
    if (pageSize < 1 || maxPageSize < 1) {
      return 'Page size must be greater than zero.';
    }
    if (pageSize > maxPageSize) {
      return 'Page size cannot exceed the maximum page size.';
    }
    return null;
  }

  bool get isProduction =>
      environmentLabel.trim().toLowerCase() == 'production';
}

class DatabaseTable {
  const DatabaseTable({required this.name, this.type});

  final String name;
  final String? type;
}

class DatabaseColumn {
  const DatabaseColumn({
    required this.name,
    required this.type,
    this.isNullable = true,
    this.enumValues = const [],
  });

  final String name;
  final String type;
  final bool isNullable;
  final List<String> enumValues;
}

/// A read-only filter created from known table metadata.
///
/// The client quotes [column] as an identifier and binds [value] as a query
/// parameter. It is not built from arbitrary SQL entered by the user.
class DatabaseTableFilter {
  const DatabaseTableFilter.equals({required this.column, required this.value})
    : matchesNull = false;

  const DatabaseTableFilter.isNull({required this.column})
    : value = null,
      matchesNull = true;

  final String column;
  final String? value;
  final bool matchesNull;
}

class DatabasePage {
  const DatabasePage({
    required this.columns,
    required this.rows,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  final List<DatabaseColumn> columns;
  final List<Map<String, String?>> rows;
  final int offset;
  final int limit;
  final bool hasMore;
}

class ReadOnlySqlValidation {
  const ReadOnlySqlValidation._({
    required this.isAllowed,
    this.executionSql,
    this.reason,
  });

  const ReadOnlySqlValidation.allowed(String sql)
    : this._(isAllowed: true, executionSql: sql);

  const ReadOnlySqlValidation.blocked(String reason)
    : this._(isAllowed: false, reason: reason);

  final bool isAllowed;
  final String? executionSql;
  final String? reason;
}
