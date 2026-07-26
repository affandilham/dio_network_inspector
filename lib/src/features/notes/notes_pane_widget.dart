import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'markdown_table_formatter.dart';
import 'notes_pane_toolbar.dart';
import 'notes_pane_view.dart';
import 'notes_store.dart';

/// Stateful coordinator for the local Notes document.
///
/// The rendering lives in [NotesPaneView]; this file owns persistence, editor
/// commands, and the time-grouped undo/redo history.
class InspectorNotesPaneWidget extends StatefulWidget {
  const InspectorNotesPaneWidget({super.key});

  @override
  State<InspectorNotesPaneWidget> createState() =>
      _InspectorNotesPaneWidgetState();
}

class _InspectorNotesPaneWidgetState extends State<InspectorNotesPaneWidget> {
  static const _historyDebounce = Duration(milliseconds: 500);

  final _controller = TextEditingController();
  final _horizontalScrollController = ScrollController();
  final _verticalScrollController = ScrollController();
  final _history = <TextEditingValue>[];
  Timer? _historyTimer;
  TextEditingValue? _pendingHistory;
  var _historyIndex = -1;
  var _isRestoringHistory = false;
  var _isLoading = true;
  var _isPreview = false;
  var _isWrapping = true;
  var _isSaving = false;
  var _isFileAction = false;
  var _isDeleteArmed = false;
  NotesDocument? _document;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_recordHistory);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final document = await NotesStore.instance.read();
    if (!mounted) return;
    _controller.text = document.content;
    _resetHistory();
    setState(() {
      _document = document;
      _isLoading = false;
    });
  }

  Future<void> _save(String value) async {
    if (mounted) setState(() => _isSaving = true);
    try {
      await NotesStore.instance.write(value);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndClearHistory() async {
    _commitPendingHistory();
    await _save(_controller.text);
    if (!mounted) return;
    _resetHistory();
    setState(() {});
    _showMessage('Markdown saved — undo history cleared');
  }

  void _applyDocument(NotesDocument document) {
    _isRestoringHistory = true;
    _controller.value = TextEditingValue(
      text: document.content,
      selection: TextSelection.collapsed(offset: document.content.length),
    );
    _isRestoringHistory = false;
    _resetHistory();
    setState(() {
      _document = document;
      _isDeleteArmed = false;
    });
  }

  Future<void> _runFileAction(
    String action,
    Future<NotesDocument?> Function() operation,
  ) async {
    setState(() => _isFileAction = true);
    try {
      final document = await operation();
      if (!mounted || document == null) return;
      _applyDocument(document);
      if (action == 'delete') _showMessage('Markdown file deleted');
    } catch (error, stackTrace) {
      debugPrint(
        'Dio Network Inspector: could not $action a Markdown file.\n$error\n$stackTrace',
      );
      _showMessage(_fileActionError(action, error));
    } finally {
      if (mounted) setState(() => _isFileAction = false);
    }
  }

  Future<void> _openFromFileManager() =>
      _runFileAction('open', NotesStore.instance.openFromFileManager);
  Future<void> _createFromFileManager() =>
      _runFileAction('create', NotesStore.instance.createFromFileManager);
  Future<void> _deleteCurrentFile() =>
      _runFileAction('delete', NotesStore.instance.deleteCurrent);

  String _fileActionError(String action, Object error) {
    if (error is MissingPluginException) {
      return 'File picker is unavailable. Run flutter pub get, then fully restart the app.';
    }
    if (error is PlatformException &&
        (error.message?.trim().isNotEmpty ?? false)) {
      return 'Could not $action the Markdown file: ${error.message!.trim()}';
    }
    if (error.toString().contains('FileSystemException')) {
      return 'Access was denied for this Markdown file. Check the app file permissions.';
    }
    return 'Could not $action this Markdown file. Check the debug console for details.';
  }

  void _showMessage(String message) => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));

  void _replaceSelection(String replacement, {int? cursorOffset}) {
    final value = _controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    _setEditorValue(
      value.text.replaceRange(start, end, replacement),
      TextSelection.collapsed(
        offset: start + (cursorOffset ?? replacement.length),
      ),
    );
  }

  void _wrapSelection(String before, String after, String placeholder) {
    final value = _controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final content = value.text.substring(start, end).isEmpty
        ? placeholder
        : value.text.substring(start, end);
    final replacement = '$before$content$after';
    _setEditorValue(
      value.text.replaceRange(start, end, replacement),
      TextSelection(
        baseOffset: start + before.length,
        extentOffset: start + before.length + content.length,
      ),
    );
  }

  void _prefixLines(String prefix, String placeholder) {
    final value = _controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final content = value.text.substring(start, end);
    final replacement = (content.isEmpty ? placeholder : content)
        .split('\n')
        .map((line) => '$prefix$line')
        .join('\n');
    _setEditorValue(
      value.text.replaceRange(start, end, replacement),
      TextSelection(
        baseOffset: start,
        extentOffset: start + replacement.length,
      ),
    );
  }

  void _setEditorValue(String text, TextSelection selection) {
    _controller.value = TextEditingValue(text: text, selection: selection);
    _commitPendingHistory();
    _save(text);
  }

  void _insertAction(MarkdownInsertAction action) {
    switch (action) {
      case MarkdownInsertAction.alert:
        _replaceSelection('> [!NOTE]\n> Your note here.\n');
      case MarkdownInsertAction.codeBlock:
        _replaceSelection('```text\ncode\n```\n', cursorOffset: 8);
      case MarkdownInsertAction.collapsibleSection:
        _replaceSelection(
          '<details>\n<summary>Details</summary>\n\nContent\n</details>\n',
          cursorOffset: 19,
        );
      case MarkdownInsertAction.horizontalRule:
        _replaceSelection('\n---\n');
      case MarkdownInsertAction.mermaid:
        _replaceSelection(
          '```mermaid\ngraph TD\n  A --> B\n```\n',
          cursorOffset: 12,
        );
      case MarkdownInsertAction.plantUml:
        _replaceSelection(
          '```plantuml\n@startuml\nAlice -> Bob: Request\n@enduml\n```\n',
          cursorOffset: 21,
        );
      case MarkdownInsertAction.tableOfContents:
        _replaceSelection('[[_TOC_]]\n');
      case MarkdownInsertAction.reformatTable:
        _reformatCurrentTable();
    }
  }

  void _reformatCurrentTable() {
    final value = _controller.value;
    final range = _currentTableRange(value);
    if (range == null) {
      return _showMessage(
        'Select a Markdown table or place the cursor inside it',
      );
    }
    final formatted = formatMarkdownTableBlock(
      value.text.substring(range.start, range.end),
    );
    if (formatted == null) {
      return _showMessage('Could not reformat this Markdown table');
    }
    _setEditorValue(
      value.text.replaceRange(range.start, range.end, formatted),
      TextSelection(
        baseOffset: range.start,
        extentOffset: range.start + formatted.length,
      ),
    );
  }

  ({int start, int end})? _currentTableRange(TextEditingValue value) {
    final text = value.text;
    if (text.isEmpty) return null;
    final lines = <({int start, int end, String content})>[];
    for (var start = 0; ;) {
      final newline = text.indexOf('\n', start);
      final end = newline == -1 ? text.length : newline;
      lines.add((start: start, end: end, content: text.substring(start, end)));
      if (newline == -1) break;
      start = newline + 1;
    }
    int lineAt(int offset) => lines.indexWhere((line) {
      final value = offset.clamp(0, text.length);
      return value >= line.start && value <= line.end;
    });
    var first = lineAt(value.selection.start);
    var last = lineAt(
      value.selection.isCollapsed
          ? value.selection.end
          : math.max(value.selection.start, value.selection.end - 1).toInt(),
    );
    if (first == -1 || last == -1) return null;
    bool tableLine(int index) => lines[index].content.trim().contains('|');
    if (value.selection.isCollapsed) {
      if (!tableLine(first)) return null;
      while (first > 0 && tableLine(first - 1)) {
        first--;
      }
      while (last < lines.length - 1 && tableLine(last + 1)) {
        last++;
      }
    } else if (List.generate(
      last - first + 1,
      (index) => first + index,
    ).any((index) => !tableLine(index))) {
      return null;
    }
    return last - first + 1 < 2
        ? null
        : (start: lines[first].start, end: lines[last].end);
  }

  bool get _canUndo => _pendingHistory != null || _historyIndex > 0;
  bool get _canRedo =>
      _historyIndex >= 0 && _historyIndex < _history.length - 1;

  void _recordHistory() {
    if (_isRestoringHistory) return;
    final next = _controller.value;
    final previous =
        _pendingHistory?.text ??
        (_historyIndex >= 0 ? _history[_historyIndex].text : null);
    if (previous == next.text) return;
    final wasIdle = _pendingHistory == null;
    _pendingHistory = next;
    _historyTimer?.cancel();
    _historyTimer = Timer(_historyDebounce, _commitPendingHistory);
    if (wasIdle && mounted) setState(() {});
  }

  void _commitPendingHistory() {
    _historyTimer?.cancel();
    _historyTimer = null;
    final next = _pendingHistory;
    _pendingHistory = null;
    if (next == null ||
        (_historyIndex >= 0 && _history[_historyIndex].text == next.text)) {
      return;
    }
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(next);
    _historyIndex = _history.length - 1;
    if (mounted) setState(() {});
  }

  void _resetHistory() {
    _historyTimer?.cancel();
    _historyTimer = null;
    _pendingHistory = null;
    _history
      ..clear()
      ..add(_controller.value);
    _historyIndex = 0;
  }

  void _undo() {
    _commitPendingHistory();
    if (_canUndo) _restoreHistory(_historyIndex - 1);
  }

  void _redo() {
    _commitPendingHistory();
    if (_canRedo) _restoreHistory(_historyIndex + 1);
  }

  void _restoreHistory(int index) {
    _historyTimer?.cancel();
    _pendingHistory = null;
    _isRestoringHistory = true;
    _controller.value = _history[index];
    _isRestoringHistory = false;
    setState(() => _historyIndex = index);
    _save(_controller.text);
  }

  void _copyMarkdown() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    _showMessage('Markdown copied to clipboard');
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    _controller.removeListener(_recordHistory);
    _controller.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            _undo,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ): _undo,
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): _redo,
        LogicalKeySet(
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): _redo,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            _redo,
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            _saveAndClearHistory,
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS):
            _saveAndClearHistory,
      },
      child: NotesPaneView(
        document: _document,
        controller: _controller,
        horizontalScrollController: _horizontalScrollController,
        verticalScrollController: _verticalScrollController,
        isFileAction: _isFileAction,
        isDeleteArmed: _isDeleteArmed,
        isPreview: _isPreview,
        isWrapping: _isWrapping,
        isSaving: _isSaving,
        canUndo: _canUndo,
        canRedo: _canRedo,
        onOpen: _openFromFileManager,
        onCreate: _createFromFileManager,
        onArmDelete: () => setState(() => _isDeleteArmed = true),
        onCancelDelete: () => setState(() => _isDeleteArmed = false),
        onDelete: _deleteCurrentFile,
        onModeChanged: (preview) => setState(() => _isPreview = preview),
        onUndo: _undo,
        onRedo: _redo,
        onBold: () => _wrapSelection('**', '**', 'bold text'),
        onItalic: () => _wrapSelection('*', '*', 'italic text'),
        onStrikethrough: () => _wrapSelection('~~', '~~', 'strikethrough text'),
        onBulletList: () => _prefixLines('- ', 'List item'),
        onNumberedList: () => _prefixLines('1. ', 'List item'),
        onTaskList: () => _prefixLines('- [ ] ', 'Task'),
        onInlineCode: () => _wrapSelection('`', '`', 'code'),
        onLink: () => _wrapSelection('[', '](https://)', 'link text'),
        onReformatTable: _reformatCurrentTable,
        onAttachment: () =>
            _wrapSelection('[', '](path/to/file)', 'attachment'),
        onSlashCommand: () => _replaceSelection('/'),
        onToggleWrap: () => setState(() => _isWrapping = !_isWrapping),
        onInsertAction: _insertAction,
        onChanged: _save,
        onSave: _saveAndClearHistory,
        onCopy: _copyMarkdown,
      ),
    );
  }
}
