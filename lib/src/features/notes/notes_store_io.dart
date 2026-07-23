import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class NotesStore {
  NotesStore._();

  static final instance = NotesStore._();
  Map<String, String>? _notes;
  File? _file;

  Future<void> _load() async {
    if (_notes != null) return;
    final directory = await getApplicationDocumentsDirectory();
    _file = File(
      '${directory.path}${Platform.pathSeparator}dio_network_inspector_notes.json',
    );
    if (!await _file!.exists()) {
      _notes = {};
      return;
    }
    final source = await _file!.readAsString();
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    _notes = decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<String> read(String key) async {
    await _load();
    return _notes![key] ?? '';
  }

  Future<void> write(String key, String value) async {
    await _load();
    if (value.trim().isEmpty) {
      _notes!.remove(key);
    } else {
      _notes![key] = value;
    }
    await _file!.writeAsString(jsonEncode(_notes));
  }
}
