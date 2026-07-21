import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/contracts/inspector_controller_contract.dart';

class JsonViewerStateData {
  final double zoomLevel;
  final String searchQuery;
  final int currentMatchIndex;
  final List<String> matches;
  final bool isScrolled;
  final dynamic parsedData;

  JsonViewerStateData({
    this.zoomLevel = 1.0,
    this.searchQuery = '',
    this.currentMatchIndex = 0,
    this.matches = const [],
    this.isScrolled = false,
    this.parsedData,
  });

  JsonViewerStateData copyWith({
    double? zoomLevel,
    String? searchQuery,
    int? currentMatchIndex,
    List<String>? matches,
    bool? isScrolled,
    dynamic parsedData,
  }) {
    return JsonViewerStateData(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      searchQuery: searchQuery ?? this.searchQuery,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
      matches: matches ?? this.matches,
      isScrolled: isScrolled ?? this.isScrolled,
      parsedData: parsedData ?? this.parsedData,
    );
  }
}

class JsonViewerController extends InspectorControllerContract<JsonViewerStateData> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final GlobalKey activeMatchKey = GlobalKey();

  JsonViewerController() : super(JsonViewerStateData());

  @override
  void init() {
    scrollController.addListener(_onScroll);
  }

  @override
  void disposeController() {
    scrollController.removeListener(_onScroll);
    searchController.dispose();
    scrollController.dispose();
    super.disposeController();
  }

  void parseData(dynamic data) {
    dynamic parsed = data;
    if (data is String) {
      try {
        parsed = jsonDecode(data);
      } catch (_) {}
    }
    value = value.copyWith(parsedData: parsed);
  }

  void _onScroll() {
    final isScrolled = scrollController.hasClients && scrollController.offset > 0;
    if (value.isScrolled != isScrolled) {
      value = value.copyWith(isScrolled: isScrolled);
    }
  }

  bool _isExpandable(dynamic val) => val is Map || val is List;

  void calculateMatches() {
    List<String> matches = [];
    if (value.searchQuery.isEmpty) {
      value = value.copyWith(matches: matches, currentMatchIndex: 0);
      return;
    }

    void traverse(dynamic val, String path, String? keyName) {
      bool isMatch = false;
      final q = value.searchQuery.toLowerCase();

      final keyStr = keyName?.toLowerCase() ?? '';
      final valStr = (val == null ? 'null' : val.toString()).toLowerCase();

      if (keyStr.contains(q) || (!_isExpandable(val) && valStr.contains(q))) {
        isMatch = true;
      } else if (!_isExpandable(val) && keyName != null) {
        final combined = '"$keyStr": $valStr';
        final combined2 = '$keyStr: $valStr';
        if (combined.contains(q) || combined2.contains(q)) {
          isMatch = true;
        }
      }

      if (isMatch) {
        matches.add(path);
      }

      if (val is Map) {
        val.forEach((k, v) {
          traverse(v, '$path.$k', k.toString());
        });
      } else if (val is List) {
        for (int i = 0; i < val.length; i++) {
          traverse(val[i], '$path.$i', i.toString());
        }
      }
    }

    traverse(value.parsedData, 'root', null);
    value = value.copyWith(matches: matches, currentMatchIndex: 0);
  }

  void onSearchChanged(String query) {
    value = value.copyWith(searchQuery: query);
    calculateMatches();
    scrollToMatch();
  }

  void nextMatch() {
    if (value.matches.isEmpty) return;
    value = value.copyWith(currentMatchIndex: (value.currentMatchIndex + 1) % value.matches.length);
    scrollToMatch();
  }

  void prevMatch() {
    if (value.matches.isEmpty) return;
    value = value.copyWith(
        currentMatchIndex: (value.currentMatchIndex - 1 + value.matches.length) % value.matches.length);
    scrollToMatch();
  }

  void scrollToMatch() {
    if (value.matches.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (activeMatchKey.currentContext != null) {
        Scrollable.ensureVisible(
          activeMatchKey.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void zoomIn() {
    value = value.copyWith(zoomLevel: (value.zoomLevel + 0.1).clamp(0.5, 3.0));
  }

  void zoomOut() {
    value = value.copyWith(zoomLevel: (value.zoomLevel - 0.1).clamp(0.5, 3.0));
  }
}
