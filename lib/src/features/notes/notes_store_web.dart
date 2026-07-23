class NotesStore {
  NotesStore._();

  static final instance = NotesStore._();
  final Map<String, String> _notes = {};

  Future<String> read(String key) async => _notes[key] ?? '';

  Future<void> write(String key, String value) async {
    if (value.trim().isEmpty) {
      _notes.remove(key);
    } else {
      _notes[key] = value;
    }
  }
}
