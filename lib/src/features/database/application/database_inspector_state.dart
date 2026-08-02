import '../domain/database_models.dart';
import '../domain/database_query_history_entry.dart';
import '../domain/database_saved_query.dart';

/// Immutable view state for one in-memory database inspector session.
class DatabaseInspectorState {
  const DatabaseInspectorState({
    this.isConnected = false,
    this.isBusy = false,
    this.isQueryRunning = false,
    this.tables = const [],
    this.keywords = const [],
    this.tableColumns = const [],
    this.columnsByTable = const {},
    this.foreignKeys = const [],
    this.indexesByTable = const {},
    this.triggersByTable = const {},
    this.ddlByTable = const {},
    this.queryHistory = const [],
    this.savedQueries = const [],
    this.page,
    this.selectedTable,
    this.error,
    this.offset = 0,
  });

  final bool isConnected;
  final bool isBusy;
  final bool isQueryRunning;
  final List<DatabaseTable> tables;
  final List<DatabaseKeyword> keywords;
  final List<DatabaseColumn> tableColumns;
  final Map<String, List<DatabaseColumn>> columnsByTable;
  final List<DatabaseForeignKey> foreignKeys;
  final Map<String, List<DatabaseTableIndex>> indexesByTable;
  final Map<String, List<DatabaseTableTrigger>> triggersByTable;
  final Map<String, String> ddlByTable;
  final List<DatabaseQueryHistoryEntry> queryHistory;
  final List<DatabaseSavedQuery> savedQueries;
  final DatabasePage? page;
  final String? selectedTable;
  final String? error;
  final int offset;

  DatabaseInspectorState copyWith({
    bool? isConnected,
    bool? isBusy,
    bool? isQueryRunning,
    List<DatabaseTable>? tables,
    List<DatabaseKeyword>? keywords,
    List<DatabaseColumn>? tableColumns,
    Map<String, List<DatabaseColumn>>? columnsByTable,
    List<DatabaseForeignKey>? foreignKeys,
    Map<String, List<DatabaseTableIndex>>? indexesByTable,
    Map<String, List<DatabaseTableTrigger>>? triggersByTable,
    Map<String, String>? ddlByTable,
    List<DatabaseQueryHistoryEntry>? queryHistory,
    List<DatabaseSavedQuery>? savedQueries,
    DatabasePage? page,
    bool clearPage = false,
    String? selectedTable,
    bool clearSelectedTable = false,
    String? error,
    bool clearError = false,
    int? offset,
  }) => DatabaseInspectorState(
    isConnected: isConnected ?? this.isConnected,
    isBusy: isBusy ?? this.isBusy,
    isQueryRunning: isQueryRunning ?? this.isQueryRunning,
    tables: tables ?? this.tables,
    keywords: keywords ?? this.keywords,
    tableColumns: tableColumns ?? this.tableColumns,
    columnsByTable: columnsByTable ?? this.columnsByTable,
    foreignKeys: foreignKeys ?? this.foreignKeys,
    indexesByTable: indexesByTable ?? this.indexesByTable,
    triggersByTable: triggersByTable ?? this.triggersByTable,
    ddlByTable: ddlByTable ?? this.ddlByTable,
    queryHistory: queryHistory ?? this.queryHistory,
    savedQueries: savedQueries ?? this.savedQueries,
    page: clearPage ? null : page ?? this.page,
    selectedTable: clearSelectedTable
        ? null
        : selectedTable ?? this.selectedTable,
    error: clearError ? null : error ?? this.error,
    offset: offset ?? this.offset,
  );
}
