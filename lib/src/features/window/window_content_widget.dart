import 'package:flutter/material.dart';
import 'window_content_controller.dart';
import '../request_list/request_list_widget.dart';
import '../request_detail/detail_pane_widget.dart';

class InspectorWindowContentWidget extends StatefulWidget {
  const InspectorWindowContentWidget({super.key});

  @override
  State<InspectorWindowContentWidget> createState() => _InspectorWindowContentWidgetState();
}

class _InspectorWindowContentWidgetState extends State<InspectorWindowContentWidget> {
  late WindowContentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WindowContentController()..init();
  }

  @override
  void dispose() {
    _controller.disposeController();
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
                      _controller.setInitialLeftPaneWidth(constraints.maxWidth / 3);
                    });
                  }

                  if (constraints.maxWidth < 200 || state.selectedRequest == null) {
                    return InspectorRequestListWidget(
                      selectedRequest: state.selectedRequest,
                      onSelected: _controller.selectRequest,
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Pane: Request List
                      SizedBox(
                        width: state.leftPaneWidth!.clamp(
                          100.0,
                          constraints.maxWidth - 100.0,
                        ),
                        child: InspectorRequestListWidget(
                          selectedRequest: state.selectedRequest,
                          onSelected: _controller.selectRequest,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanUpdate: (details) {
                          _controller.updateLeftPaneWidth(details.delta.dx, constraints.maxWidth);
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: Container(
                            width: 8,
                            color: Colors.transparent,
                            child: const VerticalDivider(width: 1, thickness: 1),
                          ),
                        ),
                      ),
                      // Right Pane: Request Details
                      Expanded(
                        child: InspectorDetailPaneWidget(
                          request: state.selectedRequest!,
                          onClose: () => _controller.selectRequest(null),
                        ),
                      ),
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
}
