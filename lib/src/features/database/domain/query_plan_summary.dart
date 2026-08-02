import 'database_models.dart';

class DatabaseQueryPlanStep {
  const DatabaseQueryPlanStep({
    required this.table,
    required this.accessType,
    required this.estimatedRows,
    required this.key,
    required this.extra,
  });

  final String table;
  final String accessType;
  final int? estimatedRows;
  final String? key;
  final String? extra;

  bool get isFullTableScan => accessType.toUpperCase() == 'ALL';
}

/// Compact, conservative summary of MySQL's tabular `EXPLAIN` output.
class DatabaseQueryPlanSummary {
  const DatabaseQueryPlanSummary(this.steps);

  final List<DatabaseQueryPlanStep> steps;

  int get estimatedRows =>
      steps.fold(0, (total, step) => total + (step.estimatedRows ?? 0));

  List<DatabaseQueryPlanStep> get fullTableScans =>
      steps.where((step) => step.isFullTableScan).toList(growable: false);

  static DatabaseQueryPlanSummary? tryFrom(DatabasePage page) {
    final names = {
      for (final column in page.columns) column.name.toLowerCase(): column.name,
    };
    final table = names['table'];
    final accessType = names['type'];
    final rows = names['rows'];
    if (table == null || accessType == null || rows == null) return null;
    return DatabaseQueryPlanSummary(
      page.rows
          .map(
            (row) => DatabaseQueryPlanStep(
              table: row[table] ?? '<derived>',
              accessType: row[accessType] ?? 'unknown',
              estimatedRows: int.tryParse(row[rows] ?? ''),
              key: names['key'] == null ? null : row[names['key']!],
              extra: names['extra'] == null ? null : row[names['extra']!],
            ),
          )
          .toList(growable: false),
    );
  }
}
