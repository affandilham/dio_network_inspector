import 'package:flutter/material.dart';

import '../../components/base_text.dart';
import '../../components/custom_popup_menu_item.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';

enum MarkdownInsertAction {
  alert,
  codeBlock,
  collapsibleSection,
  horizontalRule,
  mermaid,
  plantUml,
  tableOfContents,
  reformatTable,
}

class NotesPaneToolbar extends StatelessWidget {
  final bool isPreview;
  final bool isWrapping;
  final bool canUndo;
  final bool canRedo;
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

  const NotesPaneToolbar({
    super.key,
    required this.isPreview,
    required this.isWrapping,
    required this.canUndo,
    required this.canRedo,
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: InspectorColors.background,
        border: Border.all(color: InspectorColors.divider),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InspectorDimensions.radiusL),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _modeTab('Write', false),
              _modeTab('Preview', true),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(right: InspectorDimensions.spacingS),
                child: BaseText(
                  'Markdown',
                  style: InspectorTypography.bodySmall,
                  color: InspectorColors.tertiary,
                ),
              ),
            ],
          ),
          if (!isPreview) ...[
            const Divider(height: 1, color: InspectorColors.divider),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: InspectorDimensions.spacingXs,
                vertical: InspectorDimensions.spacingXs,
              ),
              child: Row(
                children: [
                  _historyTool(
                    Icons.undo,
                    'Undo (⌘/Ctrl+Z)',
                    canUndo ? onUndo : null,
                  ),
                  _historyTool(
                    Icons.redo,
                    'Redo (⌘/Ctrl+Shift+Z)',
                    canRedo ? onRedo : null,
                  ),
                  _separator(),
                  _tool(Icons.format_bold, 'Bold', onBold),
                  _tool(Icons.format_italic, 'Italic', onItalic),
                  _tool(
                    Icons.strikethrough_s,
                    'Strikethrough',
                    onStrikethrough,
                  ),
                  _separator(),
                  _tool(
                    Icons.format_list_bulleted,
                    'Bullet list',
                    onBulletList,
                  ),
                  _tool(
                    Icons.format_list_numbered,
                    'Numbered list',
                    onNumberedList,
                  ),
                  _tool(Icons.checklist, 'Task list', onTaskList),
                  _separator(),
                  _tool(Icons.code, 'Inline code', onInlineCode),
                  _tool(Icons.link, 'Link', onLink),
                  _tool(
                    Icons.table_chart_outlined,
                    'Reformat table',
                    onReformatTable,
                  ),
                  _tool(Icons.attach_file, 'Attachment link', onAttachment),
                  _tool(
                    Icons.terminal_outlined,
                    'Slash command',
                    onSlashCommand,
                  ),
                  _separator(),
                  _wrapToggle(),
                  _moreMenu(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool preview) {
    final selected = isPreview == preview;
    return InkWell(
      onTap: () => onModeChanged(preview),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: InspectorDimensions.spacingM,
          vertical: InspectorDimensions.spacingS,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? InspectorColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: BaseText(
          label,
          style: InspectorTypography.body.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          color: selected
              ? InspectorColors.textPrimary
              : InspectorColors.textSecondary,
        ),
      ),
    );
  }

  Widget _tool(IconData icon, String label, VoidCallback onPressed) {
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: InspectorDimensions.iconM),
          color: InspectorColors.textBlueGrey,
          splashRadius: 16,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _historyTool(IconData icon, String label, VoidCallback? onPressed) {
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: InspectorDimensions.iconM),
          color: InspectorColors.textBlueGrey,
          disabledColor: InspectorColors.tertiary.withAlpha(96),
          splashRadius: 16,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _separator() => const SizedBox(
    height: 20,
    child: VerticalDivider(width: 17, color: InspectorColors.divider),
  );

  Widget _wrapToggle() {
    final label = isWrapping
        ? 'Disable line wrap and scroll horizontally'
        : 'Wrap long lines';
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: onToggleWrap,
          icon: Icon(
            isWrapping ? Icons.wrap_text : Icons.swap_horiz,
            size: InspectorDimensions.iconM,
          ),
          color: isWrapping
              ? InspectorColors.primary
              : InspectorColors.textBlueGrey,
          splashRadius: 16,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _moreMenu() {
    return PopupMenuButton<MarkdownInsertAction>(
      tooltip: null,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 200),
      color: InspectorColors.background,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InspectorDimensions.radiusXl),
      ),
      onSelected: onInsertAction,
      itemBuilder: (context) => const [
        CustomPopupMenuItem(value: MarkdownInsertAction.alert, text: 'Alert'),
        CustomPopupMenuItem(
          value: MarkdownInsertAction.codeBlock,
          text: 'Code block',
        ),
        CustomPopupMenuItem(
          value: MarkdownInsertAction.collapsibleSection,
          text: 'Collapsible section',
        ),
        CustomPopupMenuItem(
          value: MarkdownInsertAction.horizontalRule,
          text: 'Horizontal rule',
        ),
        CustomPopupMenuItem(
          value: MarkdownInsertAction.mermaid,
          text: 'Mermaid diagram',
        ),
        CustomPopupMenuItem(
          value: MarkdownInsertAction.plantUml,
          text: 'PlantUML diagram',
        ),
        CustomPopupMenuItem(
          value: MarkdownInsertAction.tableOfContents,
          text: 'Table of contents',
        ),
        CustomPopupMenuItem(
          value: MarkdownInsertAction.reformatTable,
          text: 'Reformat table',
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: InspectorDimensions.spacingS),
        child: Icon(
          Icons.add,
          size: InspectorDimensions.iconL,
          color: InspectorColors.textBlueGrey,
        ),
      ),
    );
  }
}
