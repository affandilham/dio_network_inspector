import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../components/base_text.dart';
import '../../components/overflow_tooltip.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import 'notes_document.dart';
import 'notes_markdown_preview.dart';

class NotesPaneEditor extends StatelessWidget {
  final TextEditingController controller;
  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;
  final bool isPreview;
  final bool isWrapping;
  final ValueChanged<String> onChanged;

  const NotesPaneEditor({
    super.key,
    required this.controller,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    required this.isPreview,
    required this.isWrapping,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Offstage(offstage: isPreview, child: _editor(context)),
        ),
        Positioned.fill(
          child: Offstage(
            offstage: !isPreview,
            child: NotesMarkdownPreview(source: controller.text),
          ),
        ),
      ],
    );
  }

  Widget _editor(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: InspectorColors.surface,
        border: Border(
          left: BorderSide(color: InspectorColors.divider),
          right: BorderSide(color: InspectorColors.divider),
          bottom: BorderSide(color: InspectorColors.divider),
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(InspectorDimensions.radiusL),
        ),
      ),
      child: isWrapping ? _textField() : _nonWrappingEditor(context),
    );
  }

  Widget _nonWrappingEditor(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: controller.text.isEmpty ? ' ' : controller.text,
            style: InspectorTypography.mono.copyWith(
              color: InspectorColors.textPrimary,
              height: 1.55,
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final editorWidth = math.max(
          constraints.maxWidth,
          painter.width + InspectorDimensions.spacingM * 2,
        );

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Scrollbar(
            controller: verticalScrollController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.right,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.vertical,
            child: Scrollbar(
              controller: horizontalScrollController,
              thumbVisibility: true,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: editorWidth,
                  height: constraints.maxHeight,
                  child: _textField(scrollController: verticalScrollController),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _textField({ScrollController? scrollController}) {
    return TextField(
      controller: controller,
      scrollController: scrollController,
      expands: true,
      maxLines: null,
      minLines: null,
      textAlignVertical: TextAlignVertical.top,
      onChanged: onChanged,
      style: InspectorTypography.mono.copyWith(
        color: InspectorColors.textPrimary,
        height: 1.55,
      ),
      decoration: const InputDecoration(
        hintText: 'Write a shared debugging recap in Markdown…',
        hintStyle: TextStyle(color: InspectorColors.tertiary),
        contentPadding: EdgeInsets.all(InspectorDimensions.spacingM),
        border: InputBorder.none,
      ),
    );
  }
}

class NotesFileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isBusy;
  final VoidCallback onPressed;
  final bool isDestructive;

  const NotesFileActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isBusy,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: isBusy ? null : onPressed,
          icon: Icon(icon, size: InspectorDimensions.iconM),
          color: isDestructive
              ? InspectorColors.error
              : InspectorColors.textBlueGrey,
          splashRadius: 16,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class NotesDeleteConfirmation extends StatelessWidget {
  final String fileName;
  final bool isBusy;
  final VoidCallback onCancel;
  final Future<void> Function() onDelete;

  const NotesDeleteConfirmation({
    super.key,
    required this.fileName,
    required this.isBusy,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: InspectorDimensions.spacingS,
        vertical: InspectorDimensions.spacingXs,
      ),
      decoration: BoxDecoration(
        color: InspectorColors.error.withAlpha(16),
        border: Border.all(color: InspectorColors.error.withAlpha(64)),
        borderRadius: BorderRadius.circular(InspectorDimensions.radiusM),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: InspectorDimensions.iconS,
          ),
          const SizedBox(width: InspectorDimensions.spacingXs),
          Expanded(
            child: BaseText(
              'Delete $fileName?',
              style: InspectorTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
          TextButton(
            onPressed: isBusy ? null : onDelete,
            style: TextButton.styleFrom(foregroundColor: InspectorColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class NotesPaneFooter extends StatelessWidget {
  final NotesDocument? document;
  final bool isSaving;
  final Future<void> Function() onSave;
  final VoidCallback onCopy;

  const NotesPaneFooter({
    super.key,
    required this.document,
    required this.isSaving,
    required this.onSave,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final label = isSaving
        ? 'Saving…'
        : '${document?.isExternal == true ? 'Opened' : 'Saved locally'} · ${document?.name ?? 'dio_network_inspector_notes.md'}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 440;
        return Row(
          children: [
            Icon(
              isSaving ? Icons.sync : Icons.check_circle_outline,
              size: InspectorDimensions.iconS,
              color: InspectorColors.success,
            ),
            const SizedBox(width: InspectorDimensions.spacingXs),
            Expanded(
              child: OverflowTooltip(
                message: label,
                style: InspectorTypography.bodySmall,
                child: BaseText(
                  label,
                  maxLines: 1,
                  style: InspectorTypography.bodySmall,
                  color: InspectorColors.textSecondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: InspectorDimensions.spacingS),
            _action(
              compact,
              Icons.save_alt_outlined,
              'Save',
              'Save Markdown and clear undo history',
              isSaving ? null : onSave,
            ),
            _action(
              compact,
              Icons.copy_outlined,
              'Copy Markdown',
              'Copy Markdown',
              onCopy,
            ),
          ],
        );
      },
    );
  }

  Widget _action(
    bool compact,
    IconData icon,
    String label,
    String tooltip,
    VoidCallback? onPressed,
  ) {
    if (!compact) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: InspectorDimensions.iconS),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: InspectorColors.textBlueGrey,
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(
            horizontal: InspectorDimensions.spacingS,
            vertical: InspectorDimensions.spacingXs,
          ),
        ),
      );
    }
    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: InspectorDimensions.iconS),
          color: InspectorColors.textBlueGrey,
          splashRadius: 16,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
