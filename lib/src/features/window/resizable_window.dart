import 'package:flutter/material.dart';
import 'resizable_window_controller.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../dio_network_inspector.dart';

class ResizableWindow extends StatefulWidget {
  final Widget header;
  final Widget body;
  final VoidCallback onClose;
  final Rect initialRect;
  final ValueChanged<Rect>? onRectChanged;
  /// Optional theme override. When null the window follows the host app's
  /// active [ThemeMode] via [DioNetworkInspector.instance.themeMode].
  final ThemeMode? themeMode;

  const ResizableWindow({
    super.key,
    required this.header,
    required this.body,
    required this.onClose,
    required this.initialRect,
    this.onRectChanged,
    this.themeMode,
  });

  @override
  State<ResizableWindow> createState() => _ResizableWindowState();
}

class _ResizableWindowState extends State<ResizableWindow> {
  late ResizableWindowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ResizableWindowController(
      widget.initialRect,
      onRectChanged: widget.onRectChanged,
    );
  }

  @override
  void dispose() {
    _controller.disposeController();
    super.dispose();
  }

  Widget _buildHandle(
    Alignment alignment,
    MouseCursor cursor,
    void Function(DragUpdateDetails) onPanUpdate,
  ) {
    final cornerSize = InspectorDimensions.spacingXxl;
    final edgeSize = InspectorDimensions.handleSize;

    double? left, top, right, bottom;
    double? width, height;

    if (alignment == Alignment.topLeft) {
      left = 0; top = 0; width = cornerSize; height = cornerSize;
    } else if (alignment == Alignment.topRight) {
      right = 0; top = 0; width = cornerSize; height = cornerSize;
    } else if (alignment == Alignment.bottomLeft) {
      left = 0; bottom = 0; width = cornerSize; height = cornerSize;
    } else if (alignment == Alignment.bottomRight) {
      right = 0; bottom = 0; width = cornerSize; height = cornerSize;
    } else if (alignment == Alignment.topCenter) {
      left = cornerSize; right = cornerSize; top = 0; height = edgeSize;
    } else if (alignment == Alignment.bottomCenter) {
      left = cornerSize; right = cornerSize; bottom = 0; height = edgeSize;
    } else if (alignment == Alignment.centerLeft) {
      top = cornerSize; bottom = cornerSize; left = 0; width = edgeSize;
    } else if (alignment == Alignment.centerRight) {
      top = cornerSize; bottom = cornerSize; right = 0; width = edgeSize;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: onPanUpdate,
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Rect>(
      valueListenable: _controller,
      builder: (context, rect, child) {
        return Positioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: DioNetworkInspector.instance.themeMode,
                  builder: (context, inspectorThemeMode, child) {
                    // Effective themeMode: explicit prop beats global notifier.
                    final effectiveThemeMode =
                        widget.themeMode ?? inspectorThemeMode;

                    // Resolve background for the Material host using the
                    // parent's brightness so it agrees with system before
                    // the nested MaterialApp overrides it.
                    final hostBrightness = Theme.of(context).brightness;
                    final darkMode =
                        effectiveThemeMode == ThemeMode.dark ||
                        (effectiveThemeMode == ThemeMode.system &&
                            hostBrightness == Brightness.dark);
                    final colors = darkMode
                        ? InspectorColors.dark
                        : InspectorColors.light;

                    ThemeData buildTheme(InspectorColorsData c) => ThemeData(
                      useMaterial3: true,
                      brightness: darkMode ? Brightness.dark : Brightness.light,
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: c.primary,
                        brightness: darkMode
                            ? Brightness.dark
                            : Brightness.light,
                        primary: c.primary,
                        primaryContainer: c.primaryContainer,
                        secondary: c.secondary,
                        tertiary: c.tertiary,
                        surface: c.surface,
                      ),
                      scaffoldBackgroundColor: c.background,
                      cardColor: c.surface,
                      dividerColor: c.divider,
                      popupMenuTheme: PopupMenuThemeData(
                        color: c.background,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            InspectorDimensions.radiusXl,
                          ),
                        ),
                      ),
                    );

                    return Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(
                        InspectorDimensions.radiusL,
                      ),
                      clipBehavior: Clip.antiAlias,
                      color: colors.background,
                      child: MaterialApp(
                        debugShowCheckedModeBanner: false,
                        color: Colors.transparent,
                        theme: buildTheme(InspectorColors.light),
                        darkTheme: buildTheme(InspectorColors.dark),
                        themeMode: effectiveThemeMode,
                        home: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Column(
                            children: [
                              GestureDetector(
                                onPanUpdate: (details) {
                                  _controller.shiftRect(details.delta);
                                },
                                child: widget.header,
                              ),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: colors.divider,
                              ),
                              Expanded(child: widget.body),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Edges
              _buildHandle(
                Alignment.topCenter,
                SystemMouseCursors.resizeUpDown,
                (d) => _controller.updateRect(0, d.delta.dy, 0, -d.delta.dy),
              ),
              _buildHandle(
                Alignment.bottomCenter,
                SystemMouseCursors.resizeUpDown,
                (d) => _controller.updateRect(0, 0, 0, d.delta.dy),
              ),
              _buildHandle(
                Alignment.centerLeft,
                SystemMouseCursors.resizeLeftRight,
                (d) => _controller.updateRect(d.delta.dx, 0, -d.delta.dx, 0),
              ),
              _buildHandle(
                Alignment.centerRight,
                SystemMouseCursors.resizeLeftRight,
                (d) => _controller.updateRect(0, 0, d.delta.dx, 0),
              ),
              // Corners
              _buildHandle(
                Alignment.topLeft,
                SystemMouseCursors.resizeUpLeftDownRight,
                (d) => _controller.updateRect(d.delta.dx, d.delta.dy, -d.delta.dx, -d.delta.dy),
              ),
              _buildHandle(
                Alignment.topRight,
                SystemMouseCursors.resizeUpRightDownLeft,
                (d) => _controller.updateRect(0, d.delta.dy, d.delta.dx, -d.delta.dy),
              ),
              _buildHandle(
                Alignment.bottomLeft,
                SystemMouseCursors.resizeUpRightDownLeft,
                (d) => _controller.updateRect(d.delta.dx, 0, -d.delta.dx, d.delta.dy),
              ),
              _buildHandle(
                Alignment.bottomRight,
                SystemMouseCursors.resizeUpLeftDownRight,
                (d) => _controller.updateRect(0, 0, d.delta.dx, d.delta.dy),
              ),
            ],
          ),
        );
      },
    );
  }
}
