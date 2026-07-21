import 'package:flutter/foundation.dart';
import 'models/network_request.dart';

class DioNetworkInspector {
  static final DioNetworkInspector _instance = DioNetworkInspector._internal();
  factory DioNetworkInspector() => _instance;
  DioNetworkInspector._internal();

  static DioNetworkInspector get instance => _instance;

  final ValueNotifier<List<NetworkRequest>> requests = ValueNotifier([]);
  final ValueNotifier<bool> isRecording = ValueNotifier(true);

  int _idCounter = 0;

  int generateId() {
    return _idCounter++;
  }

  void addRequest(NetworkRequest request) {
    final current = List<NetworkRequest>.from(requests.value);
    current.insert(0, request); // newest first
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
}
