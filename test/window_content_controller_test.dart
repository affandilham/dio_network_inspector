import 'package:dio_network_inspector/dio_network_inspector.dart';
import 'package:dio_network_inspector/src/features/window/window_content_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late WindowContentController controller;

  setUp(() {
    DioNetworkInspector.instance.isNotesOpen.value = false;
    DioNetworkInspector.instance.isDatabaseOpen.value = false;
    controller = WindowContentController()..init();
  });

  tearDown(() {
    controller.disposeController();
  });

  test('opening notes closes the database inspector', () {
    controller.setDatabaseOpen(true);

    controller.setNotesOpen(true);

    expect(DioNetworkInspector.instance.isNotesOpen.value, isTrue);
    expect(DioNetworkInspector.instance.isDatabaseOpen.value, isFalse);
  });

  test('opening the database inspector closes notes', () {
    controller.setNotesOpen(true);

    controller.setDatabaseOpen(true);

    expect(DioNetworkInspector.instance.isNotesOpen.value, isFalse);
    expect(DioNetworkInspector.instance.isDatabaseOpen.value, isTrue);
  });

  test('opening settings closes notes and database inspector', () {
    final controller = WindowContentController()..init();

    controller.setNotesOpen(true);
    controller.setDatabaseOpen(true);
    controller.setSettingsOpen(true);

    expect(DioNetworkInspector.instance.isSettingsOpen.value, isTrue);
    expect(DioNetworkInspector.instance.isNotesOpen.value, isFalse);
    expect(DioNetworkInspector.instance.isDatabaseOpen.value, isFalse);
    controller.disposeController();
  });

  testWidgets('hides the database button without a database config', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DioInspectorOverlay(child: SizedBox.expand())),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.network_check));
    await tester.pump();

    expect(find.byIcon(Icons.storage_outlined), findsNothing);
  });
}
