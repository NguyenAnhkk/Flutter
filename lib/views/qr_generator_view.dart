import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QRGeneratorView extends StatefulWidget {
  const QRGeneratorView({super.key});

  @override
  State<QRGeneratorView> createState() => _QRGeneratorViewState();
}

class _QRGeneratorViewState extends State<QRGeneratorView> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _qrKey = GlobalKey();
  String _qrData = '';
  bool _isScanning = false;
  MobileScannerController? _scannerController;
  bool _cameraPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermissionGranted = status.isGranted;
    });

    if (!status.isGranted) {
      _showCameraPermissionDeniedDialog();
    }
  }

  void _showCameraPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.videocam_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Quyền truy cập camera bị từ chối'),
            ],
          ),
          content: const Text(
            'Ứng dụng cần quyền truy cập camera để quét QR code.\n\n'
                'Vui lòng cấp quyền camera trong cài đặt thiết bị.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Mở cài đặt'),
            ),
          ],
        );
      },
    );
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

      final String fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${downloadsDir.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      Navigator.pop(context);

      final String displayPath = Platform.isAndroid
          ? 'Thư mục Download'
          : 'Thư mục Documents của ứng dụng';
      _showSnackBar('Đã lưu ảnh QR Code thành công!\nVị trí: $displayPath\nTên file: $fileName');

    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showSnackBar('Lỗi khi lưu ảnh: $e');
    }
  }

  Future<void> _startScanning() async {
    if (!_cameraPermissionGranted) {
      await _requestCameraPermission();
      if (!_cameraPermissionGranted) {
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _scannerController = MobileScannerController();
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
      _scannerController?.dispose();
      _scannerController = null;
    });
  }

  bool _looksLikeUrl(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (uri.hasScheme) return true;
    return trimmed.startsWith('www.');
  }

  String? _extractUrlCandidate(String input) {
    final text = input.trim();
    final urlPattern = RegExp(
      r'((?:[a-zA-Z][\w+.-]*://)?(?:www\.)?[\w.-]+\.[a-zA-Z]{2,}(?:[/?#][^\s]*)?)',
      multiLine: true,
    );
    final match = urlPattern.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  String _normalizeUrl(String input) {
    final trimmed = input.trim();
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed);
    if (hasScheme) return trimmed;
    // Luôn thêm https nếu thiếu scheme để tăng khả năng mở liên kết
    if (trimmed.startsWith('www.')) return 'https://$trimmed';
    return 'https://$trimmed';
  }

  void _handleScannedBarcode(BarcodeCapture barcodes) {
    final barcode = barcodes.barcodes.first;
    if (barcode.rawValue == null) {
      _showSnackBar('Không thể đọc QR code');
      return;
    }

    final scannedData = barcode.rawValue!;
    setState(() {
      _qrData = scannedData;
      _textController.text = scannedData;
      _isScanning = false;
    });

    _scannerController?.dispose();
    _scannerController = null;

    _showScanResultDialog(scannedData);
  }

  Future<void> _showScanResultDialog(String scannedData) async {
    final candidate = _extractUrlCandidate(scannedData);
    final isUrl = candidate != null && _looksLikeUrl(candidate);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('QR Code Đã Quét'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scannedData,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (isUrl)
                  const Text(
                    'Đây là một liên kết. Bạn có muốn mở nó không?',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            if (isUrl)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _launchUrl(candidate!);
                },
                child: const Text('Mở Liên Kết'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final normalized = _normalizeUrl(url);
      final uri = Uri.parse(normalized);
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: thử mở bằng webview trong ứng dụng
        launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );
        if (!launched) {
          _showSnackBar('Không thể mở liên kết: $normalized');
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi khi mở liên kết: $e');
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
        title: Text(_isScanning ? 'Quét QR Code' : 'QR Code Generator'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_qrData.isNotEmpty && !_isScanning)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareQR,
              tooltip: 'Share QR Data',
            ),
          if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _startScanning,
              tooltip: 'Quét QR Code',
            ),
        ],
      ),
      body: _isScanning ? _buildScanner() : _buildGenerator(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _handleScannedBarcode,
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _stopScanning,
            backgroundColor: Colors.red,
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
        const Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ),
        if (!_cameraPermissionGranted)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.videocam_off,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cần quyền truy cập camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng cấp quyền camera để sử dụng tính năng quét QR',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _requestCameraPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cấp quyền camera'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenerator() {
    return SingleChildScrollView(
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateQR,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Tạo QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
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
                    'Chưa có dữliệu để tạo QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy nhập văn bản ở trên hoặc quét QR code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _startScanning,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Quét QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}