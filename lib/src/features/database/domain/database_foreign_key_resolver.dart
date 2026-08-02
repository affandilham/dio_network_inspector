import 'database_models.dart';

/// Resolves a result column to a schema relation without guessing ambiguous
/// JOIN columns. MySQL metadata is preferred; a conservative `*_id` fallback
/// supports schemas that have not declared foreign-key constraints.
class DatabaseForeignKeyResolver {
  const DatabaseForeignKeyResolver._();

  static DatabaseForeignKey? resolve({
    required String columnName,
    required String? selectedTable,
    required List<DatabaseTable> tables,
    required List<DatabaseForeignKey> foreignKeys,
  }) {
    final column = columnName.toLowerCase();
    final metadataMatches = foreignKeys
        .where((relation) {
          final sameColumn = relation.column.toLowerCase() == column;
          if (selectedTable != null) {
            return sameColumn &&
                relation.table.toLowerCase() == selectedTable.toLowerCase();
          }
          return sameColumn ||
              '${relation.table}.${relation.column}'.toLowerCase() == column;
        })
        .toList(growable: false);
    final targets = <String, DatabaseForeignKey>{
      for (final relation in metadataMatches)
        '${relation.referencedTable.toLowerCase()}.'
                '${relation.referencedColumn.toLowerCase()}':
            relation,
    };
    if (targets.length == 1) {
      final target = targets.values.single;
      final sourceTables = metadataMatches
          .map((relation) => relation.table.toLowerCase())
          .toSet();
      final sourceIsUnambiguous = sourceTables.length == 1;
      // In a query result the source table may be unknown. Several tables can
      // legitimately expose `kandang_id`, but if every declared relation leads
      // to the same target the navigation is still deterministic.
      return DatabaseForeignKey(
        table: selectedTable ?? (sourceIsUnambiguous ? target.table : ''),
        column: columnName,
        referencedTable: target.referencedTable,
        referencedColumn: target.referencedColumn,
        constraintName: sourceIsUnambiguous ? target.constraintName : '',
        ordinalPosition: target.ordinalPosition,
        onUpdate: target.onUpdate,
        onDelete: target.onDelete,
      );
    }
    if (metadataMatches.isNotEmpty || !column.endsWith('_id')) return null;

    final stem = column.substring(0, column.length - 3);
    final targetNames = {stem, '${stem}s'};
    final targetMatches = tables
        .where((table) => targetNames.contains(table.name.toLowerCase()))
        .toList(growable: false);
    if (targetMatches.length != 1) return null;
    return DatabaseForeignKey(
      table: selectedTable ?? '',
      column: columnName,
      referencedTable: targetMatches.single.name,
      referencedColumn: 'id',
    );
  }
}
