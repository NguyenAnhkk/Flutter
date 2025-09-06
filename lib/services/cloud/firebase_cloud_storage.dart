import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:projects/services/cloud/cloud_note.dart';
import 'package:projects/services/cloud/cloud_storage_constants.dart';
import 'package:projects/services/local/local_image_storage.dart';
import 'cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');

  Stream<Iterable<CloudNote>> allNotes({required String ownerUserId}) =>
      notes.snapshots().map(
        (event) => event.docs
            .map((doc) => CloudNote.fromSnapShot(doc))
            .where((note) => note.ownerUserId == ownerUserId),
      );

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<void> updateNote({
    required String documentId,
    required String text,
    List<String>? imagePaths,
  }) async {
    try {
      final Map<String, Object?> data = {textFieldName: text};
      if (imagePaths != null) {
        data[imagePathsFieldName] = imagePaths;
      }
      await notes.doc(documentId).update(data);
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<Iterable<CloudNote>> getNote({required String ownerUserId}) async {
    try {
      return await notes
          .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
          .get()
          .then(
            (value) => value.docs.map((doc) => CloudNote.fromSnapShot(doc))
        );
    } catch (e) {
      throw CouldNotGetAllNotesException();
    }
  }

  Future<CloudNote> createNewNote({required String ownerUserId}) async {
    final document = await notes.add({
      ownerUserIdFieldName: ownerUserId,
      textFieldName: '',
      imagePathsFieldName: <String>[],
    });
    final fetchedNote = await document.get();
    return CloudNote(
      documentId: fetchedNote.id,
      ownerUserId: ownerUserId,
      text: '',
      imagePaths: const [],
    );
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();

  FirebaseCloudStorage._sharedInstance();

  factory FirebaseCloudStorage() => _shared;

  Future<String?> saveNoteImage({
    required File file,
    required String noteId,
  }) async {
    try {
      final localStorage = LocalImageStorage();
      final imagePath = await localStorage.saveImage(file, noteId);
      print('Image saved locally: $imagePath');
      return imagePath;
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }

  Future<void> deleteNoteImage(String imagePath) async {
    try {
      final localStorage = LocalImageStorage();
      await localStorage.deleteImage(imagePath);
    } catch (e) {
      print('Error deleting local image: $e');
    }
  }

}
