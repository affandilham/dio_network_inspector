import 'database_models.dart';

/// Builds read-only SQL for single and composite foreign-key navigation.
///
/// Values are always quoted as literals and identifiers originate from MySQL
/// metadata, but both are escaped again here as a defence in depth measure.
class DatabaseForeignKeyQueryBuilder {
  const DatabaseForeignKeyQueryBuilder._();

  static String? relatedSql({
    required DatabaseForeignKey relation,
    required Iterable<DatabaseForeignKey> allRelations,
    required Map<String, String?> row,
    required int limit,
  }) {
    final relations = groupFor(relation, allRelations);
    final where = _whereClause(
      relations: relations,
      row: row,
      sourceColumnFor: (item) => item.column,
      targetColumnFor: (item) => item.referencedColumn,
    );
    if (where == null) return null;
    return 'SELECT * FROM ${_quoteIdentifier(relation.referencedTable)} '
        'WHERE $where LIMIT $limit;';
  }

  static String? referencingSql({
    required DatabaseForeignKey relation,
    required Iterable<DatabaseForeignKey> allRelations,
    required Map<String, String?> row,
    required int limit,
  }) {
    final relations = groupFor(relation, allRelations);
    final where = _whereClause(
      relations: relations,
      row: row,
      sourceColumnFor: (item) => item.referencedColumn,
      targetColumnFor: (item) => item.column,
    );
    if (where == null) return null;
    return 'SELECT * FROM ${_quoteIdentifier(relation.table)} '
        'WHERE $where LIMIT $limit;';
  }

  static List<DatabaseForeignKey> groupFor(
    DatabaseForeignKey relation,
    Iterable<DatabaseForeignKey> allRelations,
  ) {
    final constraint = relation.constraintName.trim();
    if (constraint.isEmpty) return [relation];
    final normalizedTable = relation.table.toLowerCase();
    final normalizedConstraint = constraint.toLowerCase();
    final group =
        allRelations
            .where(
              (item) =>
                  item.table.toLowerCase() == normalizedTable &&
                  item.constraintName.toLowerCase() == normalizedConstraint,
            )
            .toList()
          ..sort((a, b) => a.ordinalPosition.compareTo(b.ordinalPosition));
    return group.isEmpty ? [relation] : group;
  }

  static String? _whereClause({
    required Iterable<DatabaseForeignKey> relations,
    required Map<String, String?> row,
    required String Function(DatabaseForeignKey relation) sourceColumnFor,
    required String Function(DatabaseForeignKey relation) targetColumnFor,
  }) {
    final predicates = <String>[];
    for (final relation in relations) {
      final value = _rowValue(row, sourceColumnFor(relation));
      if (value == null || value.isEmpty || value == 'NULL') return null;
      predicates.add(
        '${_quoteIdentifier(targetColumnFor(relation))} = '
        '${_quoteValue(value)}',
      );
    }
    return predicates.join(' AND ');
  }

  static String? _rowValue(Map<String, String?> row, String column) {
    final direct = row[column];
    if (direct != null) return direct;
    final normalized = column.toLowerCase();
    for (final entry in row.entries) {
      if (entry.key.toLowerCase() == normalized) return entry.value;
    }
    return null;
  }

  static String _quoteIdentifier(String identifier) {
    const quote = '`';
    return '$quote${identifier.replaceAll(quote, '$quote$quote')}$quote';
  }

  static String _quoteValue(String value) {
    final escaped = value.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
    return "'$escaped'";
  }
}
