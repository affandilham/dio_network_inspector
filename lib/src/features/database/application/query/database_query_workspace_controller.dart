import 'package:flutter/widgets.dart';

import 'active_statement_text_controller.dart';
import 'database_query_history_inserter.dart';
import '../../contracts/database_inspector_controller_contract.dart';
import '../../domain/database_models.dart';
import 'database_query_workspace_state.dart';
import '../../domain/sql/read_only_sql_validator.dart';
import '../../domain/sql/sql_autocomplete.dart';
import '../../domain/sql/sql_error_line.dart';
import '../../domain/sql/sql_statement_parser.dart';

/// Coordinates editor state without depending on the workspace widget tree.
///
/// The database-session contract is the only dependency, which keeps this
/// controller unit-testable and avoids coupling editor behaviour to MySQL UI.
class DatabaseQueryWorkspaceController
    extends ValueNotifier<DatabaseQueryWorkspaceState> {
  DatabaseQueryWorkspaceController({
    required this._inspector,
    required this._maximumRows,
  }) : super(const DatabaseQueryWorkspaceState());

  final DatabaseInspectorControllerContract _inspector;
  final int _maximumRows;
  final ActiveStatementTextEditingController queryController =
      ActiveStatementTextEditingController();
  final FocusNode focusNode = FocusNode();
  var _lastEditorText = '';
  String? _activeTabId;

  DatabaseInspectorControllerContract get inspector => _inspector;

  SqlStatementRange? get activeStatement => SqlStatementParser.activeStatement(
    queryController.text,
    queryController.selection,
  );

  ReadOnlySqlValidation get validation {
    final statement = activeStatement;
    if (statement == null) {
      return const ReadOnlySqlValidation.blocked(
        'Place the cursor inside a SQL statement to run it.',
      );
    }
    return ReadOnlySqlValidator.validate(
      statement.sourceFrom(queryController.text),
      maximumRows: _maximumRows,
    );
  }

  bool get canExplain {
    final statement = activeStatement;
    if (statement == null || !validation.isAllowed) return false;
    final source = statement.sourceFrom(queryController.text).trimLeft();
    return RegExp(r'^(select|with)\b', caseSensitive: false).hasMatch(source);
  }

  void init() {
    queryController.text = _inspector.activeQueryTab.draft;
    _activeTabId = _inspector.activeQueryTab.id;
    _lastEditorText = queryController.text;
    queryController.addListener(_onQueryChanged);
    focusNode.addListener(_onFocusChanged);
    _inspector.addListener(_onInspectorChanged);
    _syncActiveStatement();
    refreshSuggestions();
  }

  void refreshSuggestions() {
    final suggestions = _inspector.autocompleteSuggestions(
      queryController.value,
    );
    value = value.copyWith(suggestions: suggestions, highlightedIndex: 0);
  }

  void openSuggestions() {
    value = value.copyWith(isDismissed: false);
    refreshSuggestions();
  }

  void toggleHistory() => value = value.copyWith(
    isHistoryOpen: !value.isHistoryOpen,
    isSavedQueriesOpen: false,
  );

  void toggleSavedQueries() => value = value.copyWith(
    isHistoryOpen: false,
    isSavedQueriesOpen: !value.isSavedQueriesOpen,
  );

  void insertHistoryQuery(String sql) {
    queryController.value = DatabaseQueryHistoryInserter.insert(
      queryController.value,
      historySql: sql,
    );
    value = value.copyWith(isHistoryOpen: false);
  }

  void insertSavedQuery(String sql) {
    queryController.value = DatabaseQueryHistoryInserter.insert(
      queryController.value,
      historySql: sql,
    );
    value = value.copyWith(isSavedQueriesOpen: false);
  }

  void dismissSuggestions() {
    if (!value.hasSuggestions) return;
    value = value.copyWith(isDismissed: true);
  }

  void selectHighlightedSuggestion() {
    if (!value.hasSuggestions) return;
    selectSuggestion(value.suggestions[value.highlightedIndex]);
  }

  void selectSuggestion(SqlAutocompleteSuggestion suggestion) {
    queryController.value = SqlAutocomplete.applySuggestion(
      editingValue: queryController.value,
      value: suggestion.value,
    );
    value = value.copyWith(isDismissed: true);
  }

  void deleteSelected() {
    final editingValue = queryController.value;
    final selection = editingValue.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final start = selection.start;
    final end = selection.end;
    queryController.value = editingValue.copyWith(
      text: editingValue.text.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
      composing: TextRange.empty,
    );
  }

  void insertLineBreak() {
    final editingValue = queryController.value;
    final selection = editingValue.selection;
    final start = selection.isValid
        ? selection.start
        : editingValue.text.length;
    final end = selection.isValid ? selection.end : editingValue.text.length;
    queryController.value = editingValue.copyWith(
      text: editingValue.text.replaceRange(start, end, '\n'),
      selection: TextSelection.collapsed(offset: start + 1),
      composing: TextRange.empty,
    );
  }

  /// Moves autocomplete selection and returns whether navigation wrapped.
  bool moveHighlight(int delta) {
    final count = value.suggestions.length;
    if (count == 0) return false;
    final previousIndex = value.highlightedIndex;
    final nextIndex = (previousIndex + delta + count) % count;
    value = value.copyWith(highlightedIndex: nextIndex);
    return delta > 0 ? nextIndex < previousIndex : nextIndex > previousIndex;
  }

  void createQueryTab() {
    _inspector.updateActiveDraft(queryController.text);
    _inspector.createQueryTab();
    showActiveTab();
  }

  void selectQueryTab(String id) {
    _inspector.updateActiveDraft(queryController.text);
    _inspector.selectQueryTab(id);
    showActiveTab();
  }

  void closeQueryTab(String id) {
    _inspector.closeQueryTab(id);
    showActiveTab();
  }

  Future<void> runActiveStatement() async {
    final statement = activeStatement;
    if (statement == null || !validation.isAllowed) return;
    final source = queryController.text;
    final statementStartLine = statement.startLineIn(source);
    final statementSql = statement.sourceFrom(source);
    value = value.copyWith(clearErrorLine: true);
    await _inspector.runQuery(statementSql);

    // MySQL counts lines from the statement it receives, whereas the editor
    // may contain earlier statements. Do not mark a stale location after text
    // was edited while the query was in flight.
    if (queryController.text != source) return;
    value = value.copyWith(
      errorLine: SqlErrorLine.editorLine(
        message: _inspector.value.error,
        statementStartLine: statementStartLine,
      ),
    );
  }

  Future<void> explainActiveStatement() async {
    final statement = activeStatement;
    if (statement == null || !canExplain) return;
    final source = statement.sourceFrom(queryController.text);
    await _inspector.runQuery('EXPLAIN $source');
  }

  void showActiveTab() {
    final draft = _inspector.activeQueryTab.draft;
    queryController.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
    value = value.copyWith(isDismissed: false);
    refreshSuggestions();
  }

  void _onQueryChanged() {
    final textChanged = _lastEditorText != queryController.text;
    _lastEditorText = queryController.text;
    _syncActiveStatement();
    _inspector.updateActiveDraft(queryController.text);
    value = value.copyWith(isDismissed: false, clearErrorLine: textChanged);
    refreshSuggestions();
    _inspector.loadColumnsForAutocomplete(queryController.value);
  }

  void _onFocusChanged() =>
      value = value.copyWith(isFocused: focusNode.hasFocus);

  void _onInspectorChanged() {
    final activeTabId = _inspector.activeQueryTab.id;
    if (_activeTabId != activeTabId) {
      _activeTabId = activeTabId;
      showActiveTab();
      return;
    }
    refreshSuggestions();
    if (_inspector.value.error == null && value.errorLine != null) {
      value = value.copyWith(clearErrorLine: true);
    }
  }

  void _syncActiveStatement() =>
      queryController.setActiveStatement(activeStatement);

  @override
  void dispose() {
    queryController.removeListener(_onQueryChanged);
    queryController.dispose();
    focusNode.removeListener(_onFocusChanged);
    focusNode.dispose();
    _inspector.removeListener(_onInspectorChanged);
    super.dispose();
  }
}
