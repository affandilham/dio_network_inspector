import 'package:flutter_test/flutter_test.dart';
import 'package:dio_network_inspector/dio_network_inspector.dart';
import 'package:dio_network_inspector/src/features/window/window_content_controller.dart';

void main() {
  setUp(() {
    DioNetworkInspector.instance.splitOrientation.value = SplitOrientation.side;
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
}
