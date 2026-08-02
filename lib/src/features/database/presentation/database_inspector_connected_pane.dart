import 'package:flutter/material.dart';

import '../../../core/theme/inspector_colors.dart';
import '../application/database_inspector_controller.dart';
import '../application/database_inspector_state.dart';
import '../domain/database_table_search.dart';
import '../domain/database_models.dart';
import 'connection/database_inspector_connection_view.dart';
import 'query/database_inspector_query_workspace.dart';
import 'result/database_inspector_result_view.dart';

class DatabaseInspectorConnectedPane extends StatelessWidget {
  const DatabaseInspectorConnectedPane({
    required this.config,
    required this.state,
    required this.controller,
    super.key,
  });

  final MySqlInspectorConfig config;
  final DatabaseInspectorState state;
  final DatabaseInspectorController controller;

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => controller.recordUserActivity(),
    onPointerSignal: (_) => controller.recordUserActivity(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DatabaseInspectorToolbar(
          config: config,
          state: state,
          controller: controller,
        ),
        if (state.error case final error?)
          DatabaseInspectorErrorBanner(
            message: error,
            onDismiss: controller.clearError,
          ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 190,
                child: _DatabaseTableSidebar(
                  state: state,
                  controller: controller,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    DatabaseInspectorQueryWorkspace(
                      config: config,
                      state: state,
                      controller: controller,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: DatabaseInspectorResultView(
                        config: config,
                        state: state,
                        controller: controller,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DatabaseInspectorToolbar extends StatelessWidget {
  const _DatabaseInspectorToolbar({
    required this.config,
    required this.state,
    required this.controller,
  });

  final MySqlInspectorConfig config;
  final DatabaseInspectorState state;
  final DatabaseInspectorController controller;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: InspectorColors.divider)),
    ),
    child: Row(
      children: [
        const Icon(Icons.storage_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${config.database} · ${config.environmentLabel}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'Refresh tables',
          onPressed: state.isBusy ? null : controller.refreshTables,
          icon: const Icon(Icons.refresh),
        ),
        TextButton.icon(
          onPressed: state.isBusy ? null : controller.disconnect,
          icon: const Icon(Icons.link_off, size: 18),
          label: const Text('Disconnect'),
        ),
      ],
    ),
  );
}

class _DatabaseTableSidebar extends StatefulWidget {
  const _DatabaseTableSidebar({required this.state, required this.controller});

  final DatabaseInspectorState state;
  final DatabaseInspectorController controller;

  @override
  State<_DatabaseTableSidebar> createState() => _DatabaseTableSidebarState();
}

class _DatabaseTableSidebarState extends State<_DatabaseTableSidebar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filteredTables = DatabaseTableSearch.filter(
      widget.state.tables,
      _searchController.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Text(
            'Tables',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search tables',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear table search',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close, size: 18),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: filteredTables.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No tables match “${_searchController.text.trim()}”.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredTables.length,
                  itemBuilder: (context, index) {
                    final table = filteredTables[index];
                    return ListTile(
                      dense: true,
                      selected: widget.state.selectedTable == table.name,
                      leading: const Icon(Icons.table_chart_outlined, size: 17),
                      title: Text(table.name, overflow: TextOverflow.ellipsis),
                      onTap: widget.state.isBusy
                          ? null
                          : () => widget.controller.openTable(table.name),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
