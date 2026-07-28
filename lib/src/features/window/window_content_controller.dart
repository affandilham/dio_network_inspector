import '../../models/network_request.dart';
import '../../core/contracts/inspector_controller_contract.dart';
import '../../dio_network_inspector.dart';

class WindowContentStateData {
  final NetworkRequest? selectedRequest;
  final double? leftPaneWidth;
  final bool isNotesOpen;
  final bool isDatabaseOpen;

  WindowContentStateData({
    this.selectedRequest,
    this.leftPaneWidth,
    this.isNotesOpen = false,
    this.isDatabaseOpen = false,
  });

  WindowContentStateData copyWith({
    NetworkRequest? selectedRequest,
    bool clearSelectedRequest = false,
    double? leftPaneWidth,
    bool? isNotesOpen,
    bool? isDatabaseOpen,
  }) {
    return WindowContentStateData(
      selectedRequest: clearSelectedRequest
          ? null
          : (selectedRequest ?? this.selectedRequest),
      leftPaneWidth: leftPaneWidth ?? this.leftPaneWidth,
      isNotesOpen: isNotesOpen ?? this.isNotesOpen,
      isDatabaseOpen: isDatabaseOpen ?? this.isDatabaseOpen,
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
    DioNetworkInspector.instance.isDatabaseOpen.addListener(_onDatabaseChanged);
  }

  @override
  void disposeController() {
    DioNetworkInspector.instance.requests.removeListener(_onRequestsChanged);
    DioNetworkInspector.instance.isNotesOpen.removeListener(_onNotesChanged);
    DioNetworkInspector.instance.isDatabaseOpen.removeListener(
      _onDatabaseChanged,
    );
    super.disposeController();
  }

  void _onNotesChanged() => value = value.copyWith(
    isNotesOpen: DioNetworkInspector.instance.isNotesOpen.value,
  );

  void _onDatabaseChanged() => value = value.copyWith(
    isDatabaseOpen: DioNetworkInspector.instance.isDatabaseOpen.value,
  );

  void _onRequestsChanged() {
    if (DioNetworkInspector.instance.requests.value.isEmpty &&
        value.selectedRequest != null) {
      value = value.copyWith(clearSelectedRequest: true);
    }
  }

  void selectRequest(NetworkRequest? req) {
    DioNetworkInspector.instance.isNotesOpen.value = false;
    DioNetworkInspector.instance.isDatabaseOpen.value = false;
    value = value.copyWith(
      selectedRequest: req,
      clearSelectedRequest: req == null,
    );
  }

  void setNotesOpen(bool open) {
    DioNetworkInspector.instance.isNotesOpen.value = open;
    if (open) DioNetworkInspector.instance.isDatabaseOpen.value = false;
  }

  void setDatabaseOpen(bool open) {
    DioNetworkInspector.instance.isNotesOpen.value = false;
    DioNetworkInspector.instance.isDatabaseOpen.value = open;
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
