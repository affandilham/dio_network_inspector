import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/inspector_colors.dart';
import 'notes_markdown_blocks.dart';

class NotesMermaidPreview extends StatelessWidget {
  final String source;

  const NotesMermaidPreview({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final graph = FlowGraph.parse(source);
    if (graph.edges.isEmpty) {
      return NotesCodePreview(language: 'mermaid', content: source);
    }
    return NotesDiagramCard(
      title: 'Mermaid diagram',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? math.max(150.0, constraints.maxWidth)
              : 280.0;
          return SizedBox(
            width: width,
            height: 100.0 + graph.maxRank * 92.0,
            child: CustomPaint(painter: _FlowchartPainter(graph, width)),
          );
        },
      ),
    );
  }
}

class NotesPlantUmlPreview extends StatelessWidget {
  final String source;

  const NotesPlantUmlPreview({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final sequence = SequenceDiagram.parse(source);
    if (sequence.messages.isEmpty) {
      return NotesCodePreview(language: 'plantuml', content: source);
    }
    return NotesDiagramCard(
      title: 'PlantUML diagram',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? math.max(150.0, constraints.maxWidth)
              : 280.0;
          return SizedBox(
            width: width,
            height: math.max(120.0, 78.0 + sequence.messages.length * 40.0),
            child: CustomPaint(painter: _SequencePainter(sequence, width)),
          );
        },
      ),
    );
  }
}

class FlowGraph {
  final List<String> nodes;
  final List<FlowEdge> edges;
  final Map<String, int> ranks;

  const FlowGraph(this.nodes, this.edges, this.ranks);

  int get maxRank => ranks.values.fold(0, math.max);

  static FlowGraph parse(String source) {
    final nodes = <String>[];
    final edges = <FlowEdge>[];
    final incoming = <String, int>{};
    for (final match in RegExp(
      r'([A-Za-z0-9_]+(?:-[A-Za-z0-9_]+)*)\s*[-=.]+>\s*([A-Za-z0-9_]+(?:-[A-Za-z0-9_]+)*)',
    ).allMatches(source)) {
      final from = match.group(1)!;
      final to = match.group(2)!;
      if (!nodes.contains(from)) nodes.add(from);
      if (!nodes.contains(to)) nodes.add(to);
      edges.add(FlowEdge(from, to));
      incoming[to] = (incoming[to] ?? 0) + 1;
    }
    final ranks = <String, int>{
      for (final node in nodes)
        if (!incoming.containsKey(node)) node: 0,
    };
    for (var pass = 0; pass < nodes.length; pass++) {
      for (final edge in edges) {
        ranks[edge.to] = math.max(
          ranks[edge.to] ?? 0,
          (ranks[edge.from] ?? 0) + 1,
        );
      }
    }
    return FlowGraph(nodes, edges, ranks);
  }
}

class FlowEdge {
  final String from;
  final String to;

  const FlowEdge(this.from, this.to);
}

class _FlowchartPainter extends CustomPainter {
  final FlowGraph graph;
  final double width;

  _FlowchartPainter(this.graph, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    const nodeWidth = 74.0;
    const nodeHeight = 34.0;
    final positions = <String, Offset>{};
    for (var rank = 0; rank <= graph.maxRank; rank++) {
      final nodes = graph.nodes
          .where((node) => graph.ranks[node] == rank)
          .toList();
      for (var index = 0; index < nodes.length; index++) {
        positions[nodes[index]] = Offset(
          width * (index + 1) / (nodes.length + 1),
          26 + rank * 92,
        );
      }
    }
    final linePaint = Paint()
      ..color = InspectorColors.textSecondary
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;
    for (final edge in graph.edges) {
      final from = positions[edge.from]!;
      final to = positions[edge.to]!;
      final start = Offset(from.dx, from.dy + nodeHeight / 2);
      final end = Offset(to.dx, to.dy - nodeHeight / 2);
      canvas.drawLine(start, end, linePaint);
      _drawArrow(canvas, start, end, linePaint.color);
    }
    for (final node in graph.nodes) {
      final center = positions[node]!;
      final rect = Rect.fromCenter(
        center: center,
        width: nodeWidth,
        height: nodeHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = InspectorColors.surfaceDark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        linePaint,
      );
      _paintLabel(canvas, node, center, InspectorColors.textPrimary);
    }
  }

  @override
  bool shouldRepaint(covariant _FlowchartPainter oldDelegate) =>
      oldDelegate.graph != graph || oldDelegate.width != width;
}

