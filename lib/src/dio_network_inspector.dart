import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'dart:convert';
import 'models/network_request.dart';
import 'models/split_orientation.dart';

class DioNetworkInspector {
  static final DioNetworkInspector _instance = DioNetworkInspector._internal();
  factory DioNetworkInspector() => _instance;
  DioNetworkInspector._internal();

  static DioNetworkInspector get instance => _instance;

  final ValueNotifier<List<NetworkRequest>> requests = ValueNotifier([]);
  final ValueNotifier<bool> isRecording = ValueNotifier(true);
  final ValueNotifier<bool> isNotesOpen = ValueNotifier(false);
  final ValueNotifier<bool> isUrlTesterOpen = ValueNotifier(false);
  final ValueNotifier<bool> isSidePaneOpen = ValueNotifier(true);
  final ValueNotifier<SplitOrientation> splitOrientation =
      ValueNotifier(SplitOrientation.side);

  /// Controls the inspector UI's theme. Defaults to [ThemeMode.system] which
  /// automatically follows the host application's theme.
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  static const int maxRequests = 200;

  void toggleSplitOrientation() {
    splitOrientation.value = splitOrientation.value == SplitOrientation.side
        ? SplitOrientation.bottom
        : SplitOrientation.side;
  }

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
