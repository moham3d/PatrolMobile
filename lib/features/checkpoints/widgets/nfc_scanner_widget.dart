import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/nfc_scanner_service.dart';

/// NFC scanner widget
class NFCScannerWidget extends StatefulWidget {
  const NFCScannerWidget({super.key});

  @override
  State<NFCScannerWidget> createState() => _NFCScannerWidgetState();
}

class _NFCScannerWidgetState extends State<NFCScannerWidget>
    with TickerProviderStateMixin {
  final NFCScannerService _nfcService = NFCScannerService.instance;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  StreamSubscription<String>? _scanSubscription;
  bool _isScanning = false;
  String? _status = 'Tap to start scanning';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeNFC();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeNFC() async {
    final isAvailable = await _nfcService.initialize();
    if (!isAvailable) {
      setState(() {
        _status = 'NFC not available on this device';
      });
    } else {
      _startScanning();
    }
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _status = 'Hold your device near an NFC tag';
    });

    _animationController.repeat(reverse: true);

    try {
      // Listen for scan results
      _scanSubscription = _nfcService.scanResults.listen(
        (tagData) {
          _onTagDetected(tagData);
        },
        onError: (error) {
          _onScanError(error.toString());
        },
      );

      // Start NFC scanning with timeout
      await _nfcService.startScanning(timeout: const Duration(minutes: 1));
    } catch (e) {
      _onScanError(e.toString());
    }
  }

  void _onTagDetected(String tagData) {
    setState(() {
      _status = 'NFC tag detected!';
      _isScanning = false;
    });

    _animationController.stop();
    
    // Provide feedback
    _provideFeedback();
    
    // Return the scanned tag data
    Navigator.of(context).pop(tagData);
  }

  void _onScanError(String error) {
    setState(() {
      _status = 'Error: $error';
      _isScanning = false;
    });
    
    _animationController.stop();
    
    // Show error and close after delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _provideFeedback() {
    // You can add haptic feedback here if needed
    // HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan NFC Tag'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // NFC Icon with animation
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isScanning ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _isScanning 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isScanning 
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.nfc,
                      size: 60,
                      color: _isScanning 
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Status text
            Text(
              _status!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: _isScanning 
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            if (_isScanning) ...[
              const Text(
                'Position your device close to the NFC tag.\nThe scan will happen automatically.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Scanning indicator
              const CircularProgressIndicator(),
            ] else if (!_nfcService.isAvailable) ...[
              const Text(
                'NFC is not available on this device or is disabled.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Text(
                'Tap the button below to start scanning for NFC tags.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Start button
              ElevatedButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.nfc),
                label: const Text('Start NFC Scan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
            
            const Spacer(),
            
            // Cancel button
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            
            const SizedBox(height: 32),
            
            // Help text
            const Text(
              'If you\'re having trouble, make sure NFC is enabled in your device settings.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}