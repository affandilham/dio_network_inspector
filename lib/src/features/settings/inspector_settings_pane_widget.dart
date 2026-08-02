import 'package:flutter/material.dart';

import '../../core/settings/inspector_settings.dart';
import '../../dio_network_inspector.dart';

/// Global inspector preferences shown in the same content area as Notes and
/// Database Inspector. New inspector features add their settings here.
class InspectorSettingsPaneWidget extends StatelessWidget {
  const InspectorSettingsPaneWidget({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SettingsHeader(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Database', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder<InspectorSettings>(
                  valueListenable: DioNetworkInspector.instance.settings,
                  builder: (context, settings, _) => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Release inactive query results'),
                    subtitle: const Text(
                      'Use less RAM by releasing rows from inactive query '
                      'tabs. Their SQL draft remains available to run again.',
                    ),
                    value: settings.releaseInactiveDatabaseQueryResults,
                    onChanged: (enabled) =>
                        DioNetworkInspector.instance.updateSettings(
                          settings.copyWith(
                            releaseInactiveDatabaseQueryResults: enabled,
                          ),
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder<InspectorSettings>(
                  valueListenable: DioNetworkInspector.instance.settings,
                  builder: (context, settings, _) => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Store query history in production'),
                    subtitle: const Text(
                      'Off by default. When enabled, successful read-only SQL '
                      'is stored locally on this device for production sessions.',
                    ),
                    value: settings.storeDatabaseQueryHistoryInProduction,
                    onChanged: (enabled) =>
                        DioNetworkInspector.instance.updateSettings(
                          settings.copyWith(
                            storeDatabaseQueryHistoryInProduction: enabled,
                          ),
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder<InspectorSettings>(
                  valueListenable: DioNetworkInspector.instance.settings,
                  builder: (context, settings, _) => Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Disconnect inactive database'),
                        subtitle: const Text(
                          'Optional. Disconnect MySQL only after there has '
                          'been no typing, click, scroll, table, or query '
                          'activity for the selected interval.',
                        ),
                        value: settings.enableDatabaseIdleDisconnect,
                        onChanged: (enabled) =>
                            DioNetworkInspector.instance.updateSettings(
                              settings.copyWith(
                                enableDatabaseIdleDisconnect: enabled,
                              ),
                            ),
                      ),
                      if (settings.enableDatabaseIdleDisconnect) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: DropdownButtonFormField<Duration>(
                            initialValue:
                                settings.databaseIdleDisconnectTimeout,
                            decoration: const InputDecoration(
                              labelText: 'Idle interval',
                              border: OutlineInputBorder(),
                            ),
                            items: _idleTimeoutOptions
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option.timeout,
                                    child: Text(option.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (timeout) {
                              if (timeout == null) return;
                              DioNetworkInspector.instance.updateSettings(
                                settings.copyWith(
                                  databaseIdleDisconnectTimeout: timeout,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

const _idleTimeoutOptions = <({String label, Duration timeout})>[
  (label: '1 minute', timeout: Duration(minutes: 1)),
  (label: '5 minutes', timeout: Duration(minutes: 5)),
  (label: '15 minutes', timeout: Duration(minutes: 15)),
  (label: '30 minutes', timeout: Duration(minutes: 30)),
];

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: const Row(
      children: [
        Icon(Icons.settings_outlined, size: 18),
        SizedBox(width: 8),
        Text(
          'Inspector settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
