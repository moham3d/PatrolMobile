import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
// ...existing code...

/// NFC Tag scanning service
class NFCScannerService {
  static final NFCScannerService instance = NFCScannerService._internal();
  NFCScannerService._internal();

  final StreamController<String> _resultController =
      StreamController<String>.broadcast();
  bool _isScanning = false;
  bool _isAvailable = false;

  /// Stream of scanned NFC tags
  Stream<String> get scanResults => _resultController.stream;

  /// Check if NFC is available
  bool get isAvailable => _isAvailable;

  /// Check if currently scanning
  bool get isScanning => _isScanning;

  /// Initialize NFC scanner
  Future<bool> initialize() async {
    try {
      _isAvailable = await NfcManager.instance.isAvailable();
      return _isAvailable;
    } catch (e) {
      debugPrint('Error initializing NFC: $e');
      _isAvailable = false;
      return false;
    }
  }

  /// Start NFC scanning
  Future<void> startScanning({Duration? timeout}) async {
    if (!_isAvailable) {
      throw Exception('NFC is not available on this device');
    }

    if (_isScanning) {
      await stopScanning();
    }

    _isScanning = true;

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          final result = await _processNFCTag(tag);
          if (result != null) {
            _resultController.add(result);
          }
        },
      );

      // Set timeout if specified
      if (timeout != null) {
        Timer(timeout, () {
          if (_isScanning) {
            stopScanning();
          }
        });
      }
    } catch (e) {
      _isScanning = false;
      debugPrint('Error starting NFC scan: $e');
      rethrow;
    }
  }

  /// Stop NFC scanning
  Future<void> stopScanning() async {
    if (_isScanning) {
      try {
        await NfcManager.instance.stopSession();
      } catch (e) {
        debugPrint('Error stopping NFC session: $e');
      } finally {
        _isScanning = false;
      }
    }
  }

  /// Process discovered NFC tag
  Future<String?> _processNFCTag(NfcTag tag) async {
    try {
      final tagMap = tag as Map<String, dynamic>;
      String? tagData;
      // NDEF (NFC Data Exchange Format)
      if (tagMap.containsKey('ndef')) {
        final ndef = tagMap['ndef'] as Map<String, dynamic>?;
        final cachedMessage = ndef?['cachedMessage'] as Map<String, dynamic>?;
        final records = cachedMessage?['records'] as List<dynamic>?;
        if (records != null && records.isNotEmpty) {
          tagData = _extractTextFromNdefRecordMap(records.first);
        }
      }
      // If no NDEF, try NfcA (ISO 14443 Type A)
      if (tagData == null && tagMap.containsKey('nfca')) {
        final identifier = tagMap['nfca']?['identifier'];
        if (identifier is Uint8List) {
          tagData = _bytesToHex(identifier);
        }
      }
      // If still no data, try NfcB (ISO 14443 Type B)
      if (tagData == null && tagMap.containsKey('nfcb')) {
        final identifier = tagMap['nfcb']?['identifier'];
        if (identifier is Uint8List) {
          tagData = _bytesToHex(identifier);
        }
      }
      // If still no data, try NfcF (JIS 6319-4)
      if (tagData == null && tagMap.containsKey('nfcf')) {
        final identifier = tagMap['nfcf']?['identifier'];
        if (identifier is Uint8List) {
          tagData = _bytesToHex(identifier);
        }
      }
      // If still no data, try NfcV (ISO 15693)
      if (tagData == null && tagMap.containsKey('nfcv')) {
        final identifier = tagMap['nfcv']?['identifier'];
        if (identifier is Uint8List) {
          tagData = _bytesToHex(identifier);
        }
      }
      if (tagData != null && tagData.isNotEmpty) {
        debugPrint('NFC Tag detected: $tagData');
        return tagData;
      }
      return null;
    } catch (e) {
      debugPrint('Error processing NFC tag: $e');
      return null;
    }
  }

  /// Extract text from NDEF record
  String? _extractTextFromNdefRecordMap(dynamic record) {
    try {
      // record is a Map<String, dynamic> in nfc_manager v4.x
      if (record is Map<String, dynamic>) {
        final typeNameFormat = record['typeNameFormat'];
        final type = record['type'];
        final payload = record['payload'];
        if (typeNameFormat == 1 &&
            type is Uint8List &&
            type.isNotEmpty &&
            payload is Uint8List &&
            payload.isNotEmpty) {
          // 1 == nfcWellknown
          final langCodeLength = payload[0] & 0x3F;
          final textBytes = payload.sublist(1 + langCodeLength);
          return String.fromCharCodes(textBytes);
        }
        // If not a text record, return hex representation
        if (payload is Uint8List) {
          return _bytesToHex(payload);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting text from NDEF record: $e');
      if (record is Map<String, dynamic> && record['payload'] is Uint8List) {
        return _bytesToHex(record['payload']);
      }
      return null;
    }
  }

  /// Convert bytes to hex string
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Validate NFC tag format
  bool isValidCheckpointNFC(String nfcData) {
    if (nfcData.isEmpty) return false;

    // Check for common checkpoint NFC patterns
    final patterns = [
      RegExp(r'^NFC_\w+$'), // NFC_001, NFC_MAIN, etc.
      RegExp(r'^CHECKPOINT_\w+$'), // CHECKPOINT_001, etc.
      RegExp(r'^[A-F0-9]{8,}$'), // Hex patterns (at least 8 characters)
      RegExp(r'^[A-Z0-9]{6,}$'), // Simple alphanumeric codes
    ];

    return patterns.any((pattern) => pattern.hasMatch(nfcData.toUpperCase()));
  }

  /// Process scanned NFC tag
  Map<String, dynamic> processNFCTag(String nfcData) {
    final result = <String, dynamic>{
      'code': nfcData,
      'timestamp': DateTime.now().toIso8601String(),
      'isValid': isValidCheckpointNFC(nfcData),
      'type': 'nfc',
    };

    // Add additional metadata
    result['length'] = nfcData.length;
    result['isHex'] = RegExp(r'^[A-F0-9]+$').hasMatch(nfcData.toUpperCase());

    return result;
  }

  /// Dispose NFC scanner
  void dispose() {
    stopScanning();
  }
}

/// NFC scanning state
enum NFCScanState { idle, scanning, tagDetected, error }

/// NFC scan result
class NFCScanResult {
  final String tagData;
  final DateTime timestamp;
  final bool isValid;
  final Map<String, dynamic> metadata;

  const NFCScanResult({
    required this.tagData,
    required this.timestamp,
    required this.isValid,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'NFCScanResult(tagData: $tagData, isValid: $isValid, timestamp: $timestamp)';
  }
}
