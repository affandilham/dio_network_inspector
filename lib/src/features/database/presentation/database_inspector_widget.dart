import 'package:flutter/material.dart';

import '../../../dio_network_inspector.dart';
import '../application/database_inspector_controller.dart';
import '../application/database_inspector_state.dart';
import '../data/mysql_database_client.dart';
import '../domain/database_models.dart';
import 'database_inspector_connected_pane.dart';
import 'connection/database_inspector_connection_view.dart';

/// Entry point for the read-only MySQL inspector pane.
class InspectorDatabasePaneWidget extends StatefulWidget {
  const InspectorDatabasePaneWidget({super.key});

  @override
  State<InspectorDatabasePaneWidget> createState() =>
      _InspectorDatabasePaneWidgetState();
}

class _InspectorDatabasePaneWidgetState
    extends State<InspectorDatabasePaneWidget> {
  late final DatabaseInspectorController _controller;

  MySqlInspectorConfig? get _config =>
      DioNetworkInspector.instance.databaseConfig;

  @override
  void initState() {
    super.initState();
    _controller = DatabaseInspectorController(
      configProvider: () => DioNetworkInspector.instance.databaseConfig,
      clientFactory: MySqlDatabaseClient.new,
      shouldReleaseInactiveQueryResults: () => DioNetworkInspector
          .instance
          .settings
          .value
          .releaseInactiveDatabaseQueryResults,
      shouldStoreQueryHistory: () {
        final config = DioNetworkInspector.instance.databaseConfig;
        return config == null ||
            !config.isProduction ||
            DioNetworkInspector
                .instance
                .settings
                .value
                .storeDatabaseQueryHistoryInProduction;
      },
      idleTimeoutProvider: () {
        final settings = DioNetworkInspector.instance.settings.value;
        return settings.enableDatabaseIdleDisconnect
            ? settings.databaseIdleDisconnectTimeout
            : null;
      },
    )..init();
    DioNetworkInspector.instance.settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() => _controller.recordUserActivity();

  @override
  void dispose() {
    DioNetworkInspector.instance.settings.removeListener(_onSettingsChanged);
    _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config == null) return const _DatabaseInspectorUnconfiguredView();
    return ValueListenableBuilder<DatabaseInspectorState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        if (!state.isConnected) {
          return DatabaseInspectorConnectionView(
            config: config,
            state: state,
            controller: _controller,
          );
        }
        return DatabaseInspectorConnectedPane(
          config: config,
          state: state,
          controller: _controller,
        );
      },
    );
  }
}

class _DatabaseInspectorUnconfiguredView extends StatelessWidget {
  const _DatabaseInspectorUnconfiguredView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Database Inspector belum dikonfigurasi oleh aplikasi host.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
