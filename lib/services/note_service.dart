import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/note.dart';

class NoteService {
  final DatabaseHelper database = DatabaseHelper.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get notesCollection =>
      firestore.collection('notes');

  // Diagnosticar a conexão com o Firebase.
  Future<void> diagnosticarFirebase() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    debugPrint('========== DIAGNÓSTICO FIREBASE ==========');
    debugPrint('PROJETO FIRESTORE: ${firestore.app.options.projectId}');
    debugPrint('PROJETO AUTH: ${auth.app.options.projectId}');
    debugPrint('USUÁRIO: ${user?.uid}');
    debugPrint('EMAIL: ${user?.email}');

    if (user != null) {
      final token = await user.getIdTokenResult(true);

      debugPrint('AUDIÊNCIA DO TOKEN: ${token.claims?['aud']}');
      debugPrint('EMISSOR DO TOKEN: ${token.claims?['iss']}');
    }

    debugPrint('==========================================');
  }

  // Salvar nota no SQLite e Firestore.
  Future<void> saveNote(Note note) async {
    await diagnosticarFirebase();

    debugPrint('1 - Iniciando salvamento');

    if (note.cloudId != null) {
      if (note.id != null) {
        await database.updateNote(note);
      }

      debugPrint('2 - Atualizando Firestore');

      await notesCollection.doc(note.cloudId).update(note.toFirestore());

      debugPrint('3 - Atualização concluída');
    } else {
      debugPrint('2 - Criando documento no Firestore');

      final document = await notesCollection.add(note.toFirestore());

      debugPrint('3 - Documento criado: ${document.id}');

      await database.insertNote(
        Note(
          uid: note.uid,
          title: note.title,
          content: note.content,
          date: note.date,
          cloudId: document.id,
        ),
      );

      debugPrint('4 - Salvamento concluído');
    }
  }

  // Sincronizar notas locais e notas da nuvem.
  Future<void> syncNotes(String uid) async {
    final localNotes = await database.getNotes(uid);

    for (final note in localNotes) {
      if (note.cloudId == null) {
        final document = await notesCollection.add(note.toFirestore());

        if (note.id != null) {
          await database.updateCloudId(note.id!, document.id);
        }
      }
    }

    final snapshot = await notesCollection.where('uid', isEqualTo: uid).get();

    for (final document in snapshot.docs) {
      final note = Note.fromFirestore(document.data(), document.id);

      await database.saveCloudNote(note);
    }
  }

  // Buscar notas locais.
  Future<List<Note>> getNotes(String uid) async {
    return database.getNotes(uid);
  }

  // Excluir nota do SQLite e Firestore.
  Future<void> deleteNote(Note note) async {
    if (note.cloudId != null) {
      await notesCollection.doc(note.cloudId).delete();
    }

    if (note.id != null) {
      await database.deleteNote(note.id!);
    }
  }
}
