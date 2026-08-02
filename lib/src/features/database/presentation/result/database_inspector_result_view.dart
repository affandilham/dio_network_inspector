import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/inspector_colors.dart';
import '../../application/database_inspector_controller.dart';
import '../../application/database_inspector_state.dart';
import '../../domain/database_models.dart';
import '../../domain/database_foreign_key_resolver.dart';
import '../../domain/export/database_result_exporter.dart';
import '../../domain/query_plan_summary.dart';
import 'database_json_preview.dart';
import 'database_table_structure_view.dart';

class DatabaseInspectorResultView extends StatefulWidget {
  const DatabaseInspectorResultView({
    required this.config,
    required this.state,
    required this.controller,
    super.key,
  });

  final MySqlInspectorConfig config;
  final DatabaseInspectorState state;
  final DatabaseInspectorController controller;

  @override
  State<DatabaseInspectorResultView> createState() =>
      _DatabaseInspectorResultViewState();
}

class _DatabaseInspectorResultViewState
    extends State<DatabaseInspectorResultView> {
  var _showStructure = false;

  @override
  void didUpdateWidget(covariant DatabaseInspectorResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedTable != widget.state.selectedTable) {
      _showStructure = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;
    final config = widget.config;
    final page = state.page;
    final selectedTable = state.selectedTable;
    if (state.isBusy) return const Center(child: CircularProgressIndicator());
    if (page == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            controller.activeQueryTab.resultWasEvicted
                ? 'Hasil query dilepas untuk menghemat RAM. Jalankan ulang query untuk melihat hasilnya.'
                : 'Pilih tabel atau jalankan query read-only.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final planSummary = DatabaseQueryPlanSummary.tryFrom(page);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedTable ??
                      (planSummary == null ? 'Query result' : 'Query plan'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                planSummary == null
                    ? '${page.rows.length} rows'
                    : '${planSummary.steps.length} operations',
              ),
              if (selectedTable != null) ...[
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Data'),
                  selected: !_showStructure,
                  onSelected: (_) => setState(() => _showStructure = false),
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('Structure'),
                  selected: _showStructure,
                  onSelected: (_) => setState(() => _showStructure = true),
                ),
              ],
              PopupMenuButton<DatabaseResultExportFormat>(
                tooltip: 'Export current result page',
                onSelected: (format) => _export(context, page, format),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: DatabaseResultExportFormat.csv,
                    child: Text('Export current page as CSV'),
                  ),
                  PopupMenuItem(
                    value: DatabaseResultExportFormat.json,
                    child: Text('Export current page as JSON'),
                  ),
                ],
                icon: const Icon(Icons.download_outlined),
              ),
            ],
          ),
        ),
        if (planSummary != null && !_showStructure)
          _QueryPlanSummaryView(summary: planSummary),
        Expanded(
          child: _showStructure && selectedTable != null
              ? DatabaseTableStructureView(table: selectedTable, state: state)
              : _DatabaseResultTable(
                  page: page,
                  state: state,
                  onInspectRelated: controller.inspectRelatedDataForRow,
                  onInspectReferencing: controller.inspectReferencingDataForRow,
                ),
        ),
        if (!_showStructure && selectedTable != null)
          _DatabasePagination(
            config: config,
            page: page,
            offset: state.offset,
            isBusy: state.isBusy,
            onPrevious: () => controller.openTable(
              selectedTable,
              offset: (state.offset - config.pageSize).clamp(0, state.offset),
            ),
            onNext: () => controller.openTable(
              selectedTable,
              offset: state.offset + config.pageSize,
            ),
          ),
      ],
    );
  }

  Future<void> _export(
    BuildContext context,
    DatabasePage page,
    DatabaseResultExportFormat format,
  ) async {
    final extension = DatabaseResultExporter.extensionFor(format);
    final label = widget.state.selectedTable ?? 'query-result';
    final suggestedName =
        '${_fileStem(label)}-page-${page.offset + 1}.$extension';
    try {
      final location = await getSaveLocation(
        acceptedTypeGroups: [
          XTypeGroup(label: extension.toUpperCase(), extensions: [extension]),
        ],
        suggestedName: suggestedName,
      );
      if (location == null || !context.mounted) return;
      final content = DatabaseResultExporter.encode(page, format);
      final file = XFile.fromData(
        Uint8List.fromList(utf8.encode(content)),
        mimeType: DatabaseResultExporter.mimeTypeFor(format),
        name: suggestedName,
      );
      await file.saveTo(location.path);
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Exported ${page.rows.length} rows to $suggestedName'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Unable to export the current result page.'),
        ),
      );
    }
  }

  String _fileStem(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-');
}

