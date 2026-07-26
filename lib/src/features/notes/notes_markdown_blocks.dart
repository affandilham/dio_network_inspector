import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import 'notes_markdown_parser.dart';

class NotesAlertPreview extends StatelessWidget {
  final String type;
  final String content;

  const NotesAlertPreview({
    super.key,
    required this.type,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'TIP' => InspectorColors.success,
      'IMPORTANT' => Colors.purple,
      'WARNING' => InspectorColors.warning,
      'CAUTION' => InspectorColors.error,
      _ => InspectorColors.primary,
    };
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(InspectorDimensions.radiusS),
      ),
      padding: const EdgeInsets.all(InspectorDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${type[0]}${type.substring(1).toLowerCase()}',
            style: InspectorTypography.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: InspectorDimensions.spacingXs),
            MarkdownBody(data: content),
          ],
        ],
      ),
    );
  }
}

class NotesCodePreview extends StatelessWidget {
  final String language;
  final String content;

  const NotesCodePreview({
    super.key,
    required this.language,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InspectorDimensions.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2328),
        borderRadius: BorderRadius.circular(InspectorDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Text(
              language,
              style: InspectorTypography.bodySmall.copyWith(
                color: const Color(0xFFB8C1CC),
              ),
            ),
          if (language.isNotEmpty)
            const SizedBox(height: InspectorDimensions.spacingS),
          SelectableText(
            content,
            style: InspectorTypography.mono.copyWith(
              color: const Color(0xFFF1F5F9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class NotesDetailsPreview extends StatelessWidget {
  final String title;
  final String content;

  const NotesDetailsPreview({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: InspectorColors.background,
        border: Border.all(color: InspectorColors.divider),
        borderRadius: BorderRadius.circular(InspectorDimensions.radiusM),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: InspectorDimensions.spacingM,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            InspectorDimensions.spacingM,
            0,
            InspectorDimensions.spacingM,
            InspectorDimensions.spacingM,
          ),
          title: Text(
            title,
            style: InspectorTypography.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: MarkdownBody(data: content),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesTableOfContentsPreview extends StatelessWidget {
  final List<NotesHeading> headings;

  const NotesTableOfContentsPreview({super.key, required this.headings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(InspectorDimensions.spacingM),
      decoration: BoxDecoration(
        color: InspectorColors.background,
        border: Border.all(color: InspectorColors.divider),
        borderRadius: BorderRadius.circular(InspectorDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table of contents',
            style: InspectorTypography.body.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: InspectorDimensions.spacingS),
          if (headings.isEmpty)
            const Text('Add headings to generate a table of contents.')
          else
            ...headings.map(
              (heading) => Padding(
                padding: EdgeInsets.only(
                  left: (heading.level - 1) * InspectorDimensions.spacingM,
                  bottom: InspectorDimensions.spacingXs,
                ),
                child: Text(
                  '• ${heading.text}',
                  style: InspectorTypography.body.copyWith(
                    color: InspectorColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NotesDiagramCard extends StatelessWidget {
  final String title;
  final Widget child;

  const NotesDiagramCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(InspectorDimensions.spacingM),
      decoration: BoxDecoration(
        color: InspectorColors.background,
        border: Border.all(color: InspectorColors.divider),
        borderRadius: BorderRadius.circular(InspectorDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: InspectorTypography.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: InspectorDimensions.spacingS),
          ClipRect(child: child),
        ],
      ),
    );
  }
}
