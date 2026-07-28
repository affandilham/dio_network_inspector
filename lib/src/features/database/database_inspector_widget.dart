import 'package:flutter/material.dart';

import '../../core/theme/inspector_colors.dart';
import '../../dio_network_inspector.dart';
import 'database_models.dart';
import 'mysql_database_client.dart';
import 'read_only_sql_validator.dart';

class InspectorDatabasePaneWidget extends StatefulWidget {
  const InspectorDatabasePaneWidget({super.key});

  @override
  State<InspectorDatabasePaneWidget> createState() =>
      _InspectorDatabasePaneWidgetState();
}

class _InspectorDatabasePaneWidgetState
    extends State<InspectorDatabasePaneWidget> {
  final _queryController = TextEditingController();
  MySqlDatabaseClient? _client;
  List<DatabaseTable> _tables = const [];
  DatabasePage? _page;
  String? _selectedTable;
  String? _error;
  bool _isBusy = false;
  int _offset = 0;

  MySqlInspectorConfig? get _config =>
      DioNetworkInspector.instance.databaseConfig;

  @override
  void dispose() {
    _queryController.dispose();
    _client?.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    final config = _config;
    if (config == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    final client = MySqlDatabaseClient(config);
    try {
      await client.connect();
      final tables = await client.listTables();
      if (!mounted) {
        await client.disconnect();
        return;
      }
      setState(() {
        _client = client;
        _tables = tables;
      });
    } catch (error) {
      await client.disconnect();
      if (mounted) setState(() => _error = _safeError(error, config));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _disconnect() async {
    final client = _client;
    if (client == null) return;
    setState(() => _isBusy = true);
    await client.disconnect();
    if (!mounted) return;
    setState(() {
      _client = null;
      _tables = const [];
      _page = null;
      _selectedTable = null;
      _offset = 0;
      _isBusy = false;
    });
  }

  Future<void> _refreshTables() async {
    final client = _client;
    final config = _config;
    if (client == null || config == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final tables = await client.listTables();
      if (mounted) setState(() => _tables = tables);
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error, config));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _openTable(String table, {int offset = 0}) async {
    final client = _client;
    final config = _config;
    if (client == null || config == null) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final page = await client.fetchRows(
        table: table,
        offset: offset,
        limit: config.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _selectedTable = table;
        _page = page;
        _offset = offset;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error, config));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _runQuery() async {
    final client = _client;
    final config = _config;
    if (client == null || config == null) return;
    final validation = ReadOnlySqlValidator.validate(
      _queryController.text,
      maximumRows: config.maxPageSize,
    );
    if (!validation.isAllowed) {
      setState(() => _error = validation.reason);
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final page = await client.executeReadOnly(_queryController.text);
      if (!mounted) return;
      setState(() {
        _selectedTable = null;
        _page = page;
        _offset = 0;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _safeError(error, config));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _safeError(Object error, MySqlInspectorConfig config) {
    var message = error.toString();
    for (final secret in [config.password, config.username, config.host]) {
      if (secret.isNotEmpty) message = message.replaceAll(secret, '•••');
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config == null) return _emptyConfiguration();
    if (_client == null) return _connectView(config);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(config),
        if (_error != null) _errorBanner(),
        Expanded(
          child: Row(
            children: [
              SizedBox(width: 190, child: _tableList()),
              const VerticalDivider(width: 1),
              Expanded(child: _content(config)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyConfiguration() => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Database Inspector belum dikonfigurasi oleh aplikasi host.',
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _connectView(MySqlInspectorConfig config) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MySQL Database Inspector',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Environment: ${config.environmentLabel}'),
              const SizedBox(height: 4),
              const Text(
                'Koneksi dibuat hanya setelah tombol Connect ditekan. '
                'Mode query selalu read-only.',
              ),
              if (config.isProduction) ...[
                const SizedBox(height: 12),
                const Text(
                  'Production connection: gunakan akun MySQL read-only.',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                _errorBanner(),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isBusy ? null : _connect,
                icon: _isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: const Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _toolbar(MySqlInspectorConfig config) => Container(
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
          onPressed: _isBusy ? null : _refreshTables,
          icon: const Icon(Icons.refresh),
        ),
        TextButton.icon(
          onPressed: _isBusy ? null : _disconnect,
          icon: const Icon(Icons.link_off, size: 18),
          label: const Text('Disconnect'),
        ),
      ],
    ),
  );

  Widget _errorBanner() => Container(
    width: double.infinity,
    color: Colors.red.withValues(alpha: 0.08),
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_error ?? '', style: const TextStyle(color: Colors.red)),
        ),
        IconButton(
          tooltip: 'Dismiss error',
          onPressed: () => setState(() => _error = null),
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );

  Widget _tableList() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Text(
          'Tables',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _tables.length,
          itemBuilder: (context, index) {
            final table = _tables[index];
            return ListTile(
              dense: true,
              selected: _selectedTable == table.name,
              leading: const Icon(Icons.table_chart_outlined, size: 17),
              title: Text(table.name, overflow: TextOverflow.ellipsis),
              onTap: _isBusy ? null : () => _openTable(table.name),
            );
          },
        ),
      ),
    ],
  );

  Widget _content(MySqlInspectorConfig config) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Read-only SQL',
                hintText: 'SELECT * FROM users WHERE id = 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isBusy ? null : _runQuery,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run read-only query'),
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(child: _resultView(config)),
    ],
  );

  Widget _resultView(MySqlInspectorConfig config) {
    final page = _page;
    if (_isBusy) return const Center(child: CircularProgressIndicator());
    if (page == null) {
      return const Center(
        child: Text('Pilih tabel atau jalankan query read-only.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedTable ?? 'Query result',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${page.rows.length} rows'),
            ],
          ),
        ),
        Expanded(child: _dataTable(page)),
        if (_selectedTable != null) _pagination(config, page),
      ],
    );
  }

  Widget _dataTable(DatabasePage page) {
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
              .map(
                (column) => DataColumn(
                  label: Tooltip(
                    message: column.type,
                    child: Text(
                      column.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          rows: page.rows
              .map(
                (row) => DataRow(
                  cells: page.columns
                      .map(
                        (column) => DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              row[column.name] ?? 'NULL',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _pagination(MySqlInspectorConfig config, DatabasePage page) =>
      Container(
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
              onPressed: _offset == 0 || _isBusy
                  ? null
                  : () => _openTable(
                      _selectedTable!,
                      offset: (_offset - config.pageSize).clamp(0, _offset),
                    ),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next page',
              onPressed: !page.hasMore || _isBusy
                  ? null
                  : () => _openTable(
                      _selectedTable!,
                      offset: _offset + config.pageSize,
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      );
}
