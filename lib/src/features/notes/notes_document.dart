class NotesDocument {
  final String path;
  final String name;
  final String content;
  final bool isExternal;

  const NotesDocument({
    required this.path,
    required this.name,
    required this.content,
    this.isExternal = false,
  });
}
