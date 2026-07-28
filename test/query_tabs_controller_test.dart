import 'package:dio_network_inspector/src/features/database/query_tabs_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new tabs keep independent drafts and select the new tab', () {
    final tabs = QueryTabsController();
    tabs.updateActiveDraft('SELECT * FROM users');

    final second = tabs.createTab();
    tabs.updateActiveDraft('SHOW TABLES');

    expect(tabs.tabs, hasLength(2));
    expect(tabs.active.id, second.id);
    expect(tabs.tabs.first.draft, 'SELECT * FROM users');
    expect(tabs.active.draft, 'SHOW TABLES');
  });

  test('closing the active tab selects a neighbouring tab', () {
    final tabs = QueryTabsController();
    final second = tabs.createTab();

    expect(tabs.close(second.id), isTrue);
    expect(tabs.tabs, hasLength(1));
    expect(tabs.active.name, 'Query 1');
  });

  test('the final tab is kept open', () {
    final tabs = QueryTabsController();

    expect(tabs.close(tabs.active.id), isFalse);
    expect(tabs.tabs, hasLength(1));
  });
}
