import '../../models/network_request.dart';
import '../../core/contracts/inspector_controller_contract.dart';
import '../../dio_network_inspector.dart';

class WindowContentStateData {
  final NetworkRequest? selectedRequest;
  final double? leftPaneWidth;
  final bool isNotesOpen;
  final bool isUrlTesterOpen;
  final bool isSidePaneOpen;

  WindowContentStateData({
    this.selectedRequest,
    this.leftPaneWidth,
    this.isNotesOpen = false,
    this.isUrlTesterOpen = false,
    this.isSidePaneOpen = true,
  });

  WindowContentStateData copyWith({
    NetworkRequest? selectedRequest,
    bool clearSelectedRequest = false,
    double? leftPaneWidth,
    bool? isNotesOpen,
    bool? isUrlTesterOpen,
    bool? isSidePaneOpen,
  }) {
    return WindowContentStateData(
      selectedRequest: clearSelectedRequest
          ? null
          : (selectedRequest ?? this.selectedRequest),
      leftPaneWidth: leftPaneWidth ?? this.leftPaneWidth,
      isNotesOpen: isNotesOpen ?? this.isNotesOpen,
      isUrlTesterOpen: isUrlTesterOpen ?? this.isUrlTesterOpen,
      isSidePaneOpen: isSidePaneOpen ?? this.isSidePaneOpen,
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
    DioNetworkInspector.instance.isUrlTesterOpen.addListener(_onUrlTesterChanged);
    DioNetworkInspector.instance.isSidePaneOpen.addListener(_onSidePaneChanged);
  }

  @override
  void disposeController() {
    DioNetworkInspector.instance.requests.removeListener(_onRequestsChanged);
    DioNetworkInspector.instance.isNotesOpen.removeListener(_onNotesChanged);
    DioNetworkInspector.instance.isUrlTesterOpen.removeListener(_onUrlTesterChanged);
    DioNetworkInspector.instance.isSidePaneOpen.removeListener(_onSidePaneChanged);
    super.disposeController();
  }

  void _onNotesChanged() {
    if (DioNetworkInspector.instance.isNotesOpen.value) {
      DioNetworkInspector.instance.isUrlTesterOpen.value = false;
    }
    value = value.copyWith(
      isNotesOpen: DioNetworkInspector.instance.isNotesOpen.value,
    );
  }

  void _onUrlTesterChanged() {
    if (DioNetworkInspector.instance.isUrlTesterOpen.value) {
      DioNetworkInspector.instance.isNotesOpen.value = false;
    }
    value = value.copyWith(
      isUrlTesterOpen: DioNetworkInspector.instance.isUrlTesterOpen.value,
    );
  }

  void _onSidePaneChanged() {
    value = value.copyWith(
      isSidePaneOpen: DioNetworkInspector.instance.isSidePaneOpen.value,
    );
  }

  void _onRequestsChanged() {
    if (DioNetworkInspector.instance.requests.value.isEmpty &&
        value.selectedRequest != null) {
      value = value.copyWith(clearSelectedRequest: true);
    }
  }

  void selectRequest(NetworkRequest? req) {
    DioNetworkInspector.instance.isNotesOpen.value = false;
    DioNetworkInspector.instance.isUrlTesterOpen.value = false;
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
