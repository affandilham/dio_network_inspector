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
    final colors = InspectorColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.divider),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(InspectorDimensions.radiusL),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _modeTab(context, 'Write', false),
              _modeTab(context, 'Preview', true),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: InspectorDimensions.spacingS),
                child: BaseText(
                  'Markdown',
                  style: InspectorTypography.bodySmall,
                  color: colors.tertiary,
                ),
              ),
            ],
          ),
          if (!isPreview) ...[
            Divider(height: 1, color: colors.divider),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: InspectorDimensions.spacingXs,
                vertical: InspectorDimensions.spacingXs,
              ),
              child: Row(
                children: [
                  _historyTool(context, Icons.undo, 'Undo (\u2318/Ctrl+Z)', canUndo ? onUndo : null),
                  _historyTool(context, Icons.redo, 'Redo (\u2318/Ctrl+Shift+Z)', canRedo ? onRedo : null),
                  _separator(context),
                  _tool(context, Icons.format_bold, 'Bold', onBold),
                  _tool(context, Icons.format_italic, 'Italic', onItalic),
                  _tool(context, Icons.strikethrough_s, 'Strikethrough', onStrikethrough),
                  _separator(context),
                  _tool(context, Icons.format_list_bulleted, 'Bullet list', onBulletList),
                  _tool(context, Icons.format_list_numbered, 'Numbered list', onNumberedList),
                  _tool(context, Icons.checklist, 'Task list', onTaskList),
                  _separator(context),
                  _tool(context, Icons.code, 'Inline code', onInlineCode),
                  _tool(context, Icons.link, 'Link', onLink),
                  _tool(context, Icons.table_chart_outlined, 'Reformat table', onReformatTable),
                  _tool(context, Icons.attach_file, 'Attachment link', onAttachment),
                  _tool(context, Icons.terminal_outlined, 'Slash command', onSlashCommand),
                  _separator(context),
                  _wrapToggle(context),
                  _moreMenu(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeTab(BuildContext context, String label, bool preview) {
    final colors = InspectorColors.of(context);
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
              color: selected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: BaseText(
          label,
          style: InspectorTypography.body.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          color: selected ? colors.textPrimary : colors.textSecondary,
        ),
      ),
    );
  }

  Widget _tool(BuildContext context, IconData icon, String label, VoidCallback onPressed) {
    final colors = InspectorColors.of(context);
    return Semantics(
      label: label,
      button: true,
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: InspectorDimensions.iconM),
          color: colors.textBlueGrey,
          splashRadius: 16,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _historyTool(BuildContext context, IconData icon, String label, VoidCallback? onPressed) {
    final colors = InspectorColors.of(context);
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      child: Tooltip(
        message: label,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: InspectorDimensions.iconM),
          color: colors.textBlueGrey,
          disabledColor: colors.tertiary.withAlpha(96),
          splashRadius: 16,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _separator(BuildContext context) {
    final colors = InspectorColors.of(context);
    return SizedBox(
      height: 20,
      child: VerticalDivider(width: 17, color: colors.divider),
    );
  }

  Widget _wrapToggle(BuildContext context) {
    final colors = InspectorColors.of(context);
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
          color: isWrapping ? colors.primary : colors.textBlueGrey,
          splashRadius: 16,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _moreMenu(BuildContext context) {
    final colors = InspectorColors.of(context);
    return PopupMenuButton<MarkdownInsertAction>(
      tooltip: null,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      constraints: const BoxConstraints(minWidth: 200),
      color: colors.background,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: InspectorDimensions.spacingS),
        child: Icon(
          Icons.add,
          size: InspectorDimensions.iconL,
          color: colors.textBlueGrey,
        ),
      ),
    );
  }
}
