import 'notes_document.dart';

class NotesStore {
  NotesStore._();

  static final instance = NotesStore._();
  String _content = '';
  String _name = 'dio_network_inspector_notes.md';

  Future<NotesDocument> read() async =>
      NotesDocument(path: _name, name: _name, content: _content);

  Future<void> write(String value) async => _content = value;

  Future<NotesDocument?> openFromFileManager() async => null;

  Future<NotesDocument?> createFromFileManager() async {
    _name = 'notes.md';
    _content = '';
    return read();
  }

  Future<NotesDocument> deleteCurrent() async {
    _content = '';
    return read();
  }
}
