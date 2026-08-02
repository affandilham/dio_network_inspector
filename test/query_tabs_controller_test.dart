import 'package:dio_network_inspector/src/features/database/domain/query_tabs_controller.dart';
import 'package:dio_network_inspector/src/features/database/domain/database_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renames an existing query tab', () {
    final controller = QueryTabsController();
    final tab = controller.active;

    expect(controller.rename(tab.id, 'Users lookup'), isTrue);
    expect(controller.active.name, 'Users lookup');
  });

  test('rejects blank names and unknown tabs', () {
    final controller = QueryTabsController();

    expect(controller.rename(controller.active.id, '  '), isFalse);
    expect(controller.rename('missing', 'Other'), isFalse);
    expect(controller.active.name, 'Query 1');
  });

  test('evicts inactive result pages while keeping their drafts', () {
    final controller = QueryTabsController();
    controller.updateActiveDraft('SELECT * FROM users');
    controller.updateActiveResult(
      const DatabasePage(
        columns: [],
        rows: [],
        offset: 0,
        limit: 50,
        hasMore: false,
      ),
    );
    final firstTab = controller.active;

    controller.createTab();

    expect(controller.evictInactiveResults(), isTrue);
    expect(firstTab.draft, 'SELECT * FROM users');
    expect(firstTab.result, isNull);
    expect(firstTab.resultWasEvicted, isTrue);
  });

  test('reuses the first available default name after a tab is closed', () {
    final controller = QueryTabsController();
    final second = controller.createTab();
    controller.createTab();

    expect(controller.close(second.id), isTrue);
    final replacement = controller.createTab();

    expect(replacement.name, 'Query 2');
    expect(replacement.id, isNot(second.id));
  });
}
