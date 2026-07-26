enum NotesPreviewBlockType {
  markdown,
  alert,
  code,
  details,
  mermaid,
  plantUml,
  tableOfContents,
}

class NotesPreviewBlock {
  final NotesPreviewBlockType type;
  final String title;
  final String content;

  const NotesPreviewBlock(this.type, this.content, {this.title = ''});
}

class NotesHeading {
  final int level;
  final String text;

  const NotesHeading(this.level, this.text);
}

/// Splits a note into the GitLab-flavoured blocks supported by the local
/// preview. Keeping this parser independent of widgets makes it easy to test.
class NotesMarkdownParser {
  final List<String> _lines;

  NotesMarkdownParser(String source) : _lines = source.split('\n');

  List<NotesPreviewBlock> parse() {
    final blocks = <NotesPreviewBlock>[];
    final markdown = <String>[];

    void flushMarkdown() {
      final content = markdown.join('\n').trim();
      if (content.isNotEmpty) {
        blocks.add(NotesPreviewBlock(NotesPreviewBlockType.markdown, content));
      }
      markdown.clear();
    }

    var index = 0;
    while (index < _lines.length) {
      final line = _lines[index];
      if (line.trim() == '[[_TOC_]]') {
        flushMarkdown();
        blocks.add(
          const NotesPreviewBlock(NotesPreviewBlockType.tableOfContents, ''),
        );
        index++;
        continue;
      }

      final alertMatch = RegExp(r'^>\s*\[!([A-Za-z]+)\]\s*$').firstMatch(line);
      if (alertMatch != null) {
        flushMarkdown();
        final content = <String>[];
        index++;
        while (index < _lines.length && _lines[index].startsWith('>')) {
          content.add(_lines[index].replaceFirst(RegExp(r'^>\s?'), ''));
          index++;
        }
        blocks.add(
          NotesPreviewBlock(
            NotesPreviewBlockType.alert,
            content.join('\n').trim(),
            title: alertMatch.group(1)!.toUpperCase(),
          ),
        );
        continue;
      }

      if (line.trim().toLowerCase() == '<details>') {
        flushMarkdown();
        final content = <String>[];
        var title = 'Details';
        index++;
        while (index < _lines.length &&
            _lines[index].trim().toLowerCase() != '</details>') {
          final summary = RegExp(
            r'^<summary>(.*)</summary>$',
            caseSensitive: false,
          ).firstMatch(_lines[index].trim());
          if (summary != null) {
            title = summary.group(1)!.trim();
          } else {
            content.add(_lines[index]);
          }
          index++;
        }
        if (index < _lines.length) index++;
        blocks.add(
          NotesPreviewBlock(
            NotesPreviewBlockType.details,
            content.join('\n').trim(),
            title: title,
          ),
        );
        continue;
      }

      if (line.trimLeft().startsWith('```')) {
        flushMarkdown();
        final language = line.trimLeft().substring(3).trim().toLowerCase();
        final content = <String>[];
        index++;
        while (index < _lines.length &&
            !_lines[index].trimLeft().startsWith('```')) {
          content.add(_lines[index]);
          index++;
        }
        if (index < _lines.length) index++;
        final type = language == 'mermaid'
            ? NotesPreviewBlockType.mermaid
            : language == 'plantuml'
            ? NotesPreviewBlockType.plantUml
            : NotesPreviewBlockType.code;
        blocks.add(
          NotesPreviewBlock(type, content.join('\n'), title: language),
        );
        continue;
      }

      markdown.add(line);
      index++;
    }
    flushMarkdown();
    return blocks;
  }

  List<NotesHeading> headings() {
    final headings = <NotesHeading>[];
    for (var index = 0; index < _lines.length; index++) {
      final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(_lines[index]);
      if (heading != null) {
        headings.add(
          NotesHeading(heading.group(1)!.length, heading.group(2)!.trim()),
        );
        continue;
      }
      if (index + 1 < _lines.length &&
          RegExp(r'^(=+|-+)\s*$').hasMatch(_lines[index + 1]) &&
          _lines[index].trim().isNotEmpty) {
        headings.add(
          NotesHeading(
            _lines[index + 1].trim().startsWith('=') ? 1 : 2,
            _lines[index].trim(),
          ),
        );
      }
    }
    return headings;
  }
}
