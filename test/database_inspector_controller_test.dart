import 'dart:async';

import 'package:dio_network_inspector/src/features/database/contracts/database_inspector_client.dart';
import 'package:dio_network_inspector/src/features/database/contracts/database_query_history_store.dart';
import 'package:dio_network_inspector/src/features/database/contracts/database_saved_query_store.dart';
import 'package:dio_network_inspector/src/features/database/application/database_inspector_controller.dart';
import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:dio_network_inspector/src/features/database/domain/database_query_history_entry.dart';
import 'package:dio_network_inspector/src/features/database/domain/database_saved_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('connects, loads metadata, and executes a read-only query', () async {
    final client = _FakeDatabaseInspectorClient();
    final controller = DatabaseInspectorController(
      configProvider: () => const MySqlInspectorConfig(
        host: 'localhost',
        port: 3306,
        database: 'voltunes',
        username: 'readonly',
        password: 'secret',
      ),
      clientFactory: (_) => client,
      queryHistoryStore: _FakeQueryHistoryStore(),
      savedQueryStore: _FakeSavedQueryStore(),
    );

    await controller.connect();

    expect(controller.value.isConnected, isTrue);
    expect(controller.value.tables.single.name, 'users');
    expect(controller.value.columnsByTable['users']!.single.name, 'id');

    await controller.runQuery('SELECT id FROM users');

    expect(client.executedSql, 'SELECT id FROM users LIMIT 100');
    expect(controller.value.page!.rows.single['id'], '7');
    expect(controller.value.selectedTable, isNull);

    controller.disposeController();
  });

  test(
    'sorts table names with base tables before underscored variants',
    () async {
      final controller = DatabaseInspectorController(
        configProvider: () => const MySqlInspectorConfig(
          host: 'localhost',
          port: 3306,
          database: 'voltunes',
          username: 'readonly',
          password: 'secret',
        ),
        clientFactory: (_) => _FakeDatabaseInspectorClient(
          tables: const [
            DatabaseTable(name: 'panen_returns'),
            DatabaseTable(name: 'panen_details'),
            DatabaseTable(name: 'panens'),
          ],
        ),
        queryHistoryStore: _FakeQueryHistoryStore(),
        savedQueryStore: _FakeSavedQueryStore(),
      );

      await controller.connect();

      expect(
        controller.value.tables.map((table) => table.name),
        orderedEquals(['panens', 'panen_details', 'panen_returns']),
      );
      controller.disposeController();
    },
  );

  test(
    'releases inactive query results only when the global option is on',
    () async {
      var releaseInactiveResults = false;
      final controller = DatabaseInspectorController(
        configProvider: () => const MySqlInspectorConfig(
          host: 'localhost',
          port: 3306,
          database: 'voltunes',
          username: 'readonly',
          password: 'secret',
        ),
        clientFactory: (_) => _FakeDatabaseInspectorClient(),
        shouldReleaseInactiveQueryResults: () => releaseInactiveResults,
        queryHistoryStore: _FakeQueryHistoryStore(),
        savedQueryStore: _FakeSavedQueryStore(),
      );
      await controller.connect();

      await controller.runQuery('SELECT id FROM users');
      final firstTab = controller.activeQueryTab;
      controller.createQueryTab();

      expect(firstTab.result, isNotNull);

      await controller.runQuery('SELECT id FROM users');
      releaseInactiveResults = true;
      controller.selectQueryTab(firstTab.id);

      expect(controller.queryTabs[1].result, isNull);
      expect(controller.queryTabs[1].resultWasEvicted, isTrue);
      controller.disposeController();
    },
  );

  test('stores successful queries without duplicating the same SQL', () async {
    final historyStore = _FakeQueryHistoryStore();
    final controller = DatabaseInspectorController(
      configProvider: () => const MySqlInspectorConfig(
        host: 'localhost',
        port: 3306,
        database: 'voltunes',
        username: 'readonly',
        password: 'secret',
      ),
      clientFactory: (_) => _FakeDatabaseInspectorClient(),
      queryHistoryStore: historyStore,
      savedQueryStore: _FakeSavedQueryStore(),
    );
    await controller.connect();

    await controller.runQuery('SELECT id FROM users');
    await controller.runQuery('SELECT id FROM users');

    expect(controller.value.queryHistory, hasLength(1));
    expect(controller.value.queryHistory.single.sql, 'SELECT id FROM users');
    expect(historyStore.entries, hasLength(1));
    controller.disposeController();
  });

  test('keeps production query history private by default', () async {
    final historyStore = _FakeQueryHistoryStore();
    final controller = DatabaseInspectorController(
      configProvider: () => const MySqlInspectorConfig(
        host: 'localhost',
        port: 3306,
        database: 'voltunes',
        username: 'readonly',
        password: 'secret',
        environmentLabel: 'production',
      ),
      clientFactory: (_) => _FakeDatabaseInspectorClient(),
      shouldStoreQueryHistory: () => false,
      queryHistoryStore: historyStore,
      savedQueryStore: _FakeSavedQueryStore(),
    );
    await controller.connect();
    await controller.runQuery('SELECT id FROM users');

    expect(controller.value.queryHistory, isEmpty);
    expect(historyStore.entries, isEmpty);
    controller.disposeController();
  });

  test('removes one query history entry without clearing the others', () async {
    final historyStore = _FakeQueryHistoryStore();
    final controller = DatabaseInspectorController(
      configProvider: () => const MySqlInspectorConfig(
        host: 'localhost',
        port: 3306,
        database: 'voltunes',
        username: 'readonly',
        password: 'secret',
      ),
      clientFactory: (_) => _FakeDatabaseInspectorClient(),
      queryHistoryStore: historyStore,
      savedQueryStore: _FakeSavedQueryStore(),
    );
    await controller.connect();
    await controller.runQuery('SELECT id FROM users');
    await controller.runQuery('SELECT name FROM users');

    final entryToDelete = controller.value.queryHistory.last;
    controller.deleteQueryHistory(entryToDelete);

    expect(controller.value.queryHistory, hasLength(1));
    expect(controller.value.queryHistory.single.sql, 'SELECT name FROM users');
    expect(historyStore.entries, hasLength(1));
    controller.disposeController();
  });

  test('cancelling a running query closes the inspector session', () async {
    final pendingQuery = Completer<DatabasePage>();
    final client = _FakeDatabaseInspectorClient(pendingQuery: pendingQuery);
    final controller = DatabaseInspectorController(
      configProvider: () => const MySqlInspectorConfig(
        host: 'localhost',
        port: 3306,
        database: 'voltunes',
        username: 'readonly',
        password: 'secret',
      ),
      clientFactory: (_) => client,
      queryHistoryStore: _FakeQueryHistoryStore(),
      savedQueryStore: _FakeSavedQueryStore(),
    );
    await controller.connect();

    final runningQuery = controller.runQuery('SELECT id FROM users');
    expect(controller.value.isQueryRunning, isTrue);

    await controller.cancelQuery();
    await runningQuery;

    expect(client.cancelled, isTrue);
    expect(controller.value.isConnected, isFalse);
    expect(controller.value.isQueryRunning, isFalse);
    expect(controller.value.error, contains('Query cancelled'));
    controller.disposeController();
  });

  test('loads read-only structure metadata when opening a table', () async {
    final controller = DatabaseInspectorController(
      configProvider: () => const MySqlInspectorConfig(
        host: 'localhost',
        port: 3306,
        database: 'voltunes',
        username: 'readonly',
        password: 'secret',
      ),
      clientFactory: (_) => _FakeDatabaseInspectorClient(),
      queryHistoryStore: _FakeQueryHistoryStore(),
      savedQueryStore: _FakeSavedQueryStore(),
    );
    await controller.connect();

    await controller.openTable('users');

    expect(controller.value.selectedTable, 'users');
    expect(controller.value.indexesByTable['users']!.single.name, 'PRIMARY');
    expect(
      controller.value.triggersByTable['users']!.single.name,
      'users_before_insert',
    );
    expect(controller.value.ddlByTable['users'], contains('CREATE TABLE'));
    expect(controller.value.foreignKeys.single.onUpdate, 'CASCADE');
    expect(controller.value.foreignKeys.single.onDelete, 'SET NULL');
    controller.disposeController();
  });

  test('saves named read-only queries locally per database scope', () async {
    final savedQueryStore = _FakeSavedQueryStore();
    final controller = DatabaseInspectorController(
      configProvider: () => const MySqlInspectorConfig(
        host: 'localhost',
        port: 3306,
        database: 'voltunes',
        username: 'readonly',
        password: 'secret',
      ),
      clientFactory: (_) => _FakeDatabaseInspectorClient(),
      queryHistoryStore: _FakeQueryHistoryStore(),
      savedQueryStore: savedQueryStore,
    );
    await controller.connect();

    controller.saveQuery(
      name: 'Find users',
      folder: 'People',
      sql: 'SELECT id FROM users',
    );
    controller.saveQuery(
      name: 'find USERS',
      folder: 'People',
      sql: 'SELECT name FROM users',
    );

    expect(controller.value.savedQueries, hasLength(1));
    expect(controller.value.savedQueries.single.name, 'find USERS');
    expect(controller.value.savedQueries.single.sql, 'SELECT name FROM users');
    expect(controller.value.savedQueries.single.folder, 'People');
    expect(savedQueryStore.entries, hasLength(1));
    controller.disposeController();
  });

  test('prepares a safely escaped related-data query in a new tab', () async {
    final controller = DatabaseInspectorController(
      configProvider: () => const MySqlInspectorConfig(
        host: 'localhost',
        port: 3306,
        database: 'voltunes',
        username: 'readonly',
        password: 'secret',
      ),
      clientFactory: (_) => _FakeDatabaseInspectorClient(),
      queryHistoryStore: _FakeQueryHistoryStore(),
      savedQueryStore: _FakeSavedQueryStore(),
    );
    await controller.connect();

    await controller.inspectRelatedData(
      controller.value.foreignKeys.single,
      "parent'\\id",
    );

    expect(controller.queryTabs, hasLength(2));
    expect(
      controller.activeQueryTab.draft,
      "SELECT * FROM `users` WHERE `id` = 'parent\\'\\\\id' LIMIT 50;",
    );
    expect(
      controller.value.page!.rows.single['id'],
      '7',
      reason: 'related data is executed directly in the newly-created tab',
    );
    controller.disposeController();
  });

  test(
    'prepares a safely escaped reverse foreign-key query in a new tab',
    () async {
      final controller = DatabaseInspectorController(
        configProvider: () => const MySqlInspectorConfig(
          host: 'localhost',
          port: 3306,
          database: 'voltunes',
          username: 'readonly',
          password: 'secret',
        ),
        clientFactory: (_) => _FakeDatabaseInspectorClient(),
        queryHistoryStore: _FakeQueryHistoryStore(),
        savedQueryStore: _FakeSavedQueryStore(),
      );
      await controller.connect();
      await controller.inspectReferencingData(
        controller.value.foreignKeys.single,
        "parent'\\id",
      );
      expect(
        controller.activeQueryTab.draft,
        "SELECT * FROM `users` WHERE `parent_id` = 'parent\\'\\\\id' LIMIT 50;",
      );
      controller.disposeController();
    },
  );
}

