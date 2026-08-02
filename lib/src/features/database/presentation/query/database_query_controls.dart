import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/inspector_colors.dart';
import '../../domain/database_models.dart';
import '../../domain/query_tabs_controller.dart';
import '../../application/query/active_statement_text_controller.dart';

const _sqlEditorLineHeight = 19.5;

class DatabaseQueryTabs extends StatelessWidget {
  const DatabaseQueryTabs({
    required this.tabs,
    required this.activeTabId,
    required this.isBusy,
    required this.onCreate,
    required this.isHistoryOpen,
    required this.onHistoryToggle,
    required this.isSavedQueriesOpen,
    required this.onSavedQueriesToggle,
    required this.onSelected,
    required this.onRename,
    required this.onClosed,
    super.key,
  });

  final List<DatabaseQueryTab> tabs;
  final String activeTabId;
  final bool isBusy;
  final VoidCallback onCreate;
  final bool isHistoryOpen;
  final VoidCallback onHistoryToggle;
  final bool isSavedQueriesOpen;
  final VoidCallback onSavedQueriesToggle;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onClosed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final tab = tabs[index];
              return Tooltip(
                message: isBusy ? '' : 'Double-click to rename',
                child: GestureDetector(
                  onDoubleTap: isBusy ? null : () => onRename(tab.id),
                  child: InputChip(
                    label: Text(tab.name),
                    selected: activeTabId == tab.id,
                    onPressed: isBusy ? null : () => onSelected(tab.id),
                    onDeleted: isBusy || tabs.length == 1
                        ? null
                        : () => onClosed(tab.id),
                  ),
                ),
              );
            },
          ),
        ),
        IconButton(
          tooltip: isHistoryOpen ? 'Hide query history' : 'Show query history',
          onPressed: isBusy ? null : onHistoryToggle,
          icon: Icon(
            Icons.history_outlined,
            color: isHistoryOpen ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        IconButton(
          tooltip: isSavedQueriesOpen
              ? 'Hide saved queries'
              : 'Show saved queries',
          onPressed: isBusy ? null : onSavedQueriesToggle,
          icon: Icon(
            Icons.bookmark_outline,
            color: isSavedQueriesOpen
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        IconButton(
          tooltip: 'New query tab',
          onPressed: isBusy ? null : onCreate,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}

class DatabaseReadonlySqlEditor extends StatelessWidget {
  const DatabaseReadonlySqlEditor({
    required this.editorKey,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.validation,
    required this.errorLine,
    required this.scrollController,
    required this.onTap,
    super.key,
  });

  final GlobalKey editorKey;
  final ActiveStatementTextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final ReadOnlySqlValidation validation;
  final int? errorLine;
  final ScrollController scrollController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInvalid = controller.text.isNotEmpty && !validation.isAllowed;
    controller.setErrorLine(errorLine);
    final borderColor = isFocused
        ? theme.colorScheme.primary
        : theme.dividerColor;
    return SizedBox(
      key: editorKey,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SqlLineNumberGutter(
                                  controller: controller,
                                  scrollController: scrollController,
                                  errorLine: errorLine,
                                ),
                                const VerticalDivider(width: 20),
                                Expanded(
                                  child: _SqlEditableLayer(
                                    controller: controller,
                                    focusNode: focusNode,
                                    scrollController: scrollController,
                                    onTap: onTap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isInvalid) ...[
                            const SizedBox(height: 4),
                            Text(
                              validation.reason ??
                                  'Query tidak dapat dijalankan.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: borderColor,
                          width: isFocused ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            top: -9,
            child: Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Read-only SQL',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns the editable renderer so the highlight can use its exact geometry.
class _SqlEditableLayer extends StatefulWidget {
  const _SqlEditableLayer({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.onTap,
  });

  final ActiveStatementTextEditingController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final VoidCallback onTap;

  @override
  State<_SqlEditableLayer> createState() => _SqlEditableLayerState();
}

class _SqlEditableLayerState extends State<_SqlEditableLayer> {
  final _editableKey = GlobalKey<EditableTextState>();
  Offset? _dragSelectionStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, widget.scrollController]),
      builder: (context, _) => CustomPaint(
        painter: _ActiveStatementBackgroundPainter(
          text: widget.controller.text,
          editableKey: _editableKey,
          activeRange: widget.controller.activeRange,
          viewportOffset: widget.scrollController.hasClients
              ? widget.scrollController.offset
              : 0,
        ),
        foregroundPainter: _SqlSelectionForegroundPainter(
          editableKey: _editableKey,
          selection: widget.controller.selection,
          viewportOffset: widget.scrollController.hasClients
              ? widget.scrollController.offset
              : 0,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: _handleTapDown,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: (_) => _dragSelectionStart = null,
          onPanCancel: () => _dragSelectionStart = null,
          child: EditableText(
            key: _editableKey,
            controller: widget.controller,
            focusNode: widget.focusNode,
            scrollController: widget.scrollController,
            expands: true,
            maxLines: null,
            minLines: null,
            style: _sqlEditorTextStyle,
            strutStyle: _sqlEditorStrutStyle,
            cursorColor: theme.colorScheme.primary,
            backgroundCursorColor: theme.colorScheme.onSurface,
            // Selection is painted by [_SqlSelectionForegroundPainter] so it
            // stays above the active-statement marker.
            selectionColor: Colors.transparent,
            selectionHeightStyle: ui.BoxHeightStyle.strut,
            selectionWidthStyle: ui.BoxWidthStyle.tight,
            rendererIgnoresPointer: true,
          ),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    widget.onTap();
    _selectAt(details.globalPosition, cause: SelectionChangedCause.tap);
  }

  void _handlePanStart(DragStartDetails details) {
    _dragSelectionStart = details.globalPosition;
    _selectAt(details.globalPosition, cause: SelectionChangedCause.drag);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final start = _dragSelectionStart;
    if (start == null) return;
    _selectAt(
      details.globalPosition,
      from: start,
      cause: SelectionChangedCause.drag,
    );
  }

  void _selectAt(
    Offset position, {
    Offset? from,
    required SelectionChangedCause cause,
  }) {
    widget.focusNode.requestFocus();
    _editableKey.currentState?.renderEditable.selectPositionAt(
      from: from ?? position,
      to: from == null ? null : position,
      cause: cause,
    );
  }
}

/// Draws the active statement behind the platform selection paint.
class _ActiveStatementBackgroundPainter extends CustomPainter {
  const _ActiveStatementBackgroundPainter({
    required this.text,
    required this.editableKey,
    required this.activeRange,
    required this.viewportOffset,
  });

  final String text;
  final GlobalKey<EditableTextState> editableKey;
  final TextRange? activeRange;
  final double viewportOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final range = activeRange;
    if (range == null || range.isCollapsed || range.end > text.length) return;
    final editable = editableKey.currentState?.renderEditable;
    if (editable == null || !editable.hasSize) return;
    final paint = Paint()..color = InspectorColors.activeStatementHighlight;
    final rows = _activeLineRects(editable, range);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      // Include the line-leading between adjacent statement rows, avoiding
      // thin visual gaps caused by glyph-tight selection boxes.
      final bottom = index + 1 < rows.length
          ? math.max(row.bottom, rows[index + 1].top)
          : row.bottom;
      canvas.drawRect(
        Rect.fromLTRB(row.left, row.top, row.right, bottom),
        paint,
      );
    }
    canvas.restore();
  }

  List<Rect> _activeLineRects(RenderEditable editable, TextRange range) {
    final rects = <Rect>[];
    for (final lineRange in _lineRanges(range)) {
      final boxes = editable.getBoxesForSelection(
        TextSelection(baseOffset: lineRange.start, extentOffset: lineRange.end),
      );
      if (boxes.isEmpty) continue;
      // A logical SQL line can soft-wrap into multiple visual rows. Using the
      // two caret positions loses the tail of the first row (for example
      // `WHERE`) because the end caret is already on the next row. Build one
      // highlight rect from the renderer's selection boxes per visual row.
      final rows = <double, List<TextBox>>{};
      for (final box in boxes) {
        rows.putIfAbsent(box.top, () => []).add(box);
      }
      for (final row in rows.values) {
        final left = row.map((box) => box.left).reduce(math.min);
        final right = row.map((box) => box.right).reduce(math.max);
        final top = row.map((box) => box.top).reduce(math.min);
        final bottom = row.map((box) => box.bottom).reduce(math.max);
        if (right > left) rects.add(Rect.fromLTRB(left, top, right, bottom));
      }
    }
    rects.sort((left, right) => left.top.compareTo(right.top));
    return rects;
  }

  Iterable<TextRange> _lineRanges(TextRange range) sync* {
    var lineStart = 0;
    for (var index = 0; index <= text.length; index++) {
      if (index != text.length && text[index] != '\n') continue;
      final start = math.max(range.start, lineStart);
      final end = math.min(range.end, index);
      if (start < end) yield TextRange(start: start, end: end);
      lineStart = index + 1;
    }
  }

  @override
  bool shouldRepaint(_ActiveStatementBackgroundPainter oldDelegate) =>
      text != oldDelegate.text ||
      activeRange != oldDelegate.activeRange ||
      viewportOffset != oldDelegate.viewportOffset ||
      editableKey != oldDelegate.editableKey;
}

/// Paints the user selection after [EditableText], above the active statement.
class _SqlSelectionForegroundPainter extends CustomPainter {
  const _SqlSelectionForegroundPainter({
    required this.editableKey,
    required this.selection,
    required this.viewportOffset,
  });

  final GlobalKey<EditableTextState> editableKey;
  final TextSelection selection;
  final double viewportOffset;

  @override
  void paint(Canvas canvas, Size size) {
    if (!selection.isValid || selection.isCollapsed) return;
    final editable = editableKey.currentState?.renderEditable;
    if (editable == null || !editable.hasSize) return;

    final paint = Paint()..color = const Color(0x802563EB);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final box in editable.getBoxesForSelection(selection)) {
      final rect = box.toRect();
      if (rect.width <= 0 || rect.height <= 0) continue;
      canvas.drawRect(rect, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SqlSelectionForegroundPainter oldDelegate) =>
      editableKey != oldDelegate.editableKey ||
      selection != oldDelegate.selection ||
      viewportOffset != oldDelegate.viewportOffset;
}

const _sqlEditorTextStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13,
  height: 1.5,
  color: InspectorColors.textPrimary,
);

const _sqlEditorStrutStyle = StrutStyle(
  fontSize: 13,
  height: 1.5,
  forceStrutHeight: true,
);

class _SqlLineNumberGutter extends StatelessWidget {
  const _SqlLineNumberGutter({
    required this.controller,
    required this.scrollController,
    required this.errorLine,
  });

  final ActiveStatementTextEditingController controller;
  final ScrollController scrollController;
  final int? errorLine;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([controller, scrollController]),
    builder: (context, _) {
      final scrollOffset = scrollController.hasClients
          ? scrollController.offset
          : 0.0;
      final lineCount = controller.text.split('\n').length;
      return SizedBox(
        width: 28,
        child: LayoutBuilder(
          builder: (context, constraints) => ClipRect(
            child: SizedBox(
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: -scrollOffset,
                    left: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(lineCount, (index) {
                        final line = index + 1;
                        final hasError = line == errorLine;
                        return SizedBox(
                          height: _sqlEditorLineHeight,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Text(
                              '$line',
                              maxLines: 1,
                              softWrap: false,
                              strutStyle: const StrutStyle(
                                fontSize: 13,
                                height: 1.5,
                                forceStrutHeight: true,
                              ),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: hasError
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: hasError
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
