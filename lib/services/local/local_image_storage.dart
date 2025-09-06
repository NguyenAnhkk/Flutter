import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalImageStorage {
  static final LocalImageStorage _instance = LocalImageStorage._internal();
  factory LocalImageStorage() => _instance;
  LocalImageStorage._internal();

  Future<String> get _imagesDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'note_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir.path;
  }

  Future<String?> saveImage(File imageFile, String noteId) async {
    try {
      final imagesDir = await _imagesDirectory;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(imagesDir, '${noteId}_$fileName');
      
      final savedFile = await imageFile.copy(filePath);
      print('Image saved locally: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }

  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('Image deleted: $imagePath');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<bool> imageExists(String imagePath) async {
    return await File(imagePath).exists();
  }

  Future<List<String>> getImagesForNote(String noteId) async {
    try {
      final imagesDir = await _imagesDirectory;
      final dir = Directory(imagesDir);
      final files = await dir.list().toList();
      
      return files
          .where((file) => file.path.contains('${noteId}_'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Error getting images for note: $e');
      return [];
    }
  }
}
