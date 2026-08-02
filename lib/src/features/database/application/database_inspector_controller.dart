import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../contracts/database_inspector_client.dart';
import '../contracts/database_inspector_controller_contract.dart';
import '../contracts/database_query_history_store.dart';
import '../contracts/database_query_tab_session_store.dart';
import '../contracts/database_saved_query_store.dart';
import '../data/database_query_history_store.dart';
import '../data/database_query_tab_session_store.dart';
import '../data/database_saved_query_store.dart';
import 'database_inspector_state.dart';
import '../domain/database_models.dart';
import '../domain/database_foreign_key_query_builder.dart';
import '../domain/database_query_history_entry.dart';
import '../domain/database_saved_query.dart';
import '../domain/query_tabs_controller.dart';
import '../domain/sql/read_only_sql_validator.dart';
import '../domain/sql/sql_autocomplete.dart';

typedef DatabaseInspectorClientFactory =
    DatabaseInspectorClient Function(MySqlInspectorConfig config);

/// Owns a single read-only database-inspector session.
class DatabaseInspectorController extends DatabaseInspectorControllerContract {
  factory DatabaseInspectorController({
    required MySqlInspectorConfig? Function() configProvider,
    required DatabaseInspectorClientFactory clientFactory,
    bool Function()? shouldReleaseInactiveQueryResults,
    bool Function()? shouldStoreQueryHistory,
    Duration? Function()? idleTimeoutProvider,
    DatabaseQueryHistoryStore? queryHistoryStore,
    DatabaseQueryTabSessionStore? queryTabSessionStore,
    DatabaseSavedQueryStore? savedQueryStore,
  }) => DatabaseInspectorController._(
    configProvider,
    clientFactory,
    shouldReleaseInactiveQueryResults ?? _neverReleaseInactiveQueryResults,
    shouldStoreQueryHistory ?? _alwaysStoreQueryHistory,
    idleTimeoutProvider ?? _idleDisconnectDisabled,
    queryHistoryStore ?? LocalDatabaseQueryHistoryStore(),
    queryTabSessionStore ?? LocalDatabaseQueryTabSessionStore(),
    savedQueryStore ?? LocalDatabaseSavedQueryStore(),
  );

  DatabaseInspectorController._(
    this._configProvider,
    this._clientFactory,
    this._shouldReleaseInactiveQueryResults,
    this._shouldStoreQueryHistory,
    this._idleTimeoutProvider,
    this._queryHistoryStore,
    this._queryTabSessionStore,
    this._savedQueryStore,
  ) : super(const DatabaseInspectorState());

  static bool _neverReleaseInactiveQueryResults() => false;
  static bool _alwaysStoreQueryHistory() => true;
  static Duration? _idleDisconnectDisabled() => null;

  final MySqlInspectorConfig? Function() _configProvider;
  final DatabaseInspectorClientFactory _clientFactory;
  final bool Function() _shouldReleaseInactiveQueryResults;
  final bool Function() _shouldStoreQueryHistory;
  final Duration? Function() _idleTimeoutProvider;
  final DatabaseQueryHistoryStore _queryHistoryStore;
  final DatabaseQueryTabSessionStore _queryTabSessionStore;
  final DatabaseSavedQueryStore _savedQueryStore;
  final QueryTabsController _queryTabs = QueryTabsController();
  final Set<String> _loadingAutocompleteColumns = {};
  DatabaseInspectorClient? _client;
  Timer? _idleTimer;
  var _queryRunVersion = 0;

  @override
  List<DatabaseQueryTab> get queryTabs => _queryTabs.tabs;

  @override
  DatabaseQueryTab get activeQueryTab => _queryTabs.active;

  @override
  void init() {}

