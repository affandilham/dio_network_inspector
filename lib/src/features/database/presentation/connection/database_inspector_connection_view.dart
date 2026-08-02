import 'package:flutter/material.dart';

import '../../application/database_inspector_controller.dart';
import '../../application/database_inspector_state.dart';
import '../../domain/database_models.dart';

class DatabaseInspectorConnectionView extends StatelessWidget {
  const DatabaseInspectorConnectionView({
    required this.config,
    required this.state,
    required this.controller,
    super.key,
  });

  final MySqlInspectorConfig config;
  final DatabaseInspectorState state;
  final DatabaseInspectorController controller;

  @override
  Widget build(BuildContext context) => Center(
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
              if (state.error case final error?) ...[
                const SizedBox(height: 12),
                _ErrorMessage(message: error, onDismiss: controller.clearError),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state.isBusy ? null : controller.connect,
                icon: state.isBusy
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
}

class DatabaseInspectorErrorBanner extends StatelessWidget {
  const DatabaseInspectorErrorBanner({
    required this.message,
    required this.onDismiss,
    super.key,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) =>
      _ErrorMessage(message: message, onDismiss: onDismiss);
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Colors.red.withValues(alpha: 0.08),
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.red)),
        ),
        IconButton(
          tooltip: 'Dismiss error',
          onPressed: onDismiss,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );
}
