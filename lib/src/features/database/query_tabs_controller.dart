import 'dart:collection';

import 'database_models.dart';

class DatabaseQueryTab {
  DatabaseQueryTab({
    required this.id,
    required this.name,
    this.draft = '',
    this.result,
  });

  final String id;
  String name;
  String draft;
  DatabasePage? result;
}

/// In-memory query tabs for one database connection.
///
/// The controller intentionally stores only draft SQL and the current page of
/// each result. It never stores credentials or creates extra MySQL clients.
class QueryTabsController {
  QueryTabsController() {
    _createTab(select: true);
  }

  final List<DatabaseQueryTab> _tabs = [];
  var _nextId = 1;
  String? _activeId;

  UnmodifiableListView<DatabaseQueryTab> get tabs =>
      UnmodifiableListView(_tabs);

  DatabaseQueryTab get active => _tabs.firstWhere((tab) => tab.id == _activeId);

  DatabaseQueryTab createTab() => _createTab(select: true);

  void select(String id) {
    if (_tabs.any((tab) => tab.id == id)) _activeId = id;
  }

  void updateActiveDraft(String draft) {
    active.draft = draft;
  }

  void updateActiveResult(DatabasePage? result) {
    active.result = result;
  }

  bool close(String id) {
    if (_tabs.length == 1) return false;
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index == -1) return false;
    final wasActive = _tabs[index].id == _activeId;
    _tabs.removeAt(index);
    if (wasActive) {
      _activeId = _tabs[index == _tabs.length ? index - 1 : index].id;
    }
    return true;
  }

  DatabaseQueryTab _createTab({required bool select}) {
    final number = _nextId++;
    final tab = DatabaseQueryTab(id: 'query-$number', name: 'Query $number');
    _tabs.add(tab);
    if (select) _activeId = tab.id;
    return tab;
  }
}
