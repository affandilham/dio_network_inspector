import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio_network_inspector/dio_network_inspector.dart';
import 'package:dio_network_inspector/src/features/window/window_content_controller.dart';
import 'package:dio_network_inspector/src/features/window/window_content_widget.dart';
import 'package:dio_network_inspector/src/features/request_list/request_list_widget.dart';
import 'package:dio_network_inspector/src/features/request_detail/detail_pane_widget.dart';

void main() {
  setUp(() {
    DioNetworkInspector.instance.splitOrientation.value = SplitOrientation.side;
    DioNetworkInspector.instance.clear();
  });

  test('DioNetworkInspector split orientation defaults to side and toggles correctly', () {
    final inspector = DioNetworkInspector.instance;
    expect(inspector.splitOrientation.value, equals(SplitOrientation.side));

    inspector.toggleSplitOrientation();
    expect(inspector.splitOrientation.value, equals(SplitOrientation.bottom));

    inspector.toggleSplitOrientation();
    expect(inspector.splitOrientation.value, equals(SplitOrientation.side));
  });

  test('WindowContentController syncs splitOrientation from DioNetworkInspector', () {
    final controller = WindowContentController()..init();
    expect(controller.value.splitOrientation, equals(SplitOrientation.side));

    DioNetworkInspector.instance.toggleSplitOrientation();
    expect(controller.value.splitOrientation, equals(SplitOrientation.bottom));

    controller.disposeController();
  });

  testWidgets('InspectorWindowContentWidget splits to side on large screens and bottom on small screens', (tester) async {
    final req = NetworkRequest(
      id: 1,
      url: 'https://api.example.com/data',
      method: 'GET',
      requestTime: DateTime.now(),
    )..statusCode = 200;
    final controller = WindowContentController()..init();
    controller.selectRequest(req);

    // 1. Large screen with side split orientation -> Row layout
    DioNetworkInspector.instance.splitOrientation.value = SplitOrientation.side;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: InspectorWindowContentWidget(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InspectorRequestListWidget), findsOneWidget);
    expect(find.byType(InspectorDetailPaneWidget), findsOneWidget);

    // Verify Row layout for large screen when side split is active
    final rowFinder = find.ancestor(
      of: find.byType(InspectorRequestListWidget),
      matching: find.byType(Row),
    );
    expect(rowFinder, findsWidgets);

    // 2. Small screen (< 600px) with side split orientation -> Automatically splits to bottom (Column layout)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              height: 600,
              child: InspectorWindowContentWidget(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InspectorRequestListWidget), findsOneWidget);
    expect(find.byType(InspectorDetailPaneWidget), findsOneWidget);

    // Verify Column layout for small screen
    final columnFinder = find.ancestor(
      of: find.byType(InspectorRequestListWidget),
      matching: find.byType(Column),
    );
    expect(columnFinder, findsWidgets);

    // 3. Large screen with explicit bottom split -> Column layout
    DioNetworkInspector.instance.splitOrientation.value = SplitOrientation.bottom;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: InspectorWindowContentWidget(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InspectorRequestListWidget), findsOneWidget);
    expect(find.byType(InspectorDetailPaneWidget), findsOneWidget);

    controller.disposeController();
  });
}
