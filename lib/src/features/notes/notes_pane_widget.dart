import 'package:flutter/material.dart';

import '../../components/base_text.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import 'notes_store.dart';

const _globalNoteKey = 'global-notes';

class InspectorNotesPaneWidget extends StatefulWidget {
  const InspectorNotesPaneWidget({super.key});

  @override
  State<InspectorNotesPaneWidget> createState() =>
      _InspectorNotesPaneWidgetState();
}

class _InspectorNotesPaneWidgetState extends State<InspectorNotesPaneWidget> {
  final _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final note = await NotesStore.instance.read(_globalNoteKey);
    if (!mounted) return;
    _controller.text = note;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(InspectorDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BaseText('Local note', style: InspectorTypography.sectionTitle),
          const SizedBox(height: InspectorDimensions.spacingXs),
          const BaseText(
            'One shared note, saved only on this device.',
            color: InspectorColors.textSecondary,
          ),
          const SizedBox(height: InspectorDimensions.spacingM),
          Expanded(
            child: TextField(
              controller: _controller,
              expands: true,
              maxLines: null,
              minLines: null,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (value) =>
                  NotesStore.instance.write(_globalNoteKey, value),
              style: InspectorTypography.body,
              decoration: InputDecoration(
                hintText: 'Add shared debugging notes…',
                alignLabelWithHint: true,
                filled: true,
                fillColor: InspectorColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    InspectorDimensions.radiusM,
                  ),
                  borderSide: const BorderSide(color: InspectorColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    InspectorDimensions.radiusM,
                  ),
                  borderSide: const BorderSide(color: InspectorColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    InspectorDimensions.radiusM,
                  ),
                  borderSide: const BorderSide(color: InspectorColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