class SequenceDiagram {
  final List<String> participants;
  final List<SequenceMessage> messages;

  const SequenceDiagram(this.participants, this.messages);

  static SequenceDiagram parse(String source) {
    final participants = <String>[];
    final messages = <SequenceMessage>[];
    final expression = RegExp(
      r'^\s*([A-Za-z0-9_]+(?:-[A-Za-z0-9_]+)*)\s*(-->|->|<--|<-)\s*([A-Za-z0-9_]+(?:-[A-Za-z0-9_]+)*)\s*:\s*(.+)$',
    );
    for (final line in source.split('\n')) {
      final match = expression.firstMatch(line);
      if (match == null) continue;
      final from = match.group(1)!;
      final arrow = match.group(2)!;
      final to = match.group(3)!;
      final reverse = arrow.startsWith('<');
      final sender = reverse ? to : from;
      final receiver = reverse ? from : to;
      if (!participants.contains(sender)) participants.add(sender);
      if (!participants.contains(receiver)) participants.add(receiver);
      messages.add(
        SequenceMessage(
          sender,
          receiver,
          match.group(4)!,
          arrow.contains('--'),
        ),
      );
    }
    return SequenceDiagram(participants, messages);
  }
}

class SequenceMessage {
  final String from;
  final String to;
  final String label;
  final bool dashed;

  const SequenceMessage(this.from, this.to, this.label, this.dashed);
}

class _SequencePainter extends CustomPainter {
  final SequenceDiagram diagram;
  final double width;

  _SequencePainter(this.diagram, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <String, double>{
      for (var index = 0; index < diagram.participants.length; index++)
        diagram.participants[index]:
            width * (index + 1) / (diagram.participants.length + 1),
    };
    final linePaint = Paint()
      ..color = InspectorColors.textSecondary
      ..strokeWidth = 1.15;
    const participantWidth = 72.0;
    const participantHeight = 24.0;
    const headerY = 14.0;
    final footerY = size.height - 14.0;
    final lifelineEndY = footerY - participantHeight / 2 - 3;

    void drawParticipant(String participant, double x, double y) {
      final box = Rect.fromCenter(
        center: Offset(x, y),
        width: participantWidth,
        height: participantHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(4)),
        Paint()..color = InspectorColors.primaryContainer,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(4)),
        linePaint..style = PaintingStyle.stroke,
      );
      linePaint.style = PaintingStyle.stroke;
      _paintLabel(
        canvas,
        participant,
        Offset(x, y),
        InspectorColors.textPrimary,
      );
    }

    for (final participant in diagram.participants) {
      final x = positions[participant]!;
      drawParticipant(participant, x, headerY);
      _drawDashedLine(
        canvas,
        Offset(x, 27),
        Offset(x, lifelineEndY),
        linePaint,
      );
    }
    for (var index = 0; index < diagram.messages.length; index++) {
      final message = diagram.messages[index];
      final y = 54.0 + index * 40;
      final start = Offset(positions[message.from]!, y);
      final end = Offset(positions[message.to]!, y);
      if (message.dashed) {
        _drawDashedLine(canvas, start, end, linePaint);
      } else {
        canvas.drawLine(start, end, linePaint);
      }
      _drawArrow(canvas, start, end, linePaint.color);
      _paintLabel(
        canvas,
        message.label,
        Offset((start.dx + end.dx) / 2, y - 10),
        InspectorColors.textPrimary,
        size: 10,
      );
    }
    for (final participant in diagram.participants) {
      drawParticipant(participant, positions[participant]!, footerY);
    }
  }

  @override
  bool shouldRepaint(covariant _SequencePainter oldDelegate) =>
      oldDelegate.diagram != diagram || oldDelegate.width != width;
}

void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
  final length = (end - start).distance;
  final direction = (end - start) / length;
  for (var distance = 0.0; distance < length; distance += 7) {
    canvas.drawLine(
      start + direction * distance,
      start + direction * math.min(distance + 4, length),
      paint,
    );
  }
}

void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
  final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
  final path = Path()
    ..moveTo(end.dx, end.dy)
    ..lineTo(
      end.dx - 7 * math.cos(angle - 0.45),
      end.dy - 7 * math.sin(angle - 0.45),
    )
    ..lineTo(
      end.dx - 7 * math.cos(angle + 0.45),
      end.dy - 7 * math.sin(angle + 0.45),
    )
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

void _paintLabel(
  Canvas canvas,
  String label,
  Offset center,
  Color color, {
  double size = 11,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: 160);
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );
}
