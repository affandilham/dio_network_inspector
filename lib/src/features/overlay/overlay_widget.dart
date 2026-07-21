import 'package:flutter/material.dart';
import 'overlay_controller.dart';
import '../window/resizable_window.dart';
import '../window/window_content_widget.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import '../../components/base_text.dart';
import '../../components/base_icon_button.dart';
import '../../components/base_container.dart';
import '../../dio_network_inspector.dart';

class DioInspectorOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const DioInspectorOverlay({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  @override
  State<DioInspectorOverlay> createState() => _DioInspectorOverlayState();
}

class _DioInspectorOverlayState extends State<DioInspectorOverlay> {
  late OverlayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OverlayController();
  }

  @override
  void dispose() {
    _controller.disposeController();
    super.dispose();
  }

  Widget _buildHeader() {
    return BaseContainer(
      color: InspectorColors.surface,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: InspectorColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: InspectorDimensions.spacingL,
        vertical: InspectorDimensions.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const BaseText('Network Inspector', style: InspectorTypography.title),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: DioNetworkInspector.instance.isRecording,
                builder: (context, isRecording, _) {
                  return BaseIconButton(
                    icon: Icons.circle,
                    color: isRecording ? InspectorColors.error : InspectorColors.textSecondary,
                    size: InspectorDimensions.iconS,
                    tooltip: isRecording ? 'Stop recording' : 'Record',
                    onPressed: () {
                      DioNetworkInspector.instance.isRecording.value = !isRecording;
                    },
                  );
                },
              ),
              const SizedBox(width: InspectorDimensions.spacingS),
              BaseIconButton(
                icon: Icons.do_not_disturb,
                color: InspectorColors.textSecondary,
                size: InspectorDimensions.iconM,
                tooltip: 'Clear',
                onPressed: () {
                  DioNetworkInspector.instance.clear();
                },
              ),
              const SizedBox(width: InspectorDimensions.spacingS),
              BaseIconButton(
                icon: Icons.close,
                color: InspectorColors.textBlueGrey,
                size: InspectorDimensions.iconL,
                tooltip: 'Close',
                onPressed: () => _controller.toggleOpen(false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<OverlayStateData>(
          valueListenable: _controller,
          builder: (context, state, child) {
            if (state.fabPosition == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _controller.setInitialFabPosition(Offset(
                  constraints.maxWidth - 70.0,
                  constraints.maxHeight - 70.0,
                ));
              });
            }

            if (state.windowRect == null) {
              final width = 450.0;
              final height = 500.0;
              final left = (constraints.maxWidth - width) / 2;
              final top = (constraints.maxHeight - height) / 2;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _controller.setWindowRect(Rect.fromLTWH(
                  left > 0 ? left : 0,
                  top > 0 ? top : 0,
                  width,
                  height,
                ));
              });
            }

            return Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  widget.child,
                  if (!state.isOpen && state.fabPosition != null)
                    Positioned(
                      left: state.fabPosition!.dx,
                      top: state.fabPosition!.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) => _controller.updateFabPosition(details.delta),
                        child: FloatingActionButton(
                          heroTag: 'dio_network_inspector_fab',
                          mini: true,
                          onPressed: () => _controller.toggleOpen(true),
                          backgroundColor: Colors.blueGrey.shade800,
                          child: const Icon(
                            Icons.network_check,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (state.isOpen && state.windowRect != null)
                    ResizableWindow(
                      initialRect: state.windowRect!,
                      onRectChanged: _controller.setWindowRect,
                      header: _buildHeader(),
                      body: const InspectorWindowContentWidget(),
                      onClose: () => _controller.toggleOpen(false),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
