import 'dart:collection';

import 'database_models.dart';
import 'database_query_tab_session.dart';

class DatabaseQueryTab {
  DatabaseQueryTab({
    required this.id,
    required this.name,
    this.draft = '',
    this.result,
    this.resultWasEvicted = false,
  });

  final String id;
  String name;
  String draft;
  DatabasePage? result;
  bool resultWasEvicted;
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

  List<DatabaseQueryTabSession> snapshot() => _tabs
      .map(
        (tab) => DatabaseQueryTabSession(
          name: tab.name,
          draft: tab.draft,
          isActive: tab.id == _activeId,
        ),
      )
      .toList(growable: false);

  void restore(List<DatabaseQueryTabSession> savedTabs) {
    _tabs.clear();
    _activeId = null;
    _nextId = 1;
    if (savedTabs.isEmpty) {
      _createTab(select: true);
      return;
    }
    for (final saved in savedTabs.take(20)) {
      final tab = _createTab(select: false);
      tab
        ..name = saved.name
        ..draft = saved.draft;
      if (saved.isActive && _activeId == null) _activeId = tab.id;
    }
    _activeId ??= _tabs.first.id;
  }

  void updateActiveResult(DatabasePage? result) {
    active.result = result;
    active.resultWasEvicted = false;
  }

  /// Releases result pages from inactive tabs while retaining each SQL draft.
  bool evictInactiveResults() {
    var evictedAny = false;
    for (final tab in _tabs) {
      if (tab.id == _activeId || tab.result == null) continue;
      tab.result = null;
      tab.resultWasEvicted = true;
      evictedAny = true;
    }
    return evictedAny;
  }

  bool rename(String id, String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index == -1) return false;
    _tabs[index].name = trimmedName;
    return true;
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
    final idNumber = _nextId++;
    final tab = DatabaseQueryTab(
      id: 'query-$idNumber',
      name: 'Query ${_nextAvailableDefaultNameNumber()}',
    );
    _tabs.add(tab);
    if (select) _activeId = tab.id;
    return tab;
  }

  int _nextAvailableDefaultNameNumber() {
    var number = 1;
    while (_tabs.any((tab) => tab.name == 'Query $number')) {
      number++;
    }
    return number;
  }
}
