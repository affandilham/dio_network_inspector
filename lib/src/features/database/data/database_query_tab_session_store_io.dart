import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../contracts/database_query_tab_session_store.dart';
import '../domain/database_query_tab_session.dart';

class LocalDatabaseQueryTabSessionStore
    implements DatabaseQueryTabSessionStore {
  static const _fileName = 'dio_network_inspector_query_tabs.json';

  File? _file;

  Future<File> get _sessionFile async {
    final cachedFile = _file;
    if (cachedFile != null) return cachedFile;
    final directory = await getApplicationSupportDirectory();
    return _file = File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<List<DatabaseQueryTabSession>> read(String scope) async {
    try {
      final decoded = jsonDecode(await (await _sessionFile).readAsString());
      if (decoded is! Map) return const [];
      final tabs = decoded[scope];
      if (tabs is! List) return const [];
      return tabs
          .map(DatabaseQueryTabSession.tryParse)
          .whereType<DatabaseQueryTabSession>()
          .take(20)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> write(String scope, List<DatabaseQueryTabSession> tabs) async {
    try {
      final file = await _sessionFile;
      final existing = await _readAll(file);
      existing[scope] = tabs.map((tab) => tab.toJson()).toList(growable: false);
      await file.writeAsString(jsonEncode(existing));
    } catch (_) {
      // Session restoration is optional and must never interrupt querying.
    }
  }

  Future<Map<String, Object?>> _readAll(File file) async {
    if (!await file.exists()) return <String, Object?>{};
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map
          ? Map<String, Object?>.from(decoded)
          : <String, Object?>{};
    } on FormatException {
      return <String, Object?>{};
    }
  }
}
