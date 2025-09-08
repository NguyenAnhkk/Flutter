import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class QRGeneratorView extends StatefulWidget {
  const QRGeneratorView({super.key});

  @override
  State<QRGeneratorView> createState() => _QRGeneratorViewState();
}

class _QRGeneratorViewState extends State<QRGeneratorView> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  String _qrData = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _generateQR() {
    setState(() {
      _qrData = _textController.text.trim();
    });
  }

  void _shareQR() {
    if (_qrData.isNotEmpty) {
      Share.share('QR Code Data: $_qrData');
    }
  }

  Future<void> _saveQRImage() async {
    if (_qrData.isEmpty) {
      _showSnackBar('Vui lòng nhập dữ liệu trước khi tải ảnh');
      return;
    }


    final shouldSave = await _showSaveConfirmationDialog();
    if (!shouldSave) return;

    try {

      final status = await _requestStoragePermission();
      if (!status) {
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );


      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      Directory? downloadsDir;
      if (Platform.isAndroid) {

        try {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {

            downloadsDir = await getExternalStorageDirectory();
            if (downloadsDir != null) {
              downloadsDir = Directory('${downloadsDir.path}/Download');
              await downloadsDir.create(recursive: true);
            }
          }
        } catch (e) {

          downloadsDir = await getApplicationDocumentsDirectory();
        }
      } else {

        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        Navigator.pop(context);
        _showSnackBar('Không thể truy cập thư mục lưu trữ');
        return;
      }

      // Create filename with timestamp
      final String fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${downloadsDir.path}/$fileName';

      // Save the image
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      final String displayPath = Platform.isAndroid
          ? 'Thư mục Download'
          : 'Thư mục Documents của ứng dụng';
      _showSnackBar('Đã lưu ảnh QR Code thành công!\nVị trí: $displayPath\nTên file: $fileName');

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showSnackBar('Lỗi khi lưu ảnh: $e');
    }
  }

  Future<bool> _showSaveConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.download, color: Colors.blue),
              SizedBox(width: 8),
              Text('Lưu ảnh QR Code'),
            ],
          ),
          content: const Text(
            'Bạn có muốn lưu ảnh QR Code này vào thiết bị không?\n\n'
            'Ứng dụng sẽ cần quyền truy cập bộ nhớ để lưu ảnh.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu ảnh'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        var photosStatus = await Permission.photos.status;

        if (photosStatus.isGranted) {
          return true;
        }

        if (photosStatus.isDenied) {
          photosStatus = await Permission.photos.request();
          if (photosStatus.isGranted) {
            return true;
          }
        }

        if (photosStatus.isPermanentlyDenied) {
          final shouldOpenSettings = await _showPermissionDeniedDialog();
          if (shouldOpenSettings) {
            await openAppSettings();
          }
          return false;
        }
      }

      var storageStatus = await Permission.storage.status;

      if (storageStatus.isGranted) {
        return true;
      }

      if (storageStatus.isDenied) {
        storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }
      }

      if (storageStatus.isPermanentlyDenied) {
        final shouldOpenSettings = await _showPermissionDeniedDialog();
        if (shouldOpenSettings) {
          await openAppSettings();
        }
        return false;
      }

      _showSnackBar('Cần quyền truy cập bộ nhớ để lưu ảnh');
      return false;
    } catch (e) {
      _showSnackBar('Lỗi khi xin quyền: $e');
      return false;
    }
  }

  Future<bool> _showPermissionDeniedDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Quyền bị từ chối'),
            ],
          ),
          content: const Text(
            'Quyền truy cập bộ nhớ đã bị từ chối vĩnh viễn.\n\n'
            'Để lưu ảnh, bạn cần cấp quyền trong Cài đặt ứng dụng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mở Cài đặt'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_qrData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareQR,
              tooltip: 'Share QR Data',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhập văn bản để tạo QR Code:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập văn bản, URL, hoặc dữ liệu khác...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      maxLines: 1,
                      onChanged: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            _qrData = value.trim();
                          });
                        } else {
                          setState(() {
                            _qrData = '';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // QR Code display section
            Container(
              constraints: const BoxConstraints(
                minHeight: 400,
                maxHeight: 600,
              ),
              child: _qrData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có dữ liệu để tạo QR Code',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy nhập văn bản ở trên để tạo QR Code',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'QR Code của bạn:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            RepaintBoundary(
                              key: _qrKey,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: _qrData,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  errorStateBuilder: (context, error) {
                                    return const Center(
                                      child: Text(
                                        'Lỗi tạo QR Code',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _qrData,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _shareQR,
                                      icon: const Icon(Icons.share),
                                      label: const Text('Chia sẻ'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _saveQRImage,
                                      icon: const Icon(Icons.download),
                                      label: const Text('Tải ảnh'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _textController.clear();
                                        _qrData = '';
                                      });
                                    },
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Xóa tất cả'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20), // Extra space at bottom
          ],
        ),
      ),
    );
  }
}
