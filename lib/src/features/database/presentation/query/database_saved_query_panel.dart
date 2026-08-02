import 'package:flutter/material.dart';

import '../../domain/database_saved_query.dart';

/// Local, named read-only queries for the connected database scope.
class DatabaseSavedQueryPanel extends StatelessWidget {
  const DatabaseSavedQueryPanel({
    required this.entries,
    required this.onSelected,
    required this.onSaveActive,
    required this.onDelete,
    super.key,
  });

  final List<DatabaseSavedQuery> entries;
  final ValueChanged<String> onSelected;
  final VoidCallback onSaveActive;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxHeight: 180),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          child: Row(
            children: [
              const Text(
                'Saved queries',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onSaveActive,
                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                label: const Text('Save active'),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('No saved queries yet.'))
              : ListView(
                  children: [
                    for (final folder in _folders) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 12, 2),
                        child: Text(
                          folder.isEmpty ? 'General' : folder,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      for (final entry in entries.where(
                        (entry) => entry.folder == folder,
                      ))
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.bookmark_outline, size: 17),
                          title: Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            entry.sql.replaceAll(RegExp(r'\s+'), ' '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Delete saved query',
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => onDelete(entry.id),
                          ),
                          onTap: () => onSelected(entry.sql),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    ),
  );

  List<String> get _folders =>
      {for (final entry in entries) entry.folder}.toList()
        ..sort((left, right) => left.compareTo(right));
}
