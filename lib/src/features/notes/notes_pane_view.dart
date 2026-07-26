import 'package:flutter/material.dart';

import '../../components/base_text.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import 'notes_document.dart';
import 'notes_pane_editor.dart';
import 'notes_pane_toolbar.dart';

class NotesPaneView extends StatelessWidget {
  final NotesDocument? document;
  final TextEditingController controller;
  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;
  final bool isFileAction;
  final bool isDeleteArmed;
  final bool isPreview;
  final bool isWrapping;
  final bool isSaving;
  final bool canUndo;
  final bool canRedo;
  final Future<void> Function() onOpen;
  final Future<void> Function() onCreate;
  final VoidCallback onArmDelete;
  final VoidCallback onCancelDelete;
  final Future<void> Function() onDelete;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrikethrough;
  final VoidCallback onBulletList;
  final VoidCallback onNumberedList;
  final VoidCallback onTaskList;
  final VoidCallback onInlineCode;
  final VoidCallback onLink;
  final VoidCallback onReformatTable;
  final VoidCallback onAttachment;
  final VoidCallback onSlashCommand;
  final VoidCallback onToggleWrap;
  final ValueChanged<MarkdownInsertAction> onInsertAction;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSave;
  final VoidCallback onCopy;

  const NotesPaneView({
    super.key,
    required this.document,
    required this.controller,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    required this.isFileAction,
    required this.isDeleteArmed,
    required this.isPreview,
    required this.isWrapping,
    required this.isSaving,
    required this.canUndo,
    required this.canRedo,
    required this.onOpen,
    required this.onCreate,
    required this.onArmDelete,
    required this.onCancelDelete,
    required this.onDelete,
    required this.onModeChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onBold,
    required this.onItalic,
    required this.onStrikethrough,
    required this.onBulletList,
    required this.onNumberedList,
    required this.onTaskList,
    required this.onInlineCode,
    required this.onLink,
    required this.onReformatTable,
    required this.onAttachment,
    required this.onSlashCommand,
    required this.onToggleWrap,
    required this.onInsertAction,
    required this.onChanged,
    required this.onSave,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(InspectorDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: InspectorDimensions.spacingXs),
          BaseText(
            document?.isExternal == true
                ? 'Opened from your file manager.'
                : 'One shared note, saved only on this device.',
            color: InspectorColors.textSecondary,
          ),
          if (isDeleteArmed) ...[
            const SizedBox(height: InspectorDimensions.spacingS),
            NotesDeleteConfirmation(
              fileName: document?.name ?? 'this file',
              isBusy: isFileAction,
              onCancel: onCancelDelete,
              onDelete: onDelete,
            ),
          ],
          const SizedBox(height: InspectorDimensions.spacingM),
          NotesPaneToolbar(
            isPreview: isPreview,
            isWrapping: isWrapping,
            canUndo: canUndo,
            canRedo: canRedo,
            onModeChanged: onModeChanged,
            onUndo: onUndo,
            onRedo: onRedo,
            onBold: onBold,
            onItalic: onItalic,
            onStrikethrough: onStrikethrough,
            onBulletList: onBulletList,
            onNumberedList: onNumberedList,
            onTaskList: onTaskList,
            onInlineCode: onInlineCode,
            onLink: onLink,
            onReformatTable: onReformatTable,
            onAttachment: onAttachment,
            onSlashCommand: onSlashCommand,
            onToggleWrap: onToggleWrap,
            onInsertAction: onInsertAction,
          ),
          Expanded(
            child: NotesPaneEditor(
              controller: controller,
              horizontalScrollController: horizontalScrollController,
              verticalScrollController: verticalScrollController,
              isPreview: isPreview,
              isWrapping: isWrapping,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: InspectorDimensions.spacingS),
          NotesPaneFooter(
            document: document,
            isSaving: isSaving,
            onSave: onSave,
            onCopy: onCopy,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        const BaseText('Local note', style: InspectorTypography.sectionTitle),
        const Spacer(),
        NotesFileActionButton(
          icon: Icons.folder_open_outlined,
          label: 'Open Markdown file',
          isBusy: isFileAction,
          onPressed: onOpen,
        ),
        NotesFileActionButton(
          icon: Icons.note_add_outlined,
          label: 'Create Markdown file',
          isBusy: isFileAction,
          onPressed: onCreate,
        ),
        NotesFileActionButton(
          icon: Icons.delete_outline,
          label: 'Delete current Markdown file',
          isBusy: isFileAction,
          onPressed: onArmDelete,
          isDestructive: true,
        ),
      ],
    );
  }
}
