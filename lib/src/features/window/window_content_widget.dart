import 'package:flutter/material.dart';
import 'window_content_controller.dart';
import '../request_list/request_list_widget.dart';
import '../request_detail/detail_pane_widget.dart';
import '../notes/notes_pane_widget.dart';
import '../database/presentation/database_inspector_widget.dart';
import '../settings/inspector_settings_pane_widget.dart';
import '../url_tester/url_tester_widget.dart';
import '../../models/split_orientation.dart';

class InspectorWindowContentWidget extends StatefulWidget {
  final WindowContentController? controller;

  const InspectorWindowContentWidget({super.key, this.controller});

  @override
  State<InspectorWindowContentWidget> createState() =>
      _InspectorWindowContentWidgetState();
}

class _InspectorWindowContentWidgetState
    extends State<InspectorWindowContentWidget> {
  late WindowContentController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? (WindowContentController()..init());
  }

  @override
  void dispose() {
    if (_ownsController) _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ValueListenableBuilder<WindowContentStateData>(
                valueListenable: _controller,
                builder: (context, state, child) {
                  if (state.leftPaneWidth == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _controller.setInitialLeftPaneWidth(
                        constraints.maxWidth / 3,
                      );
                    });
                  }

                  if (state.topPaneHeight == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _controller.setInitialTopPaneHeight(
                        constraints.maxHeight / 2,
                      );
                    });
                  }

                  final rightPaneActive =
                      state.selectedRequest != null ||
                      state.isNotesOpen ||
                      state.isUrlTesterOpen ||
                      state.isDatabaseOpen ||
                      state.isSettingsOpen;

                  if (constraints.maxWidth < 200 || !rightPaneActive) {
                    return InspectorRequestListWidget(
                      selectedRequest: state.selectedRequest,
                      onSelected: _controller.selectRequest,
                    );
                  }

                  if (!state.isSidePaneOpen) {
                    return _buildActivePane(state);
                  }

                  final isBottom =
                      state.splitOrientation == SplitOrientation.bottom;

                  if (isBottom) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Pane: Request List
                        SizedBox(
                          height:
                              (state.topPaneHeight ?? constraints.maxHeight / 2)
                                  .clamp(100.0, constraints.maxHeight - 100.0),
                          child: InspectorRequestListWidget(
                            selectedRequest: state.selectedRequest,
                            onSelected: _controller.selectRequest,
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: (details) {
                            _controller.updateTopPaneHeight(
                              details.delta.dy,
                              constraints.maxHeight,
                            );
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeRow,
                            child: Container(
                              height: 8,
                              color: Colors.transparent,
                              child: const Divider(height: 1, thickness: 1),
                            ),
                          ),
                        ),
                        Expanded(child: _buildActivePane(state)),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Pane: Request List
                      SizedBox(
                        width: (state.leftPaneWidth ?? constraints.maxWidth / 3)
                            .clamp(100.0, constraints.maxWidth - 100.0),
                        child: InspectorRequestListWidget(
                          selectedRequest: state.selectedRequest,
                          onSelected: _controller.selectRequest,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanUpdate: (details) {
                          _controller.updateLeftPaneWidth(
                            details.delta.dx,
                            constraints.maxWidth,
                          );
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: Container(
                            width: 8,
                            color: Colors.transparent,
                            child: const VerticalDivider(
                              width: 1,
                              thickness: 1,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: _buildActivePane(state)),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivePane(WindowContentStateData state) {
    if (state.isUrlTesterOpen) return const InspectorUrlTesterWidget();
    if (state.isNotesOpen) return const InspectorNotesPaneWidget();
    if (state.isDatabaseOpen) return const InspectorDatabasePaneWidget();
    if (state.isSettingsOpen) return const InspectorSettingsPaneWidget();
    return InspectorDetailPaneWidget(
      request: state.selectedRequest!,
      onClose: () => _controller.selectRequest(null),
    );
  }
}
