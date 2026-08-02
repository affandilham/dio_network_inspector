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
    this.executionTimeout = const Duration(seconds: 30),
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
  final Duration executionTimeout;

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
    if (executionTimeout <= Duration.zero) {
      return 'Execution timeout must be greater than zero.';
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

class DatabaseKeyword {
  const DatabaseKeyword({required this.word, required this.isReserved});

  final String word;
  final bool isReserved;
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

/// A validated schema relationship discovered from MySQL metadata.
///
/// It is metadata only; [DatabaseForeignKey] never contains a row value or
/// credentials. The controller uses it solely to prepare a read-only query.
class DatabaseForeignKey {
  const DatabaseForeignKey({
    required this.table,
    required this.column,
    required this.referencedTable,
    required this.referencedColumn,
    this.constraintName = '',
    this.ordinalPosition = 1,
    this.onUpdate,
    this.onDelete,
  });

  final String table;
  final String column;
  final String referencedTable;
  final String referencedColumn;

  /// MySQL constraint that groups the columns of a composite foreign key.
  ///
  /// Older/custom clients may not expose it; those relations intentionally
  /// retain single-column behaviour.
  final String constraintName;
  final int ordinalPosition;
  final String? onUpdate;
  final String? onDelete;
}

/// Read-only metadata for one MySQL index and its ordered columns.
class DatabaseTableIndex {
  const DatabaseTableIndex({
    required this.name,
    required this.isUnique,
    required this.type,
    required this.columns,
  });

  final String name;
  final bool isUnique;
  final String type;
  final List<String> columns;
}

/// Read-only metadata for one trigger declared on a MySQL table.
class DatabaseTableTrigger {
  const DatabaseTableTrigger({
    required this.name,
    required this.timing,
    required this.event,
    required this.statement,
  });

  final String name;
  final String timing;
  final String event;
  final String statement;
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
