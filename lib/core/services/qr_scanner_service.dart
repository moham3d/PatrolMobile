import 'dart:async';
// ...existing code...
import 'package:flutter/foundation.dart';
// ...existing code...
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// QR Code scanning service
class QRScannerService {
  static final QRScannerService instance = QRScannerService._internal();
  QRScannerService._internal();

  MobileScannerController? _controller;
  StreamSubscription<BarcodeCapture>? _scanSubscription;
  final StreamController<String> _resultController =
      StreamController<String>.broadcast();

  /// Stream of scanned QR codes
  Stream<String> get scanResults => _resultController.stream;

  /// Check camera permission
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Initialize QR scanner
  Future<void> initialize(MobileScannerController controller) async {
    _controller = controller;
    // Listen to scan results
    _scanSubscription = _controller!.barcodes.listen((BarcodeCapture capture) {
      for (final barcode in capture.barcodes) {
        if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
          _resultController.add(barcode.rawValue!);
        }
      }
    });
  }

  /// Start scanning
  Future<void> startScanning() async {
    try {
      await _controller?.start();
    } catch (e) {
      debugPrint('Error starting QR scanner: $e');
      rethrow;
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    try {
      await _controller?.stop();
    } catch (e) {
      debugPrint('Error stopping QR scanner: $e');
    }
  }

  /// Toggle flash
  Future<void> toggleFlash() async {
    try {
      await _controller?.toggleTorch();
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  /// Flip camera
  Future<void> flipCamera() async {
    try {
      await _controller?.switchCamera();
    } catch (e) {
      debugPrint('Error flipping camera: $e');
    }
  }

  /// Get flash status
  /// Torch state should be tracked via MobileScannerController.torchState stream in the UI.
  Future<bool?> getFlashStatus() async {
    // Not supported directly in mobile_scanner; track via stream in UI.
    return null;
  }

  /// Dispose scanner
  void dispose() {
    _scanSubscription?.cancel();
    _controller?.dispose();
    _controller = null;
  }

  /// Validate QR code format
  bool isValidCheckpointQR(String qrCode) {
    // Basic validation - you can customize this based on your QR code format
    if (qrCode.isEmpty) return false;

    // Check for common checkpoint QR patterns
    final patterns = [
      RegExp(r'^CP_\w+$'), // CP_001, CP_MAIN, etc.
      RegExp(r'^CHECKPOINT_\w+$'), // CHECKPOINT_001, etc.
      RegExp(r'^[A-Z0-9]{6,}$'), // Simple alphanumeric codes
    ];

    return patterns.any((pattern) => pattern.hasMatch(qrCode));
  }

  /// Process scanned QR code
  Map<String, dynamic> processQRCode(String qrCode) {
    final result = <String, dynamic>{
      'code': qrCode,
      'timestamp': DateTime.now().toIso8601String(),
      'isValid': isValidCheckpointQR(qrCode),
    };

    // Extract additional information if the QR code contains structured data
    try {
      // If QR code contains JSON data
      if (qrCode.startsWith('{') && qrCode.endsWith('}')) {
        // Handle JSON QR codes (if your system uses them)
        result['isStructured'] = true;
        result['data'] = qrCode;
      } else {
        // Handle simple text QR codes
        result['isStructured'] = false;
        result['checkpointId'] = qrCode;
      }
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      result['error'] = e.toString();
    }

    return result;
  }
}

/// QR Scanner widget overlay data
class QRScannerOverlayData {
  final bool hasFlash;
  final bool isFlashOn;
  final bool isScanning;
  final String? lastScannedCode;
  final DateTime? lastScanTime;

  const QRScannerOverlayData({
    this.hasFlash = false,
    this.isFlashOn = false,
    this.isScanning = false,
    this.lastScannedCode,
    this.lastScanTime,
  });

  QRScannerOverlayData copyWith({
    bool? hasFlash,
    bool? isFlashOn,
    bool? isScanning,
    String? lastScannedCode,
    DateTime? lastScanTime,
  }) {
    return QRScannerOverlayData(
      hasFlash: hasFlash ?? this.hasFlash,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      isScanning: isScanning ?? this.isScanning,
      lastScannedCode: lastScannedCode ?? this.lastScannedCode,
      lastScanTime: lastScanTime ?? this.lastScanTime,
    );
  }
}
