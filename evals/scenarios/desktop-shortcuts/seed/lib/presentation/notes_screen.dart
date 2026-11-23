import 'package:material_ui/material_ui.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<String> _notes = <String>[];

  void _addNote() {
    setState(() {
      _notes.add('Note ${_notes.length + 1}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) => ListTile(title: Text(_notes[index])),
      ),
    );
  }
}
