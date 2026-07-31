import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import 'notes_markdown_blocks.dart';
import 'notes_markdown_diagrams.dart';
import 'notes_markdown_parser.dart';

export 'notes_markdown_diagrams.dart'
    show FlowEdge, FlowGraph, SequenceDiagram, SequenceMessage;

/// Renders the Markdown features available in the local Notes editor.
///
/// Parsing, reusable blocks, and diagram painters live in focused files so this
/// widget remains a small composition layer.
class NotesMarkdownPreview extends StatelessWidget {
  final String source;

  const NotesMarkdownPreview({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final parser = NotesMarkdownParser(source);
    final blocks = parser.parse();
    final headings = parser.headings();

    final colors = InspectorColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          left: BorderSide(color: colors.divider),
          right: BorderSide(color: colors.divider),
          bottom: BorderSide(color: colors.divider),
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(InspectorDimensions.radiusL),
        ),
      ),
      child: SelectionArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(InspectorDimensions.spacingM),
          itemCount: blocks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildBlock(blocks[index], headings),
        ),
      ),
    );
  }

  Widget _buildBlock(NotesPreviewBlock block, List<NotesHeading> headings) {
    return switch (block.type) {
      NotesPreviewBlockType.markdown => MarkdownBody(data: block.content),
      NotesPreviewBlockType.alert => NotesAlertPreview(
        type: block.title,
        content: block.content,
      ),
      NotesPreviewBlockType.code => NotesCodePreview(
        language: block.title,
        content: block.content,
      ),
      NotesPreviewBlockType.details => NotesDetailsPreview(
        title: block.title,
        content: block.content,
      ),
      NotesPreviewBlockType.mermaid => NotesMermaidPreview(
        source: block.content,
      ),
      NotesPreviewBlockType.plantUml => NotesPlantUmlPreview(
        source: block.content,
      ),
      NotesPreviewBlockType.tableOfContents => NotesTableOfContentsPreview(
        headings: headings,
      ),
    };
  }
}
