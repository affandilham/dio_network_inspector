import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../contracts/database_saved_query_store.dart';
import '../domain/database_saved_query.dart';

class LocalDatabaseSavedQueryStore implements DatabaseSavedQueryStore {
  static const _fileName = 'dio_network_inspector_saved_queries.json';
  File? _file;

  Future<File> get _savedQueriesFile async {
    final cachedFile = _file;
    if (cachedFile != null) return cachedFile;
    final directory = await getApplicationSupportDirectory();
    return _file = File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<List<DatabaseSavedQuery>> read(String scope) async {
    try {
      final decoded = jsonDecode(
        await (await _savedQueriesFile).readAsString(),
      );
      if (decoded is! List) return const [];
      return decoded
          .map(DatabaseSavedQuery.tryParse)
          .whereType<DatabaseSavedQuery>()
          .where((entry) => entry.scope == scope)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> write(String scope, List<DatabaseSavedQuery> entries) async {
    try {
      final file = await _savedQueriesFile;
      final existing = await _readAll(file);
      final merged = [
        ...existing.where((entry) => entry.scope != scope),
        ...entries,
      ];
      await file.writeAsString(
        jsonEncode(merged.map((entry) => entry.toJson()).toList()),
      );
    } catch (_) {
      // Saved queries are optional and cannot interrupt database inspection.
    }
  }

  Future<List<DatabaseSavedQuery>> _readAll(File file) async {
    if (!await file.exists()) return const [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .map(DatabaseSavedQuery.tryParse)
          .whereType<DatabaseSavedQuery>()
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }
}
