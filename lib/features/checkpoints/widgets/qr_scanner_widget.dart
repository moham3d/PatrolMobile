// ...existing code...
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR Code scanner widget
class QRScannerWidget extends StatefulWidget {
  const QRScannerWidget({super.key});

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  MobileScannerController controller = MobileScannerController();
  String? scannedCode;
  bool isFlashOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner View
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null &&
                    barcode.rawValue!.isNotEmpty &&
                    scannedCode == null) {
                  setState(() {
                    scannedCode = barcode.rawValue;
                  });
                  _provideFeedback();
                  Navigator.of(context).pop(barcode.rawValue);
                  break;
                }
              }
            },
          ),
          // Instructions overlay
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Position the QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The scan will happen automatically',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Cancel button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  void _flipCamera() async {
    await controller.switchCamera();
  }

  void _provideFeedback() {
    // You can add haptic feedback here if needed
    // HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
