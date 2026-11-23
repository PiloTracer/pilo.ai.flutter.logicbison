import 'package:flutter/services.dart';
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
    // Platform modifier: Cmd on macOS, Ctrl on Windows and Linux.
    final isMac = Theme.of(context).platform == TargetPlatform.macOS;
    final newNote = SingleActivator(
      LogicalKeyboardKey.keyN,
      control: true,
    );
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{newNote: _addNote},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(title: const Text('Notes')),
          floatingActionButton: FloatingActionButton(
            onPressed: _addNote,
            tooltip: isMac ? 'New note (Cmd+N)' : 'New note (Ctrl+N)',
            child: const Icon(Icons.add),
          ),
          body: ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) =>
                ListTile(title: Text(_notes[index])),
          ),
        ),
      ),
    );
  }
}