class _FakeQueryHistoryStore implements DatabaseQueryHistoryStore {
  List<DatabaseQueryHistoryEntry> entries = const [];

  @override
  Future<List<DatabaseQueryHistoryEntry>> read(String scope) async =>
      entries.where((entry) => entry.scope == scope).toList(growable: false);

  @override
  Future<void> write(
    String scope,
    List<DatabaseQueryHistoryEntry> entries,
  ) async {
    this.entries = entries;
  }
}

class _FakeSavedQueryStore implements DatabaseSavedQueryStore {
  List<DatabaseSavedQuery> entries = const [];

  @override
  Future<List<DatabaseSavedQuery>> read(String scope) async =>
      entries.where((entry) => entry.scope == scope).toList(growable: false);

  @override
  Future<void> write(String scope, List<DatabaseSavedQuery> entries) async {
    this.entries = entries;
  }
}

class _FakeDatabaseInspectorClient implements DatabaseInspectorClient {
  _FakeDatabaseInspectorClient({
    this.tables = const [DatabaseTable(name: 'users')],
    this.pendingQuery,
  });

  final List<DatabaseTable> tables;
  final Completer<DatabasePage>? pendingQuery;
  var connected = false;
  var cancelled = false;
  String? executedSql;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect() async {
    connected = true;
  }

