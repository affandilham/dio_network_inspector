import 'package:dio_network_inspector/dio_network_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DioInspectorOverlay adapts to light and dark theme modes',
      (WidgetTester tester) async {
    // 1. Build widget in Light Mode
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light,
        home: Scaffold(
          body: DioInspectorOverlay(
            themeMode: ThemeMode.light,
            child: const Text('Host App'),
          ),
        ),
      ),
    );

    expect(find.text('Host App'), findsOneWidget);

    // 2. Build widget in Dark Mode
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: DioInspectorOverlay(
            themeMode: ThemeMode.dark,
            child: const Text('Host App'),
          ),
        ),
      ),
    );

    expect(find.text('Host App'), findsOneWidget);
  });
}
