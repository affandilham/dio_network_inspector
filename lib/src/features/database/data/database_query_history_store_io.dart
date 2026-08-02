import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../contracts/database_query_history_store.dart';
import '../domain/database_query_history_entry.dart';

class LocalDatabaseQueryHistoryStore implements DatabaseQueryHistoryStore {
  static const _fileName = 'dio_network_inspector_query_history.json';

  File? _file;

  Future<File> get _historyFile async {
    final cachedFile = _file;
    if (cachedFile != null) return cachedFile;
    final directory = await getApplicationSupportDirectory();
    return _file = File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<List<DatabaseQueryHistoryEntry>> read(String scope) async {
    try {
      final file = await _historyFile;
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .map(DatabaseQueryHistoryEntry.tryParse)
          .whereType<DatabaseQueryHistoryEntry>()
          .where((entry) => entry.scope == scope)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> write(
    String scope,
    List<DatabaseQueryHistoryEntry> entries,
  ) async {
    try {
      final file = await _historyFile;
      final existingEntries = await _readAll(file);
      final mergedEntries = [
        ...existingEntries.where((entry) => entry.scope != scope),
        ...entries,
      ];
      await file.writeAsString(
        jsonEncode(mergedEntries.map((entry) => entry.toJson()).toList()),
      );
    } catch (_) {
      // Query history is a convenience feature. It must not affect querying.
    }
  }

  Future<List<DatabaseQueryHistoryEntry>> _readAll(File file) async {
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .map(DatabaseQueryHistoryEntry.tryParse)
          .whereType<DatabaseQueryHistoryEntry>()
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }
}
