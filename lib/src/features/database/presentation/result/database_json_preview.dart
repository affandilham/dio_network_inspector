import 'dart:convert';

import 'package:flutter/material.dart';

/// Compact, read-only renderer for values returned by MySQL JSON columns.
class DatabaseJsonPreview extends StatelessWidget {
  const DatabaseJsonPreview({
    required this.source,
    required this.formatted,
    super.key,
  });

  final String source;
  final String formatted;

  static String? tryFormat(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(source));
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Expanded(
        child: Text(source, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      IconButton(
        tooltip: 'Preview JSON',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.data_object_outlined, size: 18),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('JSON preview'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 480),
              child: SingleChildScrollView(
                child: SelectableText(
                  formatted,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
