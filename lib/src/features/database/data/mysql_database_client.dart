import 'package:mysql_client/mysql_client.dart';

import '../contracts/database_inspector_client.dart';
import '../domain/database_models.dart';
import '../domain/sql/read_only_sql_validator.dart';

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
  Future<void> cancelActiveQuery() => disconnect();

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
  Future<List<DatabaseKeyword>> listKeywords() async {
    final result = await _requireConnection().execute(
      'SELECT WORD AS word, RESERVED AS reserved '
      'FROM information_schema.keywords ORDER BY WORD',
    );
    return result.rows
        .map((row) {
          final values = row.assoc();
          final word = values['word'] ?? '';
          return DatabaseKeyword(
            word: word,
            isReserved: values['reserved'] == '1',
          );
        })
        .where((keyword) => keyword.word.isNotEmpty)
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
        .map((row) => _columnFromValues(row.assoc()))
        .where((column) => column.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<Map<String, List<DatabaseColumn>>> listAllColumns() async {
    final result = await _requireConnection().execute(
      'SELECT TABLE_NAME AS table_name, COLUMN_NAME AS name, '
      'COLUMN_TYPE AS type, IS_NULLABLE AS nullable '
      'FROM information_schema.columns '
      'WHERE TABLE_SCHEMA = :database '
      'ORDER BY TABLE_NAME, ORDINAL_POSITION',
      {'database': config.database},
    );
    final columnsByTable = <String, List<DatabaseColumn>>{};
    for (final row in result.rows) {
      final values = row.assoc();
      final table = values['table_name'];
      if (table == null || table.isEmpty) continue;
      final column = _columnFromValues(values);
      if (column.name.isNotEmpty) {
        columnsByTable.putIfAbsent(table, () => []).add(column);
      }
    }
    return columnsByTable;
  }

  @override
  Future<List<DatabaseForeignKey>> listForeignKeys() async {
    final result = await _requireConnection().execute(
      'SELECT k.TABLE_NAME AS table_name, k.CONSTRAINT_NAME AS constraint_name, '
      'k.ORDINAL_POSITION AS ordinal_position, '
      'k.COLUMN_NAME AS column_name, '
      'k.REFERENCED_TABLE_NAME AS referenced_table, '
      'k.REFERENCED_COLUMN_NAME AS referenced_column, '
      'r.UPDATE_RULE AS update_rule, r.DELETE_RULE AS delete_rule '
      'FROM information_schema.key_column_usage k '
      'LEFT JOIN information_schema.referential_constraints r '
      'ON r.CONSTRAINT_SCHEMA = k.CONSTRAINT_SCHEMA '
      'AND r.CONSTRAINT_NAME = k.CONSTRAINT_NAME '
      'AND r.TABLE_NAME = k.TABLE_NAME '
      'WHERE k.TABLE_SCHEMA = :database '
      'AND k.REFERENCED_TABLE_NAME IS NOT NULL '
      'AND k.REFERENCED_COLUMN_NAME IS NOT NULL '
      'ORDER BY k.TABLE_NAME, k.CONSTRAINT_NAME, k.ORDINAL_POSITION',
      {'database': config.database},
    );
    return result.rows
        .map((row) {
          final values = row.assoc();
          return DatabaseForeignKey(
            table: values['table_name'] ?? '',
            column: values['column_name'] ?? '',
            referencedTable: values['referenced_table'] ?? '',
            referencedColumn: values['referenced_column'] ?? '',
            constraintName: values['constraint_name'] ?? '',
            ordinalPosition:
                int.tryParse(values['ordinal_position'] ?? '') ?? 1,
            onUpdate: values['update_rule'],
            onDelete: values['delete_rule'],
          );
        })
        .where(
          (relation) =>
              relation.table.isNotEmpty &&
              relation.column.isNotEmpty &&
              relation.referencedTable.isNotEmpty &&
              relation.referencedColumn.isNotEmpty,
        )
        .toList(growable: false);
  }

  @override
  Future<List<DatabaseTableIndex>> listIndexes(String table) async {
    final result = await _requireConnection().execute(
      'SELECT INDEX_NAME AS name, NON_UNIQUE AS non_unique, '
      'INDEX_TYPE AS index_type, COLUMN_NAME AS column_name '
      'FROM information_schema.statistics '
      'WHERE TABLE_SCHEMA = :database AND TABLE_NAME = :table '
      'ORDER BY INDEX_NAME, SEQ_IN_INDEX',
      {'database': config.database, 'table': table},
    );
    final indexes = <String, DatabaseTableIndex>{};
    for (final row in result.rows) {
      final values = row.assoc();
      final name = values['name'] ?? '';
      if (name.isEmpty) continue;
      final column = values['column_name'];
      final current = indexes[name];
      if (current == null) {
        indexes[name] = DatabaseTableIndex(
          name: name,
          isUnique: values['non_unique'] == '0',
          type: values['index_type'] ?? '',
          columns: column == null ? const [] : [column],
        );
      } else if (column != null) {
        indexes[name] = DatabaseTableIndex(
          name: current.name,
          isUnique: current.isUnique,
          type: current.type,
          columns: [...current.columns, column],
        );
      }
    }
    return indexes.values.toList(growable: false);
  }

  @override
  Future<List<DatabaseTableTrigger>> listTriggers(String table) async {
    final result = await _requireConnection().execute(
      'SELECT TRIGGER_NAME AS name, ACTION_TIMING AS timing, '
      'EVENT_MANIPULATION AS event, ACTION_STATEMENT AS statement '
      'FROM information_schema.triggers '
      'WHERE TRIGGER_SCHEMA = :database AND EVENT_OBJECT_TABLE = :table '
      'ORDER BY ACTION_TIMING, EVENT_MANIPULATION, TRIGGER_NAME',
      {'database': config.database, 'table': table},
    );
    return result.rows
        .map((row) {
          final values = row.assoc();
          return DatabaseTableTrigger(
            name: values['name'] ?? '',
            timing: values['timing'] ?? '',
            event: values['event'] ?? '',
            statement: values['statement'] ?? '',
          );
        })
        .where((trigger) => trigger.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<String?> showCreateTable(String table) async {
    final result = await _requireConnection().execute(
      'SHOW CREATE TABLE ${_quoteIdentifier(table)}',
    );
    if (result.rows.isEmpty) return null;
    final values = result.rows.first.assoc();
    return values['Create Table'] ??
        values['Create View'] ??
        (values.length > 1 ? values.values.elementAt(1) : null);
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

  DatabaseColumn _columnFromValues(Map<String, String?> values) {
    final type = values['type'] ?? '';
    return DatabaseColumn(
      name: values['name'] ?? '',
      type: type,
      isNullable: (values['nullable'] ?? '').toUpperCase() == 'YES',
      enumValues: parseEnumValues(type),
    );
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
            type: displayColumnType(column.type.intVal),
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

  static List<String> parseEnumValues(String columnType) {
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

  /// Converts MySQL wire-protocol type codes into labels suitable for the UI.
  static String displayColumnType(int type) => switch (type) {
    0 => 'DECIMAL',
    1 => 'TINYINT',
    2 => 'SMALLINT',
    3 => 'INT',
    4 => 'FLOAT',
    5 => 'DOUBLE',
    6 => 'NULL',
    7 || 17 => 'TIMESTAMP',
    8 => 'BIGINT',
    9 => 'MEDIUMINT',
    10 || 14 => 'DATE',
    11 || 19 => 'TIME',
    12 || 18 => 'DATETIME',
    13 => 'YEAR',
    15 || 253 => 'VARCHAR',
    16 => 'BIT',
    246 => 'DECIMAL',
    247 => 'ENUM',
    248 => 'SET',
    249 => 'TINYBLOB',
    250 => 'MEDIUMBLOB',
    251 => 'LONGBLOB',
    252 => 'BLOB',
    254 => 'CHAR',
    255 => 'GEOMETRY',
    _ => 'MySQL type $type',
  };
}
