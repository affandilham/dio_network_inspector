import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/database_inspector_state.dart';
import '../../application/query/database_query_workspace_controller.dart';
import '../../application/query/database_query_workspace_state.dart';
import '../../contracts/database_inspector_controller_contract.dart';
import '../../domain/database_models.dart';
import 'database_autocomplete_popup.dart';
import 'database_query_history_panel.dart';
import 'database_saved_query_panel.dart';
import 'database_query_controls.dart';

/// Renders the SQL workspace. Editor behaviour lives in
/// [DatabaseQueryWorkspaceController]; this widget owns only Flutter views.
class DatabaseInspectorQueryWorkspace extends StatefulWidget {
  const DatabaseInspectorQueryWorkspace({
    required this.config,
    required this.state,
    required this.controller,
    super.key,
  });

  final MySqlInspectorConfig config;
  final DatabaseInspectorState state;
  final DatabaseInspectorControllerContract controller;

  @override
  State<DatabaseInspectorQueryWorkspace> createState() =>
      _DatabaseInspectorQueryWorkspaceState();
}

class _DatabaseInspectorQueryWorkspaceState
    extends State<DatabaseInspectorQueryWorkspace> {
  final _layerLink = LayerLink();
  final _autocompleteTapRegionGroupId = Object();
  final _editorKey = GlobalKey();
  final _editorScrollController = ScrollController();
  final _scrollController = ScrollController();
  final _itemKeys = <int, GlobalKey>{};
  late final DatabaseQueryWorkspaceController _workspace;
  OverlayEntry? _overlay;
  List<Object>? _lastSuggestions;
  var _popupWidth = 420.0;
  var _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _workspace = DatabaseQueryWorkspaceController(
      inspector: widget.controller,
      maximumRows: widget.config.maxPageSize,
    )..init();
    _workspace.addListener(_onWorkspaceChanged);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void reassemble() {
    super.reassemble();
    HardwareKeyboard.instance
      ..removeHandler(_handleKeyEvent)
      ..addHandler(_handleKeyEvent);
    _scheduleOverlaySync();
  }

  @override
  void dispose() {
    _removeOverlay();
    _workspace.removeListener(_onWorkspaceChanged);
    _workspace.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _scrollController.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  void _onWorkspaceChanged() {
    if (!mounted) return;
    if (!identical(_lastSuggestions, _workspace.value.suggestions)) {
      _lastSuggestions = _workspace.value.suggestions;
      _itemKeys.clear();
    }
    _scheduleOverlaySync();
  }

  bool _handleKeyEvent(KeyEvent event) {
    final state = _workspace.value;
    if (event is! KeyDownEvent || !_workspace.focusNode.hasFocus) {
      return false;
    }
    if (_isRunShortcut(event)) {
      if (!widget.state.isBusy && _workspace.validation.isAllowed) {
        _workspace.runActiveStatement();
      }
      return true;
    }
    if (!state.hasSuggestions) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _moveHighlight(1);
        return true;
      case LogicalKeyboardKey.arrowUp:
        _moveHighlight(-1);
        return true;
      case LogicalKeyboardKey.enter:
        if (HardwareKeyboard.instance.isShiftPressed) {
          _workspace.insertLineBreak();
        } else {
          _workspace.selectHighlightedSuggestion();
        }
        return true;
      case LogicalKeyboardKey.tab:
        _workspace.selectHighlightedSuggestion();
        return true;
      case LogicalKeyboardKey.escape:
        _workspace.dismissSuggestions();
        return true;
    }
    return false;
  }

  bool _isRunShortcut(KeyEvent event) =>
      event.logicalKey == LogicalKeyboardKey.enter &&
      HardwareKeyboard.instance.isControlPressed &&
      !HardwareKeyboard.instance.isMetaPressed &&
      !HardwareKeyboard.instance.isShiftPressed &&
      !HardwareKeyboard.instance.isAltPressed;

  void _moveHighlight(int delta) {
    final wrapped = _workspace.moveHighlight(delta);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _ensureHighlightedSuggestionVisible(delta, wrapped: wrapped),
    );
  }

  void _ensureHighlightedSuggestionVisible(
    int direction, {
    required bool wrapped,
  }) {
    if (!_scrollController.hasClients) return;
    if (wrapped) {
      _scrollController.animateTo(
        direction > 0 ? 0 : _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
      return;
    }
    final itemContext =
        _itemKeys[_workspace.value.highlightedIndex]?.currentContext;
    if (itemContext == null) return;
    Scrollable.ensureVisible(
      itemContext,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      alignmentPolicy: direction >= 0
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  void _scheduleOverlaySync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) _syncOverlay();
    });
  }

  void _syncOverlay() {
    final workspaceState = _workspace.value;
    if (!mounted || !workspaceState.hasSuggestions) {
      _removeOverlay();
      return;
    }
    final overlay = Overlay.maybeOf(context);
    final renderBox = _editorKey.currentContext?.findRenderObject();
    if (overlay == null || renderBox is! RenderBox || !renderBox.hasSize) {
      return;
    }
    _popupWidth = renderBox.size.width;
    if (_overlay != null) {
      _overlay!.markNeedsBuild();
      return;
    }
    _overlay = OverlayEntry(
      builder: (context) {
        final currentState = _workspace.value;
        return CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8),
          showWhenUnlinked: false,
          child: TapRegion(
            groupId: _autocompleteTapRegionGroupId,
            child: UnconstrainedBox(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: _popupWidth,
                height: (currentState.suggestions.length * 54.0 + 16)
                    .clamp(64, 300)
                    .toDouble(),
                child: DatabaseAutocompletePopup(
                  suggestions: currentState.suggestions,
                  highlightedIndex: currentState.highlightedIndex,
                  itemKeys: _itemKeys,
                  scrollController: _scrollController,
                  onSelected: _workspace.selectSuggestion,
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DatabaseQueryWorkspaceState>(
        valueListenable: _workspace,
        builder: (context, workspaceState, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DatabaseQueryTabs(
              tabs: widget.controller.queryTabs,
              activeTabId: widget.controller.activeQueryTab.id,
              isBusy: widget.state.isBusy,
              onCreate: _workspace.createQueryTab,
              isHistoryOpen: workspaceState.isHistoryOpen,
              onHistoryToggle: _workspace.toggleHistory,
              isSavedQueriesOpen: workspaceState.isSavedQueriesOpen,
              onSavedQueriesToggle: _workspace.toggleSavedQueries,
              onSelected: _workspace.selectQueryTab,
              onRename: _renameQueryTab,
              onClosed: _closeQueryTab,
            ),
            const Divider(height: 1),
            if (workspaceState.isHistoryOpen)
              DatabaseQueryHistoryPanel(
                entries: widget.state.queryHistory,
                onSelected: _workspace.insertHistoryQuery,
                onClear: widget.controller.clearQueryHistory,
                onDelete: widget.controller.deleteQueryHistory,
              ),
            if (workspaceState.isSavedQueriesOpen)
              DatabaseSavedQueryPanel(
                entries: widget.state.savedQueries,
                onSelected: _workspace.insertSavedQuery,
                onSaveActive: _saveActiveQuery,
                onDelete: widget.controller.deleteSavedQuery,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Column(
                children: [
                  NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (_) {
                      _scheduleOverlaySync();
                      return false;
                    },
                    child: SizeChangedLayoutNotifier(
                      child: TapRegion(
                        groupId: _autocompleteTapRegionGroupId,
                        onTapOutside: (_) => _workspace.dismissSuggestions(),
                        child: CompositedTransformTarget(
                          link: _layerLink,
                          child: DatabaseReadonlySqlEditor(
                            editorKey: _editorKey,
                            controller: _workspace.queryController,
                            focusNode: _workspace.focusNode,
                            isFocused: workspaceState.isFocused,
                            validation: _workspace.validation,
                            errorLine: workspaceState.errorLine,
                            scrollController: _editorScrollController,
                            onTap: _workspace.openSuggestions,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.state.isQueryRunning)
                          OutlinedButton.icon(
                            onPressed: widget.controller.cancelQuery,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('Cancel'),
                          )
                        else ...[
                          OutlinedButton.icon(
                            onPressed:
                                widget.state.isBusy || !_workspace.canExplain
                                ? null
                                : _workspace.explainActiveStatement,
                            icon: const Icon(Icons.insights_outlined),
                            label: const Text('Explain'),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Run active statement (Ctrl + Enter)',
                            child: FilledButton.icon(
                              onPressed:
                                  widget.state.isBusy ||
                                      !_workspace.validation.isAllowed
                                  ? null
                                  : _workspace.runActiveStatement,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Run'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _closeQueryTab(String id) async {
    final tab = widget.controller.queryTabs.firstWhere((tab) => tab.id == id);
    if (tab.draft.trim().isNotEmpty) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Close query tab?'),
          content: const Text(
            'This tab has a SQL draft. Closing it will discard the draft and its result.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep tab'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard and close'),
            ),
          ],
        ),
      );
      if (!mounted || shouldDiscard != true) return;
    }
    _workspace.closeQueryTab(id);
  }

  Future<void> _renameQueryTab(String id) async {
    final tab = widget.controller.queryTabs.firstWhere((tab) => tab.id == id);
    var draftName = tab.name;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename query tab'),
        content: TextFormField(
          initialValue: tab.name,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          onChanged: (value) => draftName = value,
          onFieldSubmitted: (value) => Navigator.of(context).pop(value),
          decoration: const InputDecoration(labelText: 'Tab name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(draftName),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || name == null) return;
    widget.controller.renameQueryTab(id, name);
  }

  Future<void> _saveActiveQuery() async {
    final statement = _workspace.activeStatement;
    final sql = statement?.sourceFrom(_workspace.queryController.text).trim();
    if (sql == null || sql.isEmpty || !_workspace.validation.isAllowed) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Place the cursor inside a valid read-only statement.'),
        ),
      );
      return;
    }

    var draftName = '';
    var draftFolder = '';
    final saved = await showDialog<({String name, String folder})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save query'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              autofocus: true,
              maxLength: 80,
              onChanged: (value) => draftName = value,
              decoration: const InputDecoration(labelText: 'Query name'),
            ),
            TextFormField(
              maxLength: 80,
              textInputAction: TextInputAction.done,
              onChanged: (value) => draftFolder = value,
              onFieldSubmitted: (_) => Navigator.of(
                context,
              ).pop((name: draftName, folder: draftFolder)),
              decoration: const InputDecoration(labelText: 'Folder (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop((name: draftName, folder: draftFolder)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || saved == null) return;
    widget.controller.saveQuery(
      name: saved.name,
      folder: saved.folder,
      sql: sql,
    );
  }
}
