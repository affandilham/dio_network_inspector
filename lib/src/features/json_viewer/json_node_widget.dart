import 'package:flutter/material.dart';
import '../../components/base_text.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_typography.dart';

class JsonNodeWidget extends StatefulWidget {
  final String path;
  final String? keyName;
  final dynamic value;
  final bool isRoot;
  final bool initiallyExpanded;
  final String searchQuery;
  final List<String> matches;
  final String? activeMatchPath;
  final GlobalKey? activeMatchKey;
  final double zoomLevel;

  const JsonNodeWidget({
    super.key,
    required this.path,
    this.keyName,
    required this.value,
    this.isRoot = false,
    this.initiallyExpanded = false,
    this.searchQuery = '',
    this.matches = const [],
    this.activeMatchPath,
    this.activeMatchKey,
    this.zoomLevel = 1.0,
  });

  @override
  State<JsonNodeWidget> createState() => _JsonNodeWidgetState();
}

class _JsonNodeWidgetState extends State<JsonNodeWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded || _hasMatchDescendant();
  }

  @override
  void didUpdateWidget(JsonNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.activeMatchPath != oldWidget.activeMatchPath) {
      if (_hasMatchDescendant()) {
        _isExpanded = true;
      }
    }
  }

  bool _hasMatchDescendant() {
    if (widget.matches.isEmpty) return false;
    return widget.matches.any(
      (m) => m.startsWith(widget.path) && m != widget.path,
    );
  }

  bool get _isMatch => widget.matches.contains(widget.path);
  bool get _isActiveMatch => widget.activeMatchPath == widget.path;
  bool get _isExpandable => widget.value is Map || widget.value is List;

  void _toggle() {
    if (_isExpandable) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  String _getPreview(dynamic value) {
    if (value is Map) {
      if (value.isEmpty) return '{}';
      final entries = value.entries
          .take(3)
          .map((e) => '${e.key}: ${_getPreviewValue(e.value)}')
          .join(', ');
      return value.length > 3 ? '{$entries, ...}' : '{$entries}';
    } else if (value is List) {
      if (value.isEmpty) return '[]';
      return '[...] ${value.length} items';
    }
    return value.toString();
  }

  String _getPreviewValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value is Map) return '{...}';
    if (value is List) return '[...]';
    return value.toString();
  }

  Widget _buildValue(dynamic value, double fontSize) {
    if (value == null) {
      return BaseText(
        'null',
        style: InspectorTypography.mono.copyWith(fontSize: fontSize),
        color: InspectorColors.jsonNull,
      );
    } else if (value is String) {
      return BaseText(
        '"$value"',
        style: InspectorTypography.mono.copyWith(fontSize: fontSize),
        color: InspectorColors.jsonString,
      );
    } else if (value is num || value is bool) {
      return BaseText(
        value.toString(),
        style: InspectorTypography.mono.copyWith(fontSize: fontSize),
        color: InspectorColors.jsonNumber,
      );
    } else {
      return BaseText(
        value.toString(),
        style: InspectorTypography.mono.copyWith(fontSize: fontSize),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize = 12.0 * widget.zoomLevel;
    final double iconSize = 16.0 * widget.zoomLevel;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpandable)
          Icon(
            _isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
            size: iconSize,
            color: InspectorColors.textSecondary,
          )
        else
          SizedBox(width: iconSize),
        if (widget.keyName != null) ...[
          BaseText(
            '${widget.keyName}: ',
            style: InspectorTypography.mono.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
            color: InspectorColors.jsonKey,
          ),
        ],
        if (!_isExpanded || !_isExpandable)
          if (_isExpandable)
            BaseText(
              _getPreview(widget.value),
              style: InspectorTypography.mono.copyWith(fontSize: fontSize),
              color: InspectorColors.textSecondary,
            )
          else
            _buildValue(widget.value, fontSize)
        else
          BaseText(
            widget.value is Map ? '{' : '[',
            style: InspectorTypography.mono.copyWith(fontSize: fontSize),
          ),
      ],
    );

    if (_isMatch) {
      content = Container(
        key: _isActiveMatch ? widget.activeMatchKey : null,
        color: _isActiveMatch
            ? InspectorColors.warning.withValues(alpha: 0.4)
            : Colors.yellow.withValues(alpha: 0.4), // keep yellow standard
        child: content,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: _isExpandable
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: content,
          ),
        ),
        if (_isExpanded && _isExpandable)
          Padding(
            padding: EdgeInsets.only(left: 16.0 * widget.zoomLevel),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.value is Map)
                  ...((widget.value as Map).entries.map(
                    (e) => JsonNodeWidget(
                      path: '${widget.path}.${e.key}',
                      keyName: e.key.toString(),
                      value: e.value,
                      initiallyExpanded: widget.initiallyExpanded,
                      searchQuery: widget.searchQuery,
                      matches: widget.matches,
                      activeMatchPath: widget.activeMatchPath,
                      activeMatchKey: widget.activeMatchKey,
                      zoomLevel: widget.zoomLevel,
                    ),
                  ))
                else if (widget.value is List)
                  ...((widget.value as List).asMap().entries.map(
                    (e) => JsonNodeWidget(
                      path: '${widget.path}.${e.key}',
                      keyName: e.key.toString(),
                      value: e.value,
                      initiallyExpanded: widget.initiallyExpanded,
                      searchQuery: widget.searchQuery,
                      matches: widget.matches,
                      activeMatchPath: widget.activeMatchPath,
                      activeMatchKey: widget.activeMatchKey,
                      zoomLevel: widget.zoomLevel,
                    ),
                  )),
                BaseText(
                  widget.value is Map ? '}' : ']',
                  style: InspectorTypography.mono.copyWith(fontSize: fontSize),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
