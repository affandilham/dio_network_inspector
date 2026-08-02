import 'package:dio_network_inspector/src/features/database/domain/database_query_tab_session.dart';
import 'package:dio_network_inspector/src/features/database/domain/query_tabs_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores tab drafts and the saved active tab without results', () {
    final controller = QueryTabsController();

    controller.restore(const [
      DatabaseQueryTabSession(
        name: 'Users',
        draft: 'SELECT * FROM users',
        isActive: false,
      ),
      DatabaseQueryTabSession(
        name: 'Orders',
        draft: 'SELECT * FROM orders',
        isActive: true,
      ),
    ]);

    expect(controller.tabs.map((tab) => tab.name), ['Users', 'Orders']);
    expect(controller.active.name, 'Orders');
    expect(controller.active.draft, 'SELECT * FROM orders');
    expect(controller.active.result, isNull);
  });

  test('snapshots only tab metadata and active state', () {
    final controller = QueryTabsController();
    controller.updateActiveDraft('SELECT * FROM users');

    final tabs = controller.snapshot();

    expect(tabs, hasLength(1));
    expect(tabs.single.name, 'Query 1');
    expect(tabs.single.draft, 'SELECT * FROM users');
    expect(tabs.single.isActive, isTrue);
  });

  test('uses a new blank tab when a scope has no saved session', () {
    final controller = QueryTabsController();
    controller.updateActiveDraft('SELECT * FROM private_database');

    controller.restore(const []);

    expect(controller.tabs, hasLength(1));
    expect(controller.active.name, 'Query 1');
    expect(controller.active.draft, isEmpty);
  });
}
