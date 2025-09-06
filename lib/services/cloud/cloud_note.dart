import 'package:flutter/foundation.dart';
import 'package:projects/services/cloud/cloud_storage_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
@immutable
class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String text;
  final List<String>? imagePaths;
  final int? backgroundColor;

  const CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    this.imagePaths,
    this.backgroundColor,
  });

  CloudNote.fromSnapShot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
    : documentId = snapshot.id,
      ownerUserId = snapshot.data()[ownerUserIdFieldName],
      text = snapshot.data()[textFieldName] as String,
      imagePaths = (snapshot.data()[imagePathsFieldName] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      backgroundColor = snapshot.data()[backgroundColorFieldName] as int?;
}
