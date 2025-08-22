import 'package:flutter/material.dart';
import 'package:projects/services/auth/auth_service.dart';
import 'package:projects/services/crud/notes_services.dart';
import 'package:projects/utilities/generics/get_argument.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  DatabaseNote? _note;
  late final NoteServices _noteServices;
  late final TextEditingController _textController;

  @override
  void initState() {
    _noteServices = NoteServices();
    _textController = TextEditingController();
    super.initState();
  }

  void _textControlerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textController.text;
    await _noteServices.updateNote(note: note, text: text);
  }

  void _setupTextControlerListener() {
    _textController.removeListener(_textControlerListener);
    _textController.addListener(_textControlerListener);
  }


  Future<DatabaseNote> createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<DatabaseNote>();
    if(widgetNote != null){
      _note = widgetNote;
      _textController.text = widgetNote.text;
      return widgetNote;
    }
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _noteServices.getOrCreateUser(email: email);
    final newNote =  await _noteServices.createNote(owner: owner);
    _note = newNote;
    return newNote;
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      _noteServices.deleteNote(id: note.id);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && text.isNotEmpty) {
      await _noteServices.updateNote(note: note, text: text);
    }
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Note')),
      body: FutureBuilder<DatabaseNote>(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControlerListener();
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: \\${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Text('Unable to create note.'),
                );
              }
              _note = snapshot.data!;
              _setupTextControlerListener();
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start typing your note...'
                ),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
