import '../../models/network_request.dart';
import '../../models/split_orientation.dart';
import '../../core/contracts/inspector_controller_contract.dart';
import '../../dio_network_inspector.dart';

class WindowContentStateData {
  final NetworkRequest? selectedRequest;
  final double? leftPaneWidth;
  final double? topPaneHeight;
  final bool isNotesOpen;
  final bool isUrlTesterOpen;
  final bool isSidePaneOpen;
  final SplitOrientation splitOrientation;

  WindowContentStateData({
    this.selectedRequest,
    this.leftPaneWidth,
    this.topPaneHeight,
    this.isNotesOpen = false,
    this.isUrlTesterOpen = false,
    this.isSidePaneOpen = true,
    this.splitOrientation = SplitOrientation.side,
  });

  WindowContentStateData copyWith({
    NetworkRequest? selectedRequest,
    bool clearSelectedRequest = false,
    double? leftPaneWidth,
    double? topPaneHeight,
    bool? isNotesOpen,
    bool? isUrlTesterOpen,
    bool? isSidePaneOpen,
    SplitOrientation? splitOrientation,
  }) {
    return WindowContentStateData(
      selectedRequest: clearSelectedRequest
          ? null
          : (selectedRequest ?? this.selectedRequest),
      leftPaneWidth: leftPaneWidth ?? this.leftPaneWidth,
      topPaneHeight: topPaneHeight ?? this.topPaneHeight,
      isNotesOpen: isNotesOpen ?? this.isNotesOpen,
      isUrlTesterOpen: isUrlTesterOpen ?? this.isUrlTesterOpen,
      isSidePaneOpen: isSidePaneOpen ?? this.isSidePaneOpen,
      splitOrientation: splitOrientation ?? this.splitOrientation,
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
    DioNetworkInspector.instance.splitOrientation.addListener(_onSplitOrientationChanged);
  }

  @override
  void disposeController() {
    DioNetworkInspector.instance.requests.removeListener(_onRequestsChanged);
    DioNetworkInspector.instance.isNotesOpen.removeListener(_onNotesChanged);
    DioNetworkInspector.instance.isUrlTesterOpen.removeListener(_onUrlTesterChanged);
    DioNetworkInspector.instance.isSidePaneOpen.removeListener(_onSidePaneChanged);
    DioNetworkInspector.instance.splitOrientation.removeListener(_onSplitOrientationChanged);
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

  void _onSplitOrientationChanged() {
    value = value.copyWith(
      splitOrientation: DioNetworkInspector.instance.splitOrientation.value,
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

  void updateTopPaneHeight(double dy, double maxHeight) {
    if (value.topPaneHeight != null) {
      double newHeight = (value.topPaneHeight! + dy).clamp(
        100.0,
        maxHeight - 100.0,
      );
      value = value.copyWith(topPaneHeight: newHeight);
    }
  }

  void setInitialTopPaneHeight(double height) {
    value = value.copyWith(topPaneHeight: height);
  }
}
