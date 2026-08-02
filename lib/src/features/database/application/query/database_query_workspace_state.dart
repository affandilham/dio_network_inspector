import '../../domain/sql/sql_autocomplete.dart';

/// Render state for the SQL editor and its autocomplete list.
class DatabaseQueryWorkspaceState {
  const DatabaseQueryWorkspaceState({
    this.suggestions = const [],
    this.isFocused = false,
    this.isDismissed = false,
    this.highlightedIndex = 0,
    this.isHistoryOpen = false,
    this.isSavedQueriesOpen = false,
    this.errorLine,
  });

  final List<SqlAutocompleteSuggestion> suggestions;
  final bool isFocused;
  final bool isDismissed;
  final int highlightedIndex;
  final bool isHistoryOpen;
  final bool isSavedQueriesOpen;
  final int? errorLine;

  bool get hasSuggestions => !isDismissed && suggestions.isNotEmpty;

  DatabaseQueryWorkspaceState copyWith({
    List<SqlAutocompleteSuggestion>? suggestions,
    bool? isFocused,
    bool? isDismissed,
    int? highlightedIndex,
    bool? isHistoryOpen,
    bool? isSavedQueriesOpen,
    int? errorLine,
    bool clearErrorLine = false,
  }) => DatabaseQueryWorkspaceState(
    suggestions: suggestions ?? this.suggestions,
    isFocused: isFocused ?? this.isFocused,
    isDismissed: isDismissed ?? this.isDismissed,
    highlightedIndex: highlightedIndex ?? this.highlightedIndex,
    isHistoryOpen: isHistoryOpen ?? this.isHistoryOpen,
    isSavedQueriesOpen: isSavedQueriesOpen ?? this.isSavedQueriesOpen,
    errorLine: clearErrorLine ? null : errorLine ?? this.errorLine,
  );
}
