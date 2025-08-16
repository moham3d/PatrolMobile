import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Checkpoint scanner screen for QR/NFC scanning
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanning = false;
  bool _hasScanned = false;
  String? _scannedData;

  @override
  Widget build(BuildContext context) {
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
              
              // Scanner area
              Expanded(
                child: _hasScanned ? _buildScanResult() : _buildScannerView(),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _startQRScan,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('QR Code'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _startNFCScan,
                      icon: const Icon(Icons.nfc),
                      label: const Text('NFC Tag'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Manual entry option
              TextButton.icon(
                onPressed: _showManualEntry,
                icon: const Icon(Icons.edit),
                label: const Text('Manual Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: _isScanning
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isScanning) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Scanning...'),
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

  Widget _buildScanResult() {
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
                _buildInfoRow('Checkpoint', 'Main Entrance'),
                const SizedBox(height: 8),
                _buildInfoRow('Location', 'Building A - East Wing'),
                const SizedBox(height: 8),
                _buildInfoRow('Time', DateTime.now().toString().substring(0, 19)),
                const SizedBox(height: 8),
                _buildInfoRow('Status', 'Verified'),
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
    setState(() {
      _isScanning = true;
    });

    try {
      // TODO: Implement actual QR code scanning
      // This should use qr_code_scanner package
      await Future.delayed(const Duration(seconds: 2)); // Simulate scan
      
      if (mounted) {
        setState(() {
          _isScanning = false;
          _hasScanned = true;
          _scannedData = 'QR_CHECKPOINT_001';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code scanned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startNFCScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // TODO: Implement actual NFC scanning
      // This should use nfc_manager package
      await Future.delayed(const Duration(seconds: 2)); // Simulate scan
      
      if (mounted) {
        setState(() {
          _isScanning = false;
          _hasScanned = true;
          _scannedData = 'NFC_CHECKPOINT_001';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NFC tag scanned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFC scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showManualEntry() {
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
              decoration: const InputDecoration(
                labelText: 'Checkpoint ID',
                hintText: 'e.g. CP_001',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Process manual entry
              setState(() {
                _hasScanned = true;
                _scannedData = 'MANUAL_ENTRY';
              });
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _scanAnother() {
    setState(() {
      _hasScanned = false;
      _scannedData = null;
      _isScanning = false;
    });
  }
}