import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'overlay_controller.dart';
import '../window/resizable_window.dart';
import '../window/window_content_widget.dart';
import '../window/window_content_controller.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import '../../components/base_text.dart';
import '../../components/base_icon_button.dart';
import '../../components/base_container.dart';
import '../../dio_network_inspector.dart';
import '../database/database_models.dart';

class DioInspectorOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;
  final MySqlInspectorConfig? databaseConfig;

  const DioInspectorOverlay({
    super.key,
    required this.child,
    this.navigatorKey,
    this.databaseConfig,
  });

  @override
  State<DioInspectorOverlay> createState() => _DioInspectorOverlayState();
}

class _DioInspectorOverlayState extends State<DioInspectorOverlay> {
  late OverlayController _controller;
  late WindowContentController _windowContentController;

  void _toggleRecordingFromShortcut() {
    if (!_controller.value.isOpen) return;
    final inspector = DioNetworkInspector.instance;
    inspector.isRecording.value = !inspector.isRecording.value;
  }

  void _clearLogsFromShortcut() {
    if (_controller.value.isOpen) DioNetworkInspector.instance.clear();
  }

  void _toggleWindowFromShortcut() {
    _controller.toggleOpen(!_controller.value.isOpen);
  }

  @override
  void initState() {
    super.initState();
    _controller = OverlayController();
    _windowContentController = WindowContentController()..init();
    DioNetworkInspector.instance.configureDatabase(widget.databaseConfig);
  }

  @override
  void dispose() {
    _controller.disposeController();
    _windowContentController.disposeController();
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
                builder: (context, isRecording, _) => Tooltip(
                  message:
                      '${isRecording ? 'Stop' : 'Start'} recording (⌘/Ctrl+R)',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    onTap: () =>
                        DioNetworkInspector.instance.isRecording.value =
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
              ),
            ],
          ),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: DioNetworkInspector.instance.isNotesOpen,
                builder: (context, isOpen, _) => BaseIconButton(
                  icon: Icons.sticky_note_2_outlined,
                  color: isOpen
                      ? InspectorColors.primary
                      : InspectorColors.textSecondary,
                  size: InspectorDimensions.iconM,
                  tooltip: 'Notes',
                  onPressed: () =>
                      _windowContentController.setNotesOpen(!isOpen),
                ),
              ),
              if (widget.databaseConfig != null)
                ValueListenableBuilder<bool>(
                  valueListenable: DioNetworkInspector.instance.isDatabaseOpen,
                  builder: (context, isOpen, _) => BaseIconButton(
                    icon: Icons.storage_outlined,
                    color: isOpen
                        ? InspectorColors.primary
                        : InspectorColors.textSecondary,
                    size: InspectorDimensions.iconM,
                    tooltip: 'Database Inspector',
                    onPressed: () =>
                        _windowContentController.setDatabaseOpen(!isOpen),
                  ),
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
              const SizedBox(width: InspectorDimensions.spacingS),
              BaseIconButton(
                icon: Icons.close,
                color: InspectorColors.textBlueGrey,
                size: InspectorDimensions.iconL,
                tooltip: 'Close inspector (Fn+F12)',
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
    return Overlay(
      initialEntries: [
        OverlayEntry(builder: (context) => _buildOverlay(context)),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
            _toggleRecordingFromShortcut,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR):
            _toggleRecordingFromShortcut,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            _clearLogsFromShortcut,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            _clearLogsFromShortcut,
        LogicalKeySet(LogicalKeyboardKey.f12): _toggleWindowFromShortcut,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
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
                            child: Semantics(
                              label: 'Open inspector, shortcut Fn+F12',
                              button: true,
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
                        ),
                      if (state.isOpen && state.windowRect != null)
                        ResizableWindow(
                          initialRect: state.windowRect!,
                          onRectChanged: _controller.setWindowRect,
                          header: _buildHeader(),
                          body: InspectorWindowContentWidget(
                            controller: _windowContentController,
                          ),
                          onClose: () => _controller.toggleOpen(false),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