class _QueryPlanSummaryView extends StatelessWidget {
  const _QueryPlanSummaryView({required this.summary});

  final DatabaseQueryPlanSummary summary;

  @override
  Widget build(BuildContext context) {
    final fullScans = summary.fullTableScans;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: fullScans.isEmpty
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          Text('Estimated rows: ${summary.estimatedRows}'),
          if (fullScans.isEmpty)
            const Text('No full table scan detected')
          else
            Text(
              'Full scan: ${fullScans.map((step) => step.table).join(', ')}',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
        ],
      ),
    );
  }
}

class _DatabaseResultTable extends StatelessWidget {
  const _DatabaseResultTable({
    required this.page,
    required this.state,
    required this.onInspectRelated,
    required this.onInspectReferencing,
  });

  final DatabasePage page;
  final DatabaseInspectorState state;
  final void Function(DatabaseForeignKey relation, Map<String, String?> row)
  onInspectRelated;
  final void Function(DatabaseForeignKey relation, Map<String, String?> row)
  onInspectReferencing;

  @override
  Widget build(BuildContext context) {
    if (page.columns.isEmpty) {
      return const Center(child: Text('Query returned no columns.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 38,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 48,
          columns: page.columns
              .map((column) {
                final relation = _foreignKeyFor(column.name);
                final tooltip = relation == null
                    ? column.type
                    : '${column.type}\nForeign key → '
                          '${relation.referencedTable}.'
                          '${relation.referencedColumn}';
                return DataColumn(
                  label: Tooltip(
                    message: tooltip,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (relation != null) ...[
                          const Icon(
                            Icons.key_outlined,
                            size: 16,
                            color: InspectorColors.foreignKey,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          column.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .toList(growable: false),
          rows: page.rows
              .map(
                (row) => DataRow(
                  cells: page.columns
                      .map((column) => DataCell(_cell(context, row, column)))
                      .toList(growable: false),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    Map<String, String?> row,
    DatabaseColumn column,
  ) {
    final enumColumn = _enumColumnFor(column.name);
    final formattedJson = _isJsonColumn(column)
        ? DatabaseJsonPreview.tryFormat(row[column.name])
        : null;
    if (formattedJson != null) {
      return SizedBox(
        width: 260,
        child: DatabaseJsonPreview(
          source: row[column.name]!,
          formatted: formattedJson,
        ),
      );
    }
    final relation = _foreignKeyFor(column.name);
    final referencingRelations = _referencingForeignKeysFor(column.name);
    final value = row[column.name];
    if (relation != null && value != null) {
      return _ForeignKeyCell(
        value: value,
        relation: relation,
        row: row,
        isBusy: state.isBusy,
        onInspect: onInspectRelated,
      );
    }
    if (referencingRelations.isNotEmpty && value != null) {
      if (referencingRelations.length > 1) {
        return _ReverseForeignKeyMenu(
          value: value,
          relations: referencingRelations,
          row: row,
          isBusy: state.isBusy,
          onInspect: onInspectReferencing,
        );
      }
      return _ForeignKeyCell(
        value: value,
        relation: referencingRelations.single,
        row: row,
        isBusy: state.isBusy,
        onInspect: onInspectReferencing,
        reverse: true,
      );
    }
    if (enumColumn == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(
          row[column.name] ?? 'NULL',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    final selectedValue = enumColumn.enumValues.contains(value) ? value : null;
    return SizedBox(
      width: 220,
      child: Tooltip(
        message:
            'Pilihan ENUM ditampilkan untuk inspeksi. Database tetap read-only.',
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            isExpanded: true,
            value: selectedValue,
            hint: Text(value ?? 'NULL', overflow: TextOverflow.ellipsis),
            items: [
              ...enumColumn.enumValues.map(
                (enumValue) => DropdownMenuItem<String?>(
                  value: enumValue,
                  child: Text(enumValue, overflow: TextOverflow.ellipsis),
                ),
              ),
              if (enumColumn.isNullable)
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('NULL'),
                ),
            ],
            onChanged: state.isBusy
                ? null
                : (_) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Database Inspector bersifat read-only; nilai tidak diubah.',
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  DatabaseColumn? _enumColumnFor(String name) {
    if (state.selectedTable == null) return null;
    for (final column in state.tableColumns) {
      if (column.name == name && column.enumValues.isNotEmpty) return column;
    }
    return null;
  }

  DatabaseForeignKey? _foreignKeyFor(String name) {
    return DatabaseForeignKeyResolver.resolve(
      columnName: name,
      selectedTable: state.selectedTable,
      tables: state.tables,
      foreignKeys: state.foreignKeys,
    );
  }

  List<DatabaseForeignKey> _referencingForeignKeysFor(String name) {
    final table = state.selectedTable;
    if (table == null) return const [];
    return state.foreignKeys
        .where(
          (relation) =>
              relation.referencedTable == table &&
              relation.referencedColumn == name,
        )
        .toList(growable: false);
  }

  bool _isJsonColumn(DatabaseColumn column) =>
      column.type.toLowerCase().contains('json');
}

class _ForeignKeyCell extends StatelessWidget {
  const _ForeignKeyCell({
    required this.value,
    required this.relation,
    required this.row,
    required this.isBusy,
    required this.onInspect,
    this.reverse = false,
  });

  final String value;
  final DatabaseForeignKey relation;
  final Map<String, String?> row;
  final bool isBusy;
  final void Function(DatabaseForeignKey relation, Map<String, String?> row)
  onInspect;
  final bool reverse;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 190),
        child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      IconButton(
        tooltip: reverse
            ? 'Inspect ${relation.table}.${relation.column}'
            : 'Inspect ${relation.referencedTable}.${relation.referencedColumn}',
        visualDensity: VisualDensity.compact,
        iconSize: 17,
        onPressed: isBusy ? null : () => onInspect(relation, row),
        icon: const Icon(Icons.open_in_new_outlined),
      ),
    ],
  );
}

class _ReverseForeignKeyMenu extends StatelessWidget {
  const _ReverseForeignKeyMenu({
    required this.value,
    required this.relations,
    required this.row,
    required this.isBusy,
    required this.onInspect,
  });

  final String value;
  final List<DatabaseForeignKey> relations;
  final Map<String, String?> row;
  final bool isBusy;
  final void Function(DatabaseForeignKey relation, Map<String, String?> row)
  onInspect;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value),
      PopupMenuButton<DatabaseForeignKey>(
        tooltip: 'Inspect rows that reference this value',
        enabled: !isBusy,
        icon: const Icon(Icons.account_tree_outlined, size: 18),
        onSelected: (relation) => onInspect(relation, row),
        itemBuilder: (context) => relations
            .map(
              (relation) => PopupMenuItem(
                value: relation,
                child: Text('Show ${relation.table} via ${relation.column}'),
              ),
            )
            .toList(growable: false),
      ),
    ],
  );
}

class _DatabasePagination extends StatelessWidget {
  const _DatabasePagination({
    required this.config,
    required this.page,
    required this.offset,
    required this.isBusy,
    required this.onPrevious,
    required this.onNext,
  });

  final MySqlInspectorConfig config;
  final DatabasePage page;
  final int offset;
  final bool isBusy;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: InspectorColors.divider)),
    ),
    child: Row(
      children: [
        Text('Rows ${page.offset + 1}–${page.offset + page.rows.length}'),
        const Spacer(),
        IconButton(
          tooltip: 'Previous page',
          onPressed: offset == 0 || isBusy ? null : onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: !page.hasMore || isBusy ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );
}
