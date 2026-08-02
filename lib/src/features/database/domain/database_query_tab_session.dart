/// Serializable metadata for one query tab.
///
/// Results and credentials are deliberately excluded so restoring a session
/// never increases retained database data or opens a connection.
class DatabaseQueryTabSession {
  const DatabaseQueryTabSession({
    required this.name,
    required this.draft,
    required this.isActive,
  });

  final String name;
  final String draft;
  final bool isActive;

  Map<String, Object> toJson() => {
    'name': name,
    'draft': draft,
    'isActive': isActive,
  };

  static DatabaseQueryTabSession? tryParse(Object? value) {
    if (value is! Map) return null;
    final name = value['name']?.toString().trim() ?? '';
    final draft = value['draft']?.toString() ?? '';
    if (name.isEmpty) return null;
    return DatabaseQueryTabSession(
      name: name,
      draft: draft,
      isActive: value['isActive'] == true,
    );
  }
}
