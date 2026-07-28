import 'package:mysql_client/mysql_client.dart';

import 'database_inspector_client.dart';
import 'database_models.dart';
import 'read_only_sql_validator.dart';

class MySqlDatabaseClient implements DatabaseInspectorClient {
  MySqlDatabaseClient(this.config);

  final MySqlInspectorConfig config;
  MySQLConnection? _connection;

  @override
  bool get isConnected => _connection?.connected ?? false;

  @override
  Future<void> connect() async {
    final error = config.validationError;
    if (error != null) throw ArgumentError(error);
    if (isConnected) return;

    final connection = await MySQLConnection.createConnection(
      host: config.host,
      port: config.port,
      userName: config.username,
      password: config.password,
      databaseName: config.database,
      secure: config.sslMode != MySqlSslMode.disabled,
    );
    try {
      await connection.connect(timeoutMs: config.connectTimeout.inMilliseconds);
      _connection = connection;
    } catch (_) {
      await connection.close();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    if (connection != null && connection.connected) {
      await connection.close();
    }
  }

  @override
  Future<List<DatabaseTable>> listTables() async {
    final result = await _requireConnection().execute(
      'SELECT TABLE_NAME AS name, TABLE_TYPE AS type '
      'FROM information_schema.tables '
      'WHERE TABLE_SCHEMA = :database ORDER BY TABLE_NAME',
      {'database': config.database},
    );
    return result.rows
        .map(
          (row) => DatabaseTable(
            name: row.assoc()['name'] ?? '',
            type: row.assoc()['type'],
          ),
        )
        .where((table) => table.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<DatabaseColumn>> listColumns(String table) async {
    final result = await _requireConnection().execute(
      'SELECT COLUMN_NAME AS name, COLUMN_TYPE AS type, '
      'IS_NULLABLE AS nullable '
      'FROM information_schema.columns '
      'WHERE TABLE_SCHEMA = :database AND TABLE_NAME = :table '
      'ORDER BY ORDINAL_POSITION',
      {'database': config.database, 'table': table},
    );
    return result.rows
        .map((row) {
          final values = row.assoc();
          final type = values['type'] ?? '';
          return DatabaseColumn(
            name: values['name'] ?? '',
            type: type,
            isNullable: (values['nullable'] ?? '').toUpperCase() == 'YES',
            enumValues: _enumValues(type),
          );
        })
        .where((column) => column.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<DatabasePage> fetchRows({
    required String table,
    required int offset,
    required int limit,
  }) async {
    final safeLimit = limit.clamp(1, config.maxPageSize);
    final safeOffset = offset < 0 ? 0 : offset;
    final result = await _requireConnection().execute(
      <String>[
        'SELECT * FROM ',
        _quoteIdentifier(table),
        ' LIMIT $safeLimit OFFSET $safeOffset',
      ].join(),
    );
    return _pageFromResult(
      result,
      offset: safeOffset,
      limit: safeLimit,
      hasMore: result.numOfRows == safeLimit,
    );
  }

  @override
  Future<DatabasePage> executeReadOnly(String sql) async {
    final validation = ReadOnlySqlValidator.validate(
      sql,
      maximumRows: config.maxPageSize,
    );
    if (!validation.isAllowed) {
      throw StateError(validation.reason ?? 'The query is not read-only.');
    }
    final result = await _requireConnection().execute(validation.executionSql!);
    return _pageFromResult(
      result,
      offset: 0,
      limit: config.maxPageSize,
      hasMore: result.numOfRows >= config.maxPageSize,
    );
  }

  MySQLConnection _requireConnection() {
    final connection = _connection;
    if (connection == null || !connection.connected) {
      throw StateError('Database is not connected.');
    }
    return connection;
  }

  DatabasePage _pageFromResult(
    IResultSet result, {
    required int offset,
    required int limit,
    required bool hasMore,
  }) {
    final columns = result.cols
        .map(
          (column) => DatabaseColumn(
            name: column.name,
            type: 'mysql:${column.type.intVal}',
          ),
        )
        .toList(growable: false);
    final rows = result.rows
        .map((row) => Map<String, String?>.from(row.assoc()))
        .toList(growable: false);
    return DatabasePage(
      columns: columns,
      rows: rows,
      offset: offset,
      limit: limit,
      hasMore: hasMore,
    );
  }

  static String _quoteIdentifier(String identifier) {
    final quote = String.fromCharCode(96);
    return quote + identifier.replaceAll(quote, quote + quote) + quote;
  }

  static List<String> _enumValues(String columnType) {
    if (!columnType.toLowerCase().startsWith('enum(') ||
        !columnType.endsWith(')')) {
      return const [];
    }
    final source = columnType.substring(5, columnType.length - 1);
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;
    for (var index = 0; index < source.length; index++) {
      final char = source[index];
      final next = index + 1 < source.length ? source[index + 1] : '';
      if (char == '\\' && next.isNotEmpty) {
        buffer.write(next);
        index++;
      } else if (char == '\'') {
        if (inQuote && next == '\'') {
          buffer.write(next);
          index++;
        } else {
          inQuote = !inQuote;
        }
      } else if (char == ',' && !inQuote) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    if (buffer.isNotEmpty) values.add(buffer.toString());
    return values.map((value) => value.trim()).toList(growable: false);
  }
}
