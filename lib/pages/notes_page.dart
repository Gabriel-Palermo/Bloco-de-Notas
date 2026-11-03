import 'package:bloco_de_nota/models/note.dart';
import 'package:bloco_de_nota/pages/login_page.dart';
import 'package:bloco_de_nota/pages/note_form_page.dart';
import 'package:bloco_de_nota/services/auth_service.dart';
import 'package:bloco_de_nota/services/note_service.dart';
import 'package:bloco_de_nota/widgets/note_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteService noteService = NoteService();
  final AuthService authService = AuthService();

  List<Note> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // Primeiro carrega as notas locais.
      final localNotes = await noteService.getNotes(user.uid);

      if (mounted) {
        setState(() {
          notes = localNotes;
          isLoading = false;
        });
      }

      // Depois recupera as notas armazenadas no Firestore.
      await noteService.syncNotes(user.uid);

      // Atualiza a lista com as notas sincronizadas.
      final updatedNotes = await noteService.getNotes(user.uid);

      if (mounted) {
        setState(() {
          notes = updatedNotes;
        });
      }
    } catch (e) {
      debugPrint('ERRO AO CARREGAR/SINCRONIZAR NOTAS: $e');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> deleteNote(Note note) async {
    try {
      await noteService.deleteNote(note);
      await loadNotes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota deletada com sucesso!')),
        );
      }
    } catch (e) {
      debugPrint('ERRO AO DELETAR NOTA: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao deletar nota: $e')));
      }
    }
  }

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Future<void> openEditNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormPage(note: note)),
    );

    await loadNotes();
  }

  Future<void> openNewNote() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteFormPage()),
    );

    await loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas notas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openNewNote,
        backgroundColor: const Color(0xff6c4ab6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nova Nota',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Color(0xFF77717f), fontSize: 13),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (notes.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xffede5fa),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sticky_note_2_rounded,
                          color: Color(0xff6c4ab6),
                          size: 45,
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text('Nenhuma nota ainda'),
                      const SizedBox(height: 8),
                      const Text('Crie sua primeira nota.'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];

                    return NoteCard(
                      note: note,
                      onTap: () => openEditNote(note),
                      onDelete: () => deleteNote(note),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