  @override
  Future<void> connect() async {
    final config = _configProvider();
    if (config == null || value.isBusy) return;
    _set(value.copyWith(isBusy: true, clearError: true));
    final client = _clientFactory(config);
    try {
      await client.connect();
      final tables = _sortTables(await client.listTables());
      final columnsByTable = await client.listAllColumns();
      final foreignKeys = await _listForeignKeysOrEmpty(client);
      final keywords = await _listKeywordsOrEmpty(client);
      final queryHistory = _shouldStoreQueryHistory()
          ? await _queryHistoryStore.read(_historyScope(config))
          : const <DatabaseQueryHistoryEntry>[];
      final savedTabs = await _queryTabSessionStore.read(_historyScope(config));
      final savedQueries = await _savedQueryStore.read(_historyScope(config));
      _queryTabs.restore(savedTabs);
      _client = client;
      _rescheduleIdleDisconnect();
      _set(
        value.copyWith(
          isConnected: true,
          isBusy: false,
          tables: tables,
          columnsByTable: columnsByTable,
          foreignKeys: foreignKeys,
          keywords: keywords,
          queryHistory: queryHistory,
          savedQueries: savedQueries,
        ),
      );
    } catch (error) {
      await client.disconnect();
      _set(value.copyWith(isBusy: false, error: _safeError(error, config)));
    }
  }

