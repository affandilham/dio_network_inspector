import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'models/network_request.dart';
import 'core/settings/inspector_settings.dart';
import 'features/database/domain/database_models.dart';

class DioNetworkInspector {
  static final DioNetworkInspector _instance = DioNetworkInspector._internal();
  factory DioNetworkInspector() => _instance;
  DioNetworkInspector._internal();

  static DioNetworkInspector get instance => _instance;

  final ValueNotifier<List<NetworkRequest>> requests = ValueNotifier([]);
  final ValueNotifier<bool> isRecording = ValueNotifier(true);
  final ValueNotifier<bool> isNotesOpen = ValueNotifier(false);
  final ValueNotifier<bool> isDatabaseOpen = ValueNotifier(false);
  final ValueNotifier<bool> isSettingsOpen = ValueNotifier(false);
  final ValueNotifier<InspectorSettings> settings = ValueNotifier(
    const InspectorSettings(),
  );
  MySqlInspectorConfig? databaseConfig;
  static const int maxRequests = 200;

  int _idCounter = 0;

  int generateId() {
    return _idCounter++;
  }

  void addRequest(NetworkRequest request) {
    final current = List<NetworkRequest>.from(requests.value);
    current.insert(0, request); // newest first
    if (current.length > maxRequests) {
      current.removeRange(maxRequests, current.length);
    }
    requests.value = current;
  }

  void updateRequest(NetworkRequest request) {
    final current = List<NetworkRequest>.from(requests.value);
    final index = current.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      current[index] = request;
      requests.value = current;
    }
  }

  void clear() {
    requests.value = [];
  }

  /// Sets an in-memory database configuration supplied by the host app.
  ///
  /// The inspector deliberately does not persist this value or add it to
  /// exported sessions.
  void configureDatabase(MySqlInspectorConfig? config) {
    databaseConfig = config;
    if (config == null) isDatabaseOpen.value = false;
  }

  /// Updates in-memory preferences shared by every inspector feature.
  void updateSettings(InspectorSettings updatedSettings) {
    settings.value = updatedSettings;
  }

  String exportSession() => jsonEncode({
    'format': 'dio-network-inspector/session-v1',
    'exportedAt': DateTime.now().toIso8601String(),
    'requests': requests.value.map((request) => request.toJson()).toList(),
  });

  void importSession(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final data = decoded['requests'];
    if (data is! List) {
      throw const FormatException('Session has no requests list.');
    }
    final imported = data
        .whereType<Map>()
        .map((item) => NetworkRequest.fromJson(Map<String, dynamic>.from(item)))
        .take(maxRequests)
        .toList();
    requests.value = imported;
    if (imported.isNotEmpty) {
      _idCounter =
          imported
              .map((request) => request.id)
              .reduce((a, b) => a > b ? a : b) +
          1;
    }
  }
}
