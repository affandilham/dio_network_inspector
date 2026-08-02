import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/inspector_colors.dart';
import '../../application/database_inspector_state.dart';
import '../../domain/database_models.dart';
import '../widgets/sql_syntax_text.dart';

/// Read-only column structure for the currently browsed table.
class DatabaseTableStructureView extends StatelessWidget {
  const DatabaseTableStructureView({
    required this.table,
    required this.state,
    super.key,
  });

  final String table;
  final DatabaseInspectorState state;

  @override
  Widget build(BuildContext context) {
    final columns = state.tableColumns;
    if (columns.isEmpty) {
      return const Center(child: Text('No column metadata.'));
    }
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Columns'),
              Tab(text: 'Indexes'),
              Tab(text: 'Triggers'),
              Tab(text: 'DDL'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _columnsTable(columns),
                _indexesTable(),
                _triggersTable(),
                _ddlView(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _columnsTable(List<DatabaseColumn> columns) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(
      child: DataTable(
        headingRowHeight: 38,
        dataRowMinHeight: 34,
        // The Type column can contain a long enum definition. Keep the cell
        // wide enough to remain readable, while allowing the row to grow.
        dataRowMaxHeight: double.infinity,
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Column')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Nullable')),
          DataColumn(label: Text('Key')),
          DataColumn(label: Text('References')),
          DataColumn(label: Text('Actions')),
        ],
        rows: List.generate(columns.length, (index) {
          final column = columns[index];
          final relation = _relationFor(column);
          final isPrimary = _isPrimary(column);
          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(column.name)),
              DataCell(
                SizedBox(width: 260, child: Text(column.type, softWrap: true)),
              ),
              DataCell(Text(column.isNullable ? 'YES' : 'NO')),
              DataCell(
                Wrap(
                  spacing: 4,
                  children: [
                    if (isPrimary) const Chip(label: Text('PK')),
                    if (relation != null) const Chip(label: Text('FK')),
                  ],
                ),
              ),
              DataCell(
                Text(
                  relation == null
                      ? '—'
                      : '${relation.referencedTable}.${relation.referencedColumn}',
                ),
              ),
              DataCell(
                Text(
                  relation == null
                      ? '—'
                      : 'UPDATE ${relation.onUpdate ?? '—'}\n'
                            'DELETE ${relation.onDelete ?? '—'}',
                ),
              ),
            ],
          );
        }),
      ),
    ),
  );

  Widget _indexesTable() {
    final indexes = state.indexesByTable[table] ?? const [];
    if (indexes.isEmpty) return const Center(child: Text('No index metadata.'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 38,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 44,
          columns: const [
            DataColumn(label: Text('Index')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Unique')),
            DataColumn(label: Text('Columns')),
          ],
          rows: indexes
              .map(
                (index) => DataRow(
                  cells: [
                    DataCell(Text(index.name)),
                    DataCell(Text(index.type)),
                    DataCell(Text(index.isUnique ? 'YES' : 'NO')),
                    DataCell(Text(index.columns.join(', '))),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _triggersTable() {
    final triggers = state.triggersByTable[table] ?? const [];
    if (triggers.isEmpty) {
      return const Center(child: Text('No trigger metadata.'));
    }
    return _DatabaseTableTriggersAccordion(table: table, triggers: triggers);
  }

  Widget _ddlView(BuildContext context) {
    final ddl = state.ddlByTable[table];
    if (ddl == null || ddl.isEmpty) {
      return const Center(child: Text('DDL metadata is not available.'));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SelectionArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Text.rich(sqlSyntaxTextSpan(ddl)),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Tooltip(
                message: 'Copy DDL',
                child: IconButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: ddl)),
                  icon: const Icon(Icons.content_copy_outlined, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DatabaseForeignKey? _relationFor(DatabaseColumn column) {
    for (final relation in state.foreignKeys) {
      if (relation.table == table && relation.column == column.name) {
        return relation;
      }
    }
    return null;
  }

  bool _isPrimary(DatabaseColumn column) => column.name.toLowerCase() == 'id';
}

class _DatabaseTableTriggersAccordion extends StatefulWidget {
  const _DatabaseTableTriggersAccordion({
    required this.table,
    required this.triggers,
  });

  final String table;
  final List<DatabaseTableTrigger> triggers;

  @override
  State<_DatabaseTableTriggersAccordion> createState() =>
      _DatabaseTableTriggersAccordionState();
}

class _DatabaseTableTriggersAccordionState
    extends State<_DatabaseTableTriggersAccordion> {
  String? _expandedTriggerName;

  @override
  Widget build(BuildContext context) {
    final triggerCount = widget.triggers.length;
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: triggerCount + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) return _header(triggerCount);
        final trigger = widget.triggers[index - 1];
        return _triggerTile(trigger, _expandedTriggerName == trigger.name);
      },
    );
  }

  Widget _header(int triggerCount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Triggers on: ${widget.table}',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: InspectorColors.textPrimary,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        '$triggerCount ${triggerCount == 1 ? 'trigger' : 'triggers'}',
        style: const TextStyle(
          fontSize: 12,
          color: InspectorColors.textSecondary,
        ),
      ),
    ],
  );

  Widget _triggerTile(DatabaseTableTrigger trigger, bool isExpanded) {
    return Material(
      color: InspectorColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(
          () => _expandedTriggerName = isExpanded ? null : trigger.name,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: InspectorColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_outlined,
                      size: 18,
                      color: InspectorColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trigger.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TriggerBadge(label: trigger.timing),
                    const SizedBox(width: 4),
                    _TriggerBadge(label: trigger.event, isAccent: true),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: InspectorColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _descriptionFor(trigger),
                  style: const TextStyle(
                    fontSize: 12,
                    color: InspectorColors.textSecondary,
                  ),
                ),
                if (isExpanded) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: InspectorColors.divider),
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _detail(label: 'Table', value: widget.table),
                      _detail(label: 'Timing', value: trigger.timing),
                      _detail(label: 'Event', value: trigger.event),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Action executed',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Tooltip(
                        message: 'Copy trigger statement',
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: trigger.statement),
                          ),
                          icon: const Icon(
                            Icons.content_copy_outlined,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: InspectorColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectionArea(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text.rich(
                          sqlSyntaxTextSpan(
                            trigger.statement,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
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

  Widget _detail({required String label, required String value}) => RichText(
    text: TextSpan(
      style: const TextStyle(
        fontSize: 12,
        color: InspectorColors.textSecondary,
      ),
      children: [
        TextSpan(
          text: '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        TextSpan(text: value),
      ],
    ),
  );

  String _descriptionFor(DatabaseTableTrigger trigger) {
    final timing = trigger.timing.toLowerCase();
    final event = switch (trigger.event.toUpperCase()) {
      'INSERT' => 'a new row is inserted',
      'UPDATE' => 'an existing row is updated',
      'DELETE' => 'a row is deleted',
      _ => '${trigger.event.toLowerCase()} runs',
    };
    return 'Runs $timing $event.';
  }
}

class _TriggerBadge extends StatelessWidget {
  const _TriggerBadge({required this.label, this.isAccent = false});

  final String label;
  final bool isAccent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: isAccent
          ? InspectorColors.primaryContainer
          : InspectorColors.surfaceDark,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: isAccent
            ? InspectorColors.primary
            : InspectorColors.textSecondary,
      ),
    ),
  );
}