  @override
  Future<void> disconnect() async {
    final client = _client;
    if (client == null || value.isBusy) return;
    _set(value.copyWith(isBusy: true));
    await client.disconnect();
    _client = null;
    _loadingAutocompleteColumns.clear();
    _set(const DatabaseInspectorState());
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  @override
  Future<void> refreshTables() async {
    final client = _client;
    final config = _configProvider();
    if (client == null || config == null || value.isBusy) return;
    _set(value.copyWith(isBusy: true, clearError: true));
    try {
      final tables = _sortTables(await client.listTables());
      final columnsByTable = await client.listAllColumns();
      final foreignKeys = await _listForeignKeysOrEmpty(client);
      final keywords = await _listKeywordsOrEmpty(client);
      _set(
        value.copyWith(
          isBusy: false,
          tables: tables,
          columnsByTable: columnsByTable,
          foreignKeys: foreignKeys,
          keywords: keywords,
        ),
      );
    } catch (error) {
      _set(value.copyWith(isBusy: false, error: _safeError(error, config)));
    }
  }

  @override
  Future<void> openTable(String table, {int offset = 0}) async {
    final client = _client;
    final config = _configProvider();
    if (client == null || config == null || value.isBusy) return;
    _rescheduleIdleDisconnect();
    _set(value.copyWith(isBusy: true, clearError: true));
    try {
      final columns =
          value.columnsByTable[table] ?? await client.listColumns(table);
      final indexes =
          value.indexesByTable[table] ?? await client.listIndexes(table);
      final triggers =
          value.triggersByTable[table] ??
          await _listTriggersOrEmpty(client, table);
      final ddl =
          value.ddlByTable[table] ??
          await _showCreateTableOrNull(client, table);
      final page = await client.fetchRows(
        table: table,
        offset: offset,
        limit: config.pageSize,
      );
      _set(
        value.copyWith(
          isBusy: false,
          tableColumns: columns,
          columnsByTable: {...value.columnsByTable, table: columns},
          indexesByTable: {...value.indexesByTable, table: indexes},
          triggersByTable: {...value.triggersByTable, table: triggers},
          ddlByTable: ddl == null
              ? value.ddlByTable
              : {...value.ddlByTable, table: ddl},
          page: page,
          selectedTable: table,
          offset: offset,
        ),
      );
    } catch (error) {
      _set(value.copyWith(isBusy: false, error: _safeError(error, config)));
    }
  }

  @override
  Future<void> runQuery(String query) async {
    final client = _client;
    final config = _configProvider();
    if (client == null || config == null || value.isBusy) return;
    _rescheduleIdleDisconnect();
    final validation = ReadOnlySqlValidator.validate(
      query,
      maximumRows: config.maxPageSize,
    );
    if (!validation.isAllowed) {
      _set(value.copyWith(error: validation.reason));
      return;
    }
    final runVersion = ++_queryRunVersion;
    _set(value.copyWith(isBusy: true, isQueryRunning: true, clearError: true));
    try {
      final page = await client
          .executeReadOnly(validation.executionSql!)
          .timeout(config.executionTimeout);
      if (runVersion != _queryRunVersion) return;
      _queryTabs.updateActiveResult(page);
      _recordQueryHistory(query, config);
      _set(
        value.copyWith(
          isBusy: false,
          isQueryRunning: false,
          page: page,
          tableColumns: const [],
          clearSelectedTable: true,
          offset: 0,
        ),
      );
    } on TimeoutException {
      if (runVersion != _queryRunVersion) return;
      await _endQuerySession(
        client,
        'Query timed out after ${config.executionTimeout.inSeconds} seconds. '
        'The database connection was closed.',
      );
    } catch (error) {
      if (runVersion != _queryRunVersion) return;
      _set(
        value.copyWith(
          isBusy: false,
          isQueryRunning: false,
          error: _safeError(error, config),
        ),
      );
    }
  }

  @override
  Future<void> cancelQuery() async {
    final client = _client;
    if (client == null || !value.isQueryRunning) return;
    _queryRunVersion++;
    await _endQuerySession(
      client,
      'Query cancelled. The database connection was closed.',
    );
  }

  Future<void> _endQuerySession(
    DatabaseInspectorClient client,
    String message,
  ) async {
    try {
      await client.cancelActiveQuery();
    } catch (_) {
      // The session is treated as unusable whether closing succeeds or not.
    }
    if (!identical(_client, client)) return;
    _client = null;
    _loadingAutocompleteColumns.clear();
    _set(DatabaseInspectorState(error: message));
  }

  @override
  void updateActiveDraft(String draft) {
    _queryTabs.updateActiveDraft(draft);
    _saveQueryTabs();
    _rescheduleIdleDisconnect();
  }

  @override
  void createQueryTab() {
    if (value.isBusy) return;
    _queryTabs.createTab();
    _releaseInactiveQueryResultsIfEnabled();
    _showActiveTab();
    _saveQueryTabs();
  }

  @override
  void selectQueryTab(String id) {
    if (value.isBusy || _queryTabs.active.id == id) return;
    _queryTabs.select(id);
    _releaseInactiveQueryResultsIfEnabled();
    _showActiveTab();
    _saveQueryTabs();
  }

  @override
  void renameQueryTab(String id, String name) {
    if (value.isBusy || !_queryTabs.rename(id, name)) return;
    _set(value.copyWith());
    _saveQueryTabs();
  }

  @override
  void closeQueryTab(String id) {
    if (value.isBusy || !_queryTabs.close(id)) return;
    _releaseInactiveQueryResultsIfEnabled();
    _showActiveTab();
    _saveQueryTabs();
  }

  @override
  void clearQueryHistory() {
    final config = _configProvider();
    if (config == null || value.queryHistory.isEmpty) return;
    _set(value.copyWith(queryHistory: const []));
    unawaited(_queryHistoryStore.write(_historyScope(config), const []));
  }

  @override
  void deleteQueryHistory(DatabaseQueryHistoryEntry entry) {
    final config = _configProvider();
    if (config == null || !value.queryHistory.contains(entry)) return;
    final entries = value.queryHistory
        .where((item) => !identical(item, entry))
        .toList(growable: false);
    _set(value.copyWith(queryHistory: entries));
    unawaited(_queryHistoryStore.write(_historyScope(config), entries));
  }

  @override
  void saveQuery({
    required String name,
    required String sql,
    String folder = '',
  }) {
    final config = _configProvider();
    final normalizedName = name.trim();
    final normalizedSql = sql.trim();
    final normalizedFolder = folder.trim();
    if (config == null || normalizedName.isEmpty || normalizedSql.isEmpty) {
      return;
    }
    final validation = ReadOnlySqlValidator.validate(
      normalizedSql,
      maximumRows: config.maxPageSize,
    );
    if (!validation.isAllowed) {
      _set(value.copyWith(error: validation.reason));
      return;
    }
    final scope = _historyScope(config);
    final entry = DatabaseSavedQuery(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      scope: scope,
      name: normalizedName,
      sql: normalizedSql,
      savedAt: DateTime.now(),
      folder: normalizedFolder,
    );
    final entries = [
      entry,
      ...value.savedQueries.where(
        (item) =>
            item.name.toLowerCase() != normalizedName.toLowerCase() ||
            item.folder.toLowerCase() != normalizedFolder.toLowerCase(),
      ),
    ].take(50).toList(growable: false);
    _set(value.copyWith(savedQueries: entries, clearError: true));
    unawaited(_savedQueryStore.write(scope, entries));
  }

  @override
  void deleteSavedQuery(String id) {
    final config = _configProvider();
    if (config == null) return;
    final entries = value.savedQueries
        .where((entry) => entry.id != id)
        .toList(growable: false);
    if (entries.length == value.savedQueries.length) return;
    _set(value.copyWith(savedQueries: entries));
    unawaited(_savedQueryStore.write(_historyScope(config), entries));
  }

  @override
  Future<void> inspectRelatedData(
    DatabaseForeignKey relation,
    String foreignKeyValue,
  ) => inspectRelatedDataForRow(relation, {relation.column: foreignKeyValue});

  @override
  Future<void> inspectRelatedDataForRow(
    DatabaseForeignKey relation,
    Map<String, String?> row,
  ) async {
    final config = _configProvider();
    if (config == null || value.isBusy) return;
    final sourceIsKnown =
        relation.table.isEmpty ||
        value.tables.any((table) => table.name == relation.table);
    final targetIsKnown = value.tables.any(
      (table) => table.name == relation.referencedTable,
    );
    if (!sourceIsKnown || !targetIsKnown) return;

    final sql = DatabaseForeignKeyQueryBuilder.relatedSql(
      relation: relation,
      allRelations: value.foreignKeys,
      row: row,
      limit: config.pageSize,
    );
    if (sql == null) return;
    _queryTabs.createTab();
    _queryTabs.updateActiveDraft(sql);
    _releaseInactiveQueryResultsIfEnabled();
    _showActiveTab();
    _saveQueryTabs();
    await runQuery(sql);
  }

  @override
  Future<void> inspectReferencingData(
    DatabaseForeignKey relation,
    String referencedValue,
  ) => inspectReferencingDataForRow(relation, {
    relation.referencedColumn: referencedValue,
  });

  @override
  Future<void> inspectReferencingDataForRow(
    DatabaseForeignKey relation,
    Map<String, String?> row,
  ) async {
    final config = _configProvider();
    if (config == null ||
        value.isBusy ||
        !value.tables.any((table) => table.name == relation.table)) {
      return;
    }
    final sql = DatabaseForeignKeyQueryBuilder.referencingSql(
      relation: relation,
      allRelations: value.foreignKeys,
      row: row,
      limit: config.pageSize,
    );
    if (sql == null) return;
    _queryTabs.createTab();
    _queryTabs.updateActiveDraft(sql);
    _releaseInactiveQueryResultsIfEnabled();
    _showActiveTab();
    _saveQueryTabs();
    await runQuery(sql);
  }

  @override
  List<SqlAutocompleteSuggestion> autocompleteSuggestions(
    TextEditingValue editingValue,
  ) => SqlAutocomplete.suggestions(
    editingValue: editingValue,
    tables: value.tables,
    columnsByTable: value.columnsByTable,
    keywords: value.keywords,
  );

  @override
  Future<void> loadColumnsForAutocomplete(TextEditingValue editingValue) async {
    final client = _client;
    if (client == null) return;
    final requestedTable = SqlAutocomplete.tableForActiveQualifier(
      editingValue,
    );
    if (requestedTable == null) return;
    final table = _matchingTableName(requestedTable);
    if (table == null || value.columnsByTable.containsKey(table)) return;
    if (!_loadingAutocompleteColumns.add(table)) return;
    try {
      final columns = await client.listColumns(table);
      if (!identical(client, _client)) return;
      _set(
        value.copyWith(
          columnsByTable: {...value.columnsByTable, table: columns},
        ),
      );
    } catch (_) {
      // Autocomplete is optional; browsing tables still surfaces failures.
    } finally {
      _loadingAutocompleteColumns.remove(table);
    }
  }

  @override
  void recordUserActivity() => _rescheduleIdleDisconnect();

  @override
  void clearError() {
    if (value.error != null) _set(value.copyWith(clearError: true));
  }

  @override
  void disposeController() {
    _idleTimer?.cancel();
    _client?.disconnect();
    _client = null;
    super.disposeController();
  }

  void _showActiveTab() {
    final active = _queryTabs.active;
    _set(
      value.copyWith(
        page: active.result,
        clearPage: active.result == null,
        tableColumns: const [],
        clearSelectedTable: true,
        offset: 0,
      ),
    );
  }

  void _releaseInactiveQueryResultsIfEnabled() {
    if (_shouldReleaseInactiveQueryResults()) {
      _queryTabs.evictInactiveResults();
    }
  }

  void _recordQueryHistory(String query, MySqlInspectorConfig config) {
    if (!_shouldStoreQueryHistory()) return;
    final sql = query.trim();
    if (sql.isEmpty) return;
    final entry = DatabaseQueryHistoryEntry(
      scope: _historyScope(config),
      sql: sql,
      executedAt: DateTime.now(),
    );
    final entries = [
      entry,
      ...value.queryHistory.where((item) => item.sql != sql),
    ].take(50).toList(growable: false);
    _set(value.copyWith(queryHistory: entries));
    unawaited(_queryHistoryStore.write(_historyScope(config), entries));
  }

  void _saveQueryTabs() {
    final config = _configProvider();
    if (config == null) return;
    unawaited(
      _queryTabSessionStore.write(_historyScope(config), _queryTabs.snapshot()),
    );
  }

  String _historyScope(MySqlInspectorConfig config) =>
      '${config.environmentLabel.trim().toLowerCase()}:'
      '${config.database.trim().toLowerCase()}';

  List<DatabaseTable> _sortTables(List<DatabaseTable> tables) {
    final sorted = [...tables];
    sorted.sort((first, second) {
      // MySQL's default lexical order places `_` before letters. For people
      // scanning schema names, `panens` is easier to find before `panen_*`.
      final firstName = first.name.toLowerCase().replaceAll('_', '{');
      final secondName = second.name.toLowerCase().replaceAll('_', '{');
      return firstName.compareTo(secondName);
    });
    return sorted;
  }

  String? _matchingTableName(String requestedTable) {
    for (final table in value.tables) {
      if (table.name.toLowerCase() == requestedTable.toLowerCase()) {
        return table.name;
      }
    }
    return null;
  }

  Future<List<DatabaseKeyword>> _listKeywordsOrEmpty(
    DatabaseInspectorClient client,
  ) async {
    try {
      return await client.listKeywords();
    } catch (_) {
      return const [];
    }
  }

  Future<List<DatabaseForeignKey>> _listForeignKeysOrEmpty(
    DatabaseInspectorClient client,
  ) async {
    try {
      return await client.listForeignKeys();
    } catch (_) {
      // Some least-privilege users cannot read relationship metadata.
      return const [];
    }
  }

  Future<String?> _showCreateTableOrNull(
    DatabaseInspectorClient client,
    String table,
  ) async {
    try {
      return await client.showCreateTable(table);
    } catch (_) {
      // DDL visibility may be restricted independently from SELECT access.
      return null;
    }
  }

  Future<List<DatabaseTableTrigger>> _listTriggersOrEmpty(
    DatabaseInspectorClient client,
    String table,
  ) async {
    try {
      return await client.listTriggers(table);
    } catch (_) {
      // Trigger metadata may be restricted independently from table reads.
      return const [];
    }
  }

  void _rescheduleIdleDisconnect() {
    _idleTimer?.cancel();
    _idleTimer = null;
    final timeout = _idleTimeoutProvider();
    if (_client == null || timeout == null || timeout <= Duration.zero) return;
    _idleTimer = Timer(timeout, () {
      if (_client == null) return;
      if (value.isBusy) {
        _rescheduleIdleDisconnect();
        return;
      }
      unawaited(disconnect());
    });
  }

  String _safeError(Object error, MySqlInspectorConfig config) {
    var message = error.toString();
    for (final secret in [config.password, config.username, config.host]) {
      if (secret.isNotEmpty) message = message.replaceAll(secret, '•••');
    }
    return message;
  }

  void _set(DatabaseInspectorState state) {
    value = state.copyWith(
      tables: List.unmodifiable(state.tables),
      keywords: List.unmodifiable(state.keywords),
      foreignKeys: List.unmodifiable(state.foreignKeys),
      indexesByTable: UnmodifiableMapView({
        for (final entry in state.indexesByTable.entries)
          entry.key: List.unmodifiable(entry.value),
      }),
      triggersByTable: UnmodifiableMapView({
        for (final entry in state.triggersByTable.entries)
          entry.key: List.unmodifiable(entry.value),
      }),
      ddlByTable: UnmodifiableMapView(state.ddlByTable),
      queryHistory: List.unmodifiable(state.queryHistory),
      savedQueries: List.unmodifiable(state.savedQueries),
      tableColumns: List.unmodifiable(state.tableColumns),
      columnsByTable: UnmodifiableMapView({
        for (final entry in state.columnsByTable.entries)
          entry.key: List.unmodifiable(entry.value),
      }),
    );
  }
}