  @override
  Future<void> disconnect() async {
    connected = false;
  }

  @override
  Future<void> cancelActiveQuery() async {
    cancelled = true;
    if (pendingQuery != null && !pendingQuery!.isCompleted) {
      pendingQuery!.completeError(StateError('Query cancelled.'));
    }
    await disconnect();
  }

  @override
  Future<DatabasePage> executeReadOnly(String sql) async {
    executedSql = sql;
    if (pendingQuery != null) return pendingQuery!.future;
    return const DatabasePage(
      columns: [DatabaseColumn(name: 'id', type: 'bigint')],
      rows: [
        {'id': '7'},
      ],
      offset: 0,
      limit: 100,
      hasMore: false,
    );
  }

  @override
  Future<DatabasePage> fetchRows({
    required String table,
    required int offset,
    required int limit,
  }) async => DatabasePage(
    columns: const [DatabaseColumn(name: 'id', type: 'bigint')],
    rows: const [
      {'id': '7'},
    ],
    offset: offset,
    limit: limit,
    hasMore: false,
  );

  @override
  Future<Map<String, List<DatabaseColumn>>> listAllColumns() async => const {
    'users': [DatabaseColumn(name: 'id', type: 'bigint')],
  };

  @override
  Future<List<DatabaseColumn>> listColumns(String table) async => const [
    DatabaseColumn(name: 'id', type: 'bigint'),
  ];

  @override
  Future<List<DatabaseKeyword>> listKeywords() async => const [
    DatabaseKeyword(word: 'SELECT', isReserved: true),
  ];

  @override
  Future<List<DatabaseTable>> listTables() async => tables;

  @override
  Future<List<DatabaseForeignKey>> listForeignKeys() async => const [
    DatabaseForeignKey(
      table: 'users',
      column: 'parent_id',
      referencedTable: 'users',
      referencedColumn: 'id',
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    ),
  ];

  @override
  Future<List<DatabaseTableIndex>> listIndexes(String table) async => const [
    DatabaseTableIndex(
      name: 'PRIMARY',
      isUnique: true,
      type: 'BTREE',
      columns: ['id'],
    ),
  ];

  @override
  Future<List<DatabaseTableTrigger>> listTriggers(String table) async => const [
    DatabaseTableTrigger(
      name: 'users_before_insert',
      timing: 'BEFORE',
      event: 'INSERT',
      statement: 'SET NEW.created_at = NOW()',
    ),
  ];

  @override
  Future<String?> showCreateTable(String table) async =>
      'CREATE TABLE `users` (`id` bigint NOT NULL)';
}
