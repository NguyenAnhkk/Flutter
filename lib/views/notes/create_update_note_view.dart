import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/services/auth/auth_service.dart';
import 'package:projects/services/cloud/firebase_cloud_storage.dart';
import 'package:projects/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:projects/utilities/generics/get_argument.dart';
import 'package:projects/services/cloud/cloud_note.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateUpdateNoteView> {
  CloudNote? _note;
  late final FirebaseCloudStorage _noteServices;
  late final TextEditingController _textController;
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _imagePaths = [];
  List<File> _localImages = [];
  bool _isUploading = false;
  Color _backgroundColor = Colors.white;

  @override
  void initState() {
    _noteServices = FirebaseCloudStorage();
    _textController = TextEditingController();
    super.initState();
  }

  void _textControlerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textController.text;
    await _noteServices.updateNote(
      documentId: note.documentId,
      text: text,
      imagePaths: _imagePaths,
      backgroundColor: _backgroundColor.value,
    );
  }

  void _setupTextControlerListener() {
    _textController.removeListener(_textControlerListener);
    _textController.addListener(_textControlerListener);
  }

  Future<CloudNote> createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<CloudNote>();
    if (widgetNote != null) {
      _note = widgetNote;
      _textController.text = widgetNote.text;
      _imagePaths = widgetNote.imagePaths ?? [];
      return widgetNote;
    }
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final userId = currentUser.id;
    final newNote = await _noteServices.createNewNote(ownerUserId: userId);
    _note = newNote;
    return newNote;
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null && _imagePaths.isEmpty) {
      _noteServices.deleteNote(documentId: note.documentId);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && (text.isNotEmpty || _imagePaths.isNotEmpty)) {
      await _noteServices.updateNote(
        documentId: note.documentId,
        text: text,
        imagePaths: _imagePaths,
      );
    }
  }

  void _showImagePreview(BuildContext context, int index, bool isSavedImage) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header với nút đóng và xoá
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        if (isSavedImage) {
                          await _removeImage(index);
                        } else {
                          setState(() {
                            _localImages.removeAt(index);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PhotoView(
                  imageProvider: isSavedImage
                      ? FileImage(File(_imagePaths[index]))
                      : FileImage(_localImages[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  backgroundDecoration: BoxDecoration(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Phương thức xem gallery toàn bộ ảnh
  void _showImageGallery(BuildContext context, int initialIndex) {
    final List<ImageProvider> imageProviders = [
      ..._imagePaths.map((path) => FileImage(File(path))),
      ..._localImages.map((file) => FileImage(file)),
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              PhotoViewGallery.builder(
                itemCount: imageProviders.length,
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: imageProviders[index],
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                  );
                },
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: BoxDecoration(color: Colors.black),
                pageController: PageController(initialPage: initialIndex),
                onPageChanged: (index) {},
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 30),
                  onPressed: () async {
                    final currentIndex = initialIndex;
                    Navigator.of(context).pop();

                    if (currentIndex < _imagePaths.length) {
                      await _removeImage(currentIndex);
                    } else {
                      final localIndex = currentIndex - _imagePaths.length;
                      setState(() {
                        _localImages.removeAt(localIndex);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        print('Image picked: ${pickedFile.path}');
        setState(() {
          _isUploading = true;
        });

        final file = File(pickedFile.path);
        // Add local image temporarily for immediate display
        setState(() {
          _localImages.add(file);
        });

        // Check if note exists before upload
        if (_note == null) {
          print('Error: Note is null, cannot upload image');
          setState(() {
            _localImages.remove(file);
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note not ready, please try again')),
          );
          return;
        }

        // Save image locally and get path
        final imagePath = await _noteServices.saveNoteImage(
          file: file,
          noteId: _note!.documentId,
        );

        print('Save result: $imagePath');

        if (imagePath != null) {
          setState(() {
            _imagePaths.add(imagePath);
            _localImages.remove(
              file,
            ); // Remove local image after successful save
            _isUploading = false;
          });
          // Auto-save note with new image
          await _noteServices.updateNote(
            documentId: _note!.documentId,
            text: _textController.text,
            imagePaths: _imagePaths,
          );
          print('Note updated with image path: $imagePath');
        } else {
          setState(() {
            _localImages.remove(file); // Remove local image if save failed
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save image locally')),
          );
        }
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _removeImage(int index) async {
    final removedPath = _imagePaths[index];

    // Hiển thị dialog xác nhận
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xoá ảnh'),
        content: Text('Bạn có chắc muốn xoá ảnh này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      setState(() {
        _imagePaths.removeAt(index);
      });

      // Delete image from local storage
      await _noteServices.deleteNoteImage(removedPath);

      // Update note without the removed image
      await _noteServices.updateNote(
        documentId: _note!.documentId,
        text: _textController.text,
        imagePaths: _imagePaths,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xoá ảnh')));
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
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          IconButton(
            onPressed: () async {
              final text = _textController.text;
              if (_note == null || (text.isEmpty && _imagePaths.isEmpty)) {
                await showCannotShareEmptyNoteDialog(context);
              } else {
                // Share both text and image paths
                String shareText = text;
                if (_imagePaths.isNotEmpty) {
                  shareText += '\n\nImages: ${_imagePaths.join('\n')}';
                }
                Share.share(shareText);
              }
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: FutureBuilder<CloudNote>(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControlerListener();
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('Unable to create note.'));
              }
              _note = snapshot.data!;
              _setupTextControlerListener();

              return Column(
                children: [
                  // Image gallery - show both saved and local images
                  // Image gallery - show both saved and local images
                  if (_imagePaths.isNotEmpty || _localImages.isNotEmpty)
                    Container(
                      height: 150, // Tăng chiều cao
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length + _localImages.length,
                        itemBuilder: (context, index) {
                          // Show saved images first
                          if (index < _imagePaths.length) {
                            return GestureDetector(
                              onTap: () => _showImageGallery(context, index),
                              child: Container(
                                width: 140,
                                // Rộng hơn
                                height: 140,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Ảnh chính
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_imagePaths[index]),
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    // Nút xoá nhỏ
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            final localIndex = index - _imagePaths.length;
                            return GestureDetector(
                              onTap: () => _showImageGallery(context, index),
                              child: Container(
                                width: 140,
                                height: 140,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Ảnh chính
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _localImages[localIndex],
                                        width: 140,
                                        height: 140,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Indicator đang upload
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Đang lưu...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Nút xoá
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _localImages.removeAt(localIndex);
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),

                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Start typing your note...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  // Uploading indicator
                  if (_isUploading) const LinearProgressIndicator(),
                ],
              );

            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),

      // Add image button
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'camera_btn',
            onPressed: () => _pickImage(ImageSource.camera),
            mini: true,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'gallery_btn',
            onPressed: () => _pickImage(ImageSource.gallery),
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }
}
