import 'package:flutter/material.dart';
import 'json_viewer_controller.dart';
import 'json_node_widget.dart';
import 'json_viewer_toolbar.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';

class JsonViewerWidget extends StatefulWidget {
  final dynamic data;
  final bool initiallyExpanded;
  final bool showToolbar;
  final bool isScrollable;

  const JsonViewerWidget({
    super.key,
    required this.data,
    this.initiallyExpanded = false,
    this.showToolbar = true,
    this.isScrollable = true,
  });

  @override
  State<JsonViewerWidget> createState() => _JsonViewerWidgetState();
}

class _JsonViewerWidgetState extends State<JsonViewerWidget> {
  late JsonViewerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JsonViewerController()..init();
    _controller.parseData(widget.data);
  }

  @override
  void dispose() {
    _controller.disposeController();
    super.dispose();
  }

  @override
  void didUpdateWidget(JsonViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _controller.parseData(widget.data);
      _controller.calculateMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<JsonViewerStateData>(
      valueListenable: _controller,
      builder: (context, state, child) {
        final content = Container(
          width: double.infinity,
          color: InspectorColors.background,
          padding: const EdgeInsets.all(InspectorDimensions.spacingM),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: JsonNodeWidget(
              path: 'root',
              value: state.parsedData,
              isRoot: true,
              initiallyExpanded: widget.initiallyExpanded,
              searchQuery: state.searchQuery,
              matches: state.matches,
              activeMatchPath: state.matches.isNotEmpty
                  ? state.matches[state.currentMatchIndex]
                  : null,
              activeMatchKey: _controller.activeMatchKey,
              zoomLevel: state.zoomLevel,
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showToolbar)
              JsonViewerToolbarWidget(
                searchController: _controller.searchController,
                onSearchChanged: _controller.onSearchChanged,
                matchCount: state.matches.length,
                currentMatchIndex: state.currentMatchIndex,
                onPrevMatch: _controller.prevMatch,
                onNextMatch: _controller.nextMatch,
                onZoomIn: _controller.zoomIn,
                onZoomOut: _controller.zoomOut,
                zoomLevel: state.zoomLevel,
                hasShadow: state.isScrolled,
              ),
            if (widget.isScrollable)
              Expanded(
                child: SingleChildScrollView(
                  controller: _controller.scrollController,
                  child: content,
                ),
              )
            else
              content,
          ],
        );
      },
    );
  }
}
