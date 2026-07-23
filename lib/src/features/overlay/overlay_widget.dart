import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      color: InspectorColors.background,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: InspectorColors.divider)),
      ),
      height: 48,
      padding: const EdgeInsets.symmetric(
        horizontal: InspectorDimensions.spacingL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const BaseText(
                'Network Inspector',
                style: InspectorTypography.title,
              ),
              const SizedBox(width: InspectorDimensions.spacingM),
              Container(width: 1, height: 16, color: InspectorColors.divider),
              const SizedBox(width: InspectorDimensions.spacingM),
              ValueListenableBuilder<bool>(
                valueListenable: DioNetworkInspector.instance.isRecording,
                builder: (context, isRecording, _) => InkWell(
                  borderRadius: BorderRadius.circular(
                    InspectorDimensions.radiusM,
                  ),
                  onTap: () => DioNetworkInspector.instance.isRecording.value =
                      !isRecording,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isRecording
                                ? InspectorColors.error
                                : InspectorColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        BaseText(
                          isRecording ? 'Recording' : 'Paused',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          color: InspectorColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              BaseIconButton(
                icon: Icons.delete_outline,
                color: InspectorColors.textSecondary,
                size: InspectorDimensions.iconM,
                tooltip: 'Clear',
                onPressed: () {
                  DioNetworkInspector.instance.clear();
                },
              ),
              BaseIconButton(
                icon: Icons.file_upload_outlined,
                color: InspectorColors.textSecondary,
                size: InspectorDimensions.iconM,
                tooltip: 'Import session from clipboard',
                onPressed: _importSession,
              ),
              BaseIconButton(
                icon: Icons.file_download_outlined,
                color: InspectorColors.textSecondary,
                size: InspectorDimensions.iconM,
                tooltip: 'Export session to clipboard',
                onPressed: _exportSession,
              ),
              ValueListenableBuilder<bool>(
                valueListenable: DioNetworkInspector.instance.isNotesOpen,
                builder: (context, isOpen, _) => BaseIconButton(
                  icon: Icons.sticky_note_2_outlined,
                  color: isOpen
                      ? InspectorColors.primary
                      : InspectorColors.textSecondary,
                  size: InspectorDimensions.iconM,
                  tooltip: 'Global notes',
                  onPressed: () =>
                      DioNetworkInspector.instance.isNotesOpen.value = !isOpen,
                ),
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

  void _exportSession() {
    Clipboard.setData(
      ClipboardData(text: DioNetworkInspector.instance.exportSession()),
    );
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Session JSON copied')));
  }

  Future<void> _importSession() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.isEmpty) {
        throw const FormatException('Clipboard is empty.');
      }
      DioNetworkInspector.instance.importSession(data.text!);
      if (mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('Session imported')));
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Import failed: ${error.message}')),
        );
      }
    }
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
                _controller.setInitialFabPosition(
                  Offset(
                    constraints.maxWidth - 70.0,
                    constraints.maxHeight - 70.0,
                  ),
                );
              });
            }

            if (state.windowRect == null) {
              final width = (constraints.maxWidth - 32)
                  .clamp(320.0, 1000.0)
                  .toDouble();
              final height = (constraints.maxHeight - 32)
                  .clamp(360.0, 640.0)
                  .toDouble();
              final left = (constraints.maxWidth - width) / 2;
              final top = (constraints.maxHeight - height) / 2;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _controller.setWindowRect(
                  Rect.fromLTWH(
                    left > 0 ? left : 0,
                    top > 0 ? top : 0,
                    width,
                    height,
                  ),
                );
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
                        onPanUpdate: (details) =>
                            _controller.updateFabPosition(details.delta),
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
