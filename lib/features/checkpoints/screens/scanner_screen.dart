import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/checkpoint_provider.dart';
import '../../../core/services/qr_scanner_service.dart';
import '../../../core/services/nfc_scanner_service.dart';
import '../widgets/qr_scanner_widget.dart';
import '../widgets/nfc_scanner_widget.dart';

/// Checkpoint scanner screen for QR/NFC scanning
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final QRScannerService _qrService = QRScannerService.instance;
  final NFCScannerService _nfcService = NFCScannerService.instance;
  
  bool _isQRScanning = false;
  bool _isNFCScanning = false;
  bool _hasLocationPermission = false;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _qrService.dispose();
    _nfcService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _nfcService.initialize();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestResult = await Geolocator.requestPermission();
        _hasLocationPermission = requestResult == LocationPermission.whileInUse ||
                                requestResult == LocationPermission.always;
      } else {
        _hasLocationPermission = permission == LocationPermission.whileInUse ||
                                permission == LocationPermission.always;
      }

      if (_hasLocationPermission) {
        _currentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final isScanning = ref.watch(isScanningProvider);
    final scanError = ref.watch(scanErrorProvider);
    final scanSuccess = ref.watch(scanSuccessDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkpoint Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan Checkpoint',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Position the QR code or NFC tag within the scanning area to record your checkpoint visit.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Scanner area or result
              Expanded(
                child: scanSuccess != null 
                  ? _buildScanResult(scanSuccess) 
                  : _buildScannerView(isScanning),
              ),
              
              const SizedBox(height: 16),
              
              // Error display
              if (scanError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          scanError,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Action buttons
              if (scanSuccess == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isScanning ? null : _startQRScan,
                        icon: const Icon(Icons.qr_code),
                        label: const Text('QR Code'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isScanning ? null : _startNFCScan,
                        icon: const Icon(Icons.nfc),
                        label: const Text('NFC Tag'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Manual entry option
                TextButton.icon(
                  onPressed: isScanning ? null : _showManualEntry,
                  icon: const Icon(Icons.edit),
                  label: const Text('Manual Entry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerView(bool isScanning) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: isScanning
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isScanning) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Scanning...'),
            const SizedBox(height: 8),
            Text(
              _isQRScanning ? 'Looking for QR code...' : 
              _isNFCScanning ? 'Waiting for NFC tag...' : 'Verifying...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ] else ...[
            Icon(
              Icons.center_focus_strong,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Ready to scan',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose QR Code or NFC below',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanResult(ScanSuccess scanSuccess) {
    final checkpoint = scanSuccess.checkpoint;
    final visit = scanSuccess.visitResponse.visit;
    
    return Column(
      children: [
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green,
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Checkpoint Scanned!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Scanned data
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Checkpoint', checkpoint.name),
                const SizedBox(height: 8),
                if (checkpoint.locationName != null)
                  _buildInfoRow('Location', checkpoint.locationName!),
                if (checkpoint.locationName != null)
                  const SizedBox(height: 8),
                _buildInfoRow('Code', checkpoint.code),
                const SizedBox(height: 8),
                _buildInfoRow('Method', visit?.scanMethod.toUpperCase() ?? 'UNKNOWN'),
                const SizedBox(height: 8),
                _buildInfoRow('Time', DateTime.now().toString().substring(0, 19)),
                const SizedBox(height: 8),
                _buildInfoRow('Status', 'Verified ✓'),
              ],
            ),
          ),
        ),
        
        const Spacer(),
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: _scanAnother,
                child: const Text('Scan Another'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  void _startQRScan() async {
    // Check camera permission first
    final hasPermission = await _qrService.checkCameraPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission required for QR scanning'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isQRScanning = true;
    });

    // Reset any previous scan state
    ref.read(scanProvider.notifier).resetScan();

    try {
      // Show QR scanner widget
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const QRScannerWidget(),
        ),
      );

      if (result != null && mounted) {
        // Process the scanned QR code
        await ref.read(scanProvider.notifier).scanQRCode(
          qrCode: result,
          latitude: _currentLocation?.latitude,
          longitude: _currentLocation?.longitude,
          accuracy: _currentLocation?.accuracy,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isQRScanning = false;
        });
      }
    }
  }

  void _startNFCScan() async {
    if (!_nfcService.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC is not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isNFCScanning = true;
    });

    // Reset any previous scan state
    ref.read(scanProvider.notifier).resetScan();

    try {
      // Show NFC scanner widget
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const NFCScannerWidget(),
        ),
      );

      if (result != null && mounted) {
        // Process the scanned NFC tag
        await ref.read(scanProvider.notifier).scanNFCTag(
          nfcTag: result,
          latitude: _currentLocation?.latitude,
          longitude: _currentLocation?.longitude,
          accuracy: _currentLocation?.accuracy,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFC scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNFCScanning = false;
        });
      }
    }
  }

  void _showManualEntry() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Checkpoint Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter checkpoint ID manually if scanning is not available:',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Checkpoint ID',
                hintText: 'e.g. CP_001',
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a checkpoint ID'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.of(context).pop();
              
              // Process manual entry
              await ref.read(scanProvider.notifier).manualEntry(
                checkpointCode: code,
                latitude: _currentLocation?.latitude,
                longitude: _currentLocation?.longitude,
                accuracy: _currentLocation?.accuracy,
                notes: 'Manual entry',
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _scanAnother() {
    ref.read(scanProvider.notifier).resetScan();
  }
}