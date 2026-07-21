import '../../core/contracts/inspector_controller_contract.dart';

class DetailPaneStateData {
  final int selectedTabIndex;

  DetailPaneStateData({
    this.selectedTabIndex = 0,
  });

  DetailPaneStateData copyWith({
    int? selectedTabIndex,
  }) {
    return DetailPaneStateData(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

class DetailPaneController extends InspectorControllerContract<DetailPaneStateData> {
  DetailPaneController() : super(DetailPaneStateData());

  @override
  void init() {}

  void selectTab(int index) {
    value = value.copyWith(selectedTabIndex: index);
  }
}
