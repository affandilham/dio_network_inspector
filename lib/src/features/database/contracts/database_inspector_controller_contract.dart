import 'package:flutter/widgets.dart';

import '../../../core/contracts/inspector_controller_contract.dart';
import '../application/database_inspector_state.dart';
import '../domain/database_models.dart';
import '../domain/database_query_history_entry.dart';
import '../domain/query_tabs_controller.dart';
import '../domain/sql/sql_autocomplete.dart';

/// Public session API consumed by database-inspector widgets.
abstract class DatabaseInspectorControllerContract
    extends InspectorControllerContract<DatabaseInspectorState> {
  DatabaseInspectorControllerContract(super.value);

  List<DatabaseQueryTab> get queryTabs;
  DatabaseQueryTab get activeQueryTab;
  List<SqlAutocompleteSuggestion> autocompleteSuggestions(
    TextEditingValue value,
  );

  void updateActiveDraft(String draft);
  void createQueryTab();
  void selectQueryTab(String id);
  void renameQueryTab(String id, String name);
  void closeQueryTab(String id);
  void clearQueryHistory();
  void deleteQueryHistory(DatabaseQueryHistoryEntry entry);
  void saveQuery({
    required String name,
    required String sql,
    String folder = '',
  });
  void deleteSavedQuery(String id);
  Future<void> inspectRelatedData(DatabaseForeignKey relation, String value);
  Future<void> inspectRelatedDataForRow(
    DatabaseForeignKey relation,
    Map<String, String?> row,
  );
  Future<void> inspectReferencingData(
    DatabaseForeignKey relation,
    String value,
  );
  Future<void> inspectReferencingDataForRow(
    DatabaseForeignKey relation,
    Map<String, String?> row,
  );
  Future<void> connect();
  Future<void> disconnect();
  Future<void> refreshTables();
  Future<void> openTable(String table, {int offset = 0});
  Future<void> runQuery(String query);
  Future<void> cancelQuery();
  Future<void> loadColumnsForAutocomplete(TextEditingValue value);
  void recordUserActivity();
  void clearError();
}
