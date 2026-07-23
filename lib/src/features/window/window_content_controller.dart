import '../../models/network_request.dart';
import '../../core/contracts/inspector_controller_contract.dart';
import '../../dio_network_inspector.dart';

class WindowContentStateData {
  final NetworkRequest? selectedRequest;
  final double? leftPaneWidth;
  final bool isNotesOpen;

  WindowContentStateData({
    this.selectedRequest,
    this.leftPaneWidth,
    this.isNotesOpen = false,
  });

  WindowContentStateData copyWith({
    NetworkRequest? selectedRequest,
    bool clearSelectedRequest = false,
    double? leftPaneWidth,
    bool? isNotesOpen,
  }) {
    return WindowContentStateData(
      selectedRequest: clearSelectedRequest
          ? null
          : (selectedRequest ?? this.selectedRequest),
      leftPaneWidth: leftPaneWidth ?? this.leftPaneWidth,
      isNotesOpen: isNotesOpen ?? this.isNotesOpen,
    );
  }
}

class WindowContentController
    extends InspectorControllerContract<WindowContentStateData> {
  WindowContentController() : super(WindowContentStateData());

  @override
  void init() {
    DioNetworkInspector.instance.requests.addListener(_onRequestsChanged);
    DioNetworkInspector.instance.isNotesOpen.addListener(_onNotesChanged);
  }

  @override
  void disposeController() {
    DioNetworkInspector.instance.requests.removeListener(_onRequestsChanged);
    DioNetworkInspector.instance.isNotesOpen.removeListener(_onNotesChanged);
    super.disposeController();
  }

  void _onNotesChanged() => value = value.copyWith(
    isNotesOpen: DioNetworkInspector.instance.isNotesOpen.value,
  );

  void _onRequestsChanged() {
    if (DioNetworkInspector.instance.requests.value.isEmpty &&
        value.selectedRequest != null) {
      value = value.copyWith(clearSelectedRequest: true);
    }
  }

  void selectRequest(NetworkRequest? req) {
    DioNetworkInspector.instance.isNotesOpen.value = false;
    value = value.copyWith(
      selectedRequest: req,
      clearSelectedRequest: req == null,
    );
  }

  void updateLeftPaneWidth(double dx, double maxWidth) {
    if (value.leftPaneWidth != null) {
      double newWidth = (value.leftPaneWidth! + dx).clamp(
        100.0,
        maxWidth - 100.0,
      );
      value = value.copyWith(leftPaneWidth: newWidth);
    }
  }

  void setInitialLeftPaneWidth(double width) {
    value = value.copyWith(leftPaneWidth: width);
  }
}
