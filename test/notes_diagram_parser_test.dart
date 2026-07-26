import 'package:dio_network_inspector/src/features/notes/notes_markdown_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the Mermaid flowchart used by the GitLab reference', () {
    final diagram = FlowGraph.parse('''
graph TD;
  A-->B;
  A-->C;
  B-->D;
  C-->D;
''');

    expect(diagram.nodes, ['A', 'B', 'C', 'D']);
    expect(diagram.edges.map((edge) => '${edge.from}->${edge.to}'), [
      'A->B',
      'A->C',
      'B->D',
      'C->D',
    ]);
    expect(diagram.ranks, {'A': 0, 'B': 1, 'C': 1, 'D': 2});
  });

  test('parses PlantUML request and dashed response arrows', () {
    final diagram = SequenceDiagram.parse('''
@startuml
Alice -> Bob: Authentication Request
Bob --> Alice: Authentication Response
@enduml
''');

    expect(diagram.participants, ['Alice', 'Bob']);
    expect(diagram.messages, hasLength(2));
    expect(diagram.messages[0].from, 'Alice');
    expect(diagram.messages[0].to, 'Bob');
    expect(diagram.messages[0].dashed, isFalse);
    expect(diagram.messages[1].from, 'Bob');
    expect(diagram.messages[1].to, 'Alice');
    expect(diagram.messages[1].dashed, isTrue);
  });
}
