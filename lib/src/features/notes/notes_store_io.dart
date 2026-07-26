import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

import 'notes_document.dart';

class NotesStore {
  NotesStore._();

  static final instance = NotesStore._();

  static const _markdownType = XTypeGroup(
    label: 'Markdown',
    extensions: ['md', 'markdown'],
  );

  File? _file;
  File? _defaultFile;
  File? _selectionFile;

  Future<void> _load() async {
    if (_file != null) return;
    final directory = await getApplicationDocumentsDirectory();
    _defaultFile = File(
      '${directory.path}${Platform.pathSeparator}dio_network_inspector_notes.md',
    );
    _selectionFile = File(
      '${directory.path}${Platform.pathSeparator}dio_network_inspector_notes_state.json',
    );

    final selectedPath = await _readSelectedPath();
    final selectedFile = selectedPath == null ? null : File(selectedPath);
    _file = selectedFile != null && await selectedFile.exists()
        ? selectedFile
        : _defaultFile;
    await _migrateLegacyNoteIfNeeded();
  }

  Future<void> _migrateLegacyNoteIfNeeded() async {
    if (_file != _defaultFile || await _defaultFile!.exists()) return;
    final legacyFile = File(
      '${_defaultFile!.parent.path}${Platform.pathSeparator}dio_network_inspector_notes.json',
    );
    if (!await legacyFile.exists()) return;
    try {
      final decoded = jsonDecode(await legacyFile.readAsString());
      if (decoded is Map<String, dynamic>) {
        final legacyNote = decoded['global-notes']?.toString() ?? '';
        if (legacyNote.isNotEmpty) {
          await _defaultFile!.writeAsString(legacyNote);
        }
      }
    } on FormatException {
      // A malformed legacy note must not prevent opening a new Markdown file.
    }
  }

  Future<String?> _readSelectedPath() async {
    if (!await _selectionFile!.exists()) return null;
    try {
      final decoded = jsonDecode(await _selectionFile!.readAsString());
      return decoded is Map<String, dynamic>
          ? decoded['path'] as String?
          : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _select(File file) async {
    _file = file;
    await _selectionFile!.writeAsString(jsonEncode({'path': file.path}));
  }

  NotesDocument _document(String content) => NotesDocument(
    path: _file!.path,
    name: _file!.uri.pathSegments.last,
    content: content,
    isExternal: _file!.path != _defaultFile!.path,
  );

  Future<NotesDocument> read() async {
    await _load();
    final content = await _file!.exists() ? await _file!.readAsString() : '';
    return _document(content);
  }

  Future<void> write(String value) async {
    await _load();
    await _file!.writeAsString(value);
  }

  Future<NotesDocument?> openFromFileManager() async {
    final selected = await openFile(
      acceptedTypeGroups: const [_markdownType],
      confirmButtonText: 'Open note',
    );
    if (selected == null || selected.path.isEmpty) return null;
    await _load();
    await _select(File(selected.path));
    return read();
  }

  Future<NotesDocument?> createFromFileManager() async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [_markdownType],
      suggestedName: 'notes.md',
      confirmButtonText: 'Create note',
      canCreateDirectories: true,
    );
    if (location == null || location.path.isEmpty) return null;
    var path = location.path;
    if (!path.toLowerCase().endsWith('.md')) path = '$path.md';
    final file = File(path);
    if (!await file.exists()) await file.writeAsString('');
    await _load();
    await _select(file);
    return read();
  }

  Future<NotesDocument> deleteCurrent() async {
    await _load();
    if (await _file!.exists()) await _file!.delete();
    _file = _defaultFile;
    if (await _selectionFile!.exists()) {
      await _selectionFile!.delete();
    }
    return read();
  }
}
