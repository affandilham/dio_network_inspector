import 'package:flutter/material.dart';

import '../../../../core/theme/inspector_colors.dart';
import '../../domain/sql/sql_autocomplete.dart';

class DatabaseAutocompletePopup extends StatelessWidget {
  const DatabaseAutocompletePopup({
    required this.suggestions,
    required this.highlightedIndex,
    required this.itemKeys,
    required this.scrollController,
    required this.onSelected,
    super.key,
  });

  final List<SqlAutocompleteSuggestion> suggestions;
  final int highlightedIndex;
  final Map<int, GlobalKey> itemKeys;
  final ScrollController scrollController;
  final ValueChanged<SqlAutocompleteSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Scrollbar(
          controller: scrollController,
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, index) => _SuggestionRow(
              key: itemKeys.putIfAbsent(index, GlobalKey.new),
              suggestion: suggestions[index],
              highlighted: index == highlightedIndex,
              onTap: () => onSelected(suggestions[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.highlighted,
    required this.onTap,
    super.key,
  });

  final SqlAutocompleteSuggestion suggestion;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: highlighted ? InspectorColors.primary : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(
                  _iconFor(suggestion.kind),
                  size: 19,
                  color: highlighted
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    suggestion.value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: highlighted ? Colors.white : null,
                    ),
                  ),
                ),
                if (suggestion.detail case final detail?) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      detail,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: highlighted
                            ? Colors.white70
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SqlAutocompleteKind kind) => switch (kind) {
    SqlAutocompleteKind.keyword => Icons.terminal_outlined,
    SqlAutocompleteKind.table => Icons.table_chart_outlined,
    SqlAutocompleteKind.cte => Icons.account_tree_outlined,
    SqlAutocompleteKind.column => Icons.view_column_outlined,
  };
}
