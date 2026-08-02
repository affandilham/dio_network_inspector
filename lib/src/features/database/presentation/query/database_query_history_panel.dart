import 'package:flutter/material.dart';

import '../../domain/database_query_history_entry.dart';

class DatabaseQueryHistoryPanel extends StatelessWidget {
  const DatabaseQueryHistoryPanel({
    required this.entries,
    required this.onSelected,
    required this.onClear,
    required this.onDelete,
    super.key,
  });

  final List<DatabaseQueryHistoryEntry> entries;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;
  final ValueChanged<DatabaseQueryHistoryEntry> onDelete;

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
                'Query history',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: entries.isEmpty ? null : onClear,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('No successful queries yet.'))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.terminal_outlined, size: 17),
                      title: Text(
                        entry.sql.replaceAll(RegExp(r'\s+'), ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        entry.executedAt.toLocal().toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove this query from history',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => onDelete(entry),
                      ),
                      onTap: () => onSelected(entry.sql),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
