import 'package:flutter/foundation.dart';
import 'package:projects/services/cloud/cloud_storage_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
@immutable
class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String text;
  final String title;
  final List<String>? imagePaths;
  final DateTime? reminderAt;
  final String? reminderTitle;

  const CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    required this.title,
    this.imagePaths,
    this.reminderAt,
    this.reminderTitle,
  });

  CloudNote.fromSnapShot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
    : documentId = snapshot.id,
      ownerUserId = snapshot.data()[ownerUserIdFieldName],
      text = snapshot.data()[textFieldName] as String,
      title = (snapshot.data()[titleFieldName] ?? '') as String,
      imagePaths = (snapshot.data()[imagePathsFieldName] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reminderAt = (snapshot.data()[reminderAtFieldName] is Timestamp)
          ? (snapshot.data()[reminderAtFieldName] as Timestamp).toDate()
          : null,
      reminderTitle = snapshot.data()[reminderTitleFieldName] as String?;
}
