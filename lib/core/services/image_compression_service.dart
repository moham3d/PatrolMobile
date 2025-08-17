import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Utility service for image compression and optimization
class ImageCompressionService {
  static ImageCompressionService? _instance;
  static ImageCompressionService get instance => _instance ??= ImageCompressionService._internal();
  
  ImageCompressionService._internal();

  /// Compress image for incident reports and evidence
  Future<XFile?> compressImageForIncident(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      final Uint8List imageBytes = await file.readAsBytes();
      
      // For incidents, use medium quality to balance file size and detail
      return await _compressImage(
        imageFile,
        quality: 70,
        maxWidth: 1920,
        maxHeight: 1080,
        targetFileSizeKB: 500, // Target 500KB for incidents
      );
    } catch (e) {
      print('Error compressing image for incident: $e');
      return imageFile; // Return original if compression fails
    }
  }

  /// Compress image for profile or low-priority uploads
  Future<XFile?> compressImageForProfile(XFile imageFile) async {
    try {
      return await _compressImage(
        imageFile,
        quality: 60,
        maxWidth: 512,
        maxHeight: 512,
        targetFileSizeKB: 100, // Target 100KB for profiles
      );
    } catch (e) {
      print('Error compressing image for profile: $e');
      return imageFile;
    }
  }

  /// Compress image for emergency reports (higher quality for evidence)
  Future<XFile?> compressImageForEmergency(XFile imageFile) async {
    try {
      return await _compressImage(
        imageFile,
        quality: 80,
        maxWidth: 2560,
        maxHeight: 1440,
        targetFileSizeKB: 800, // Larger for emergency evidence
      );
    } catch (e) {
      print('Error compressing image for emergency: $e');
      return imageFile;
    }
  }

  /// Core image compression logic
  Future<XFile?> _compressImage(
    XFile imageFile, {
    required int quality,
    required int maxWidth,
    required int maxHeight,
    required int targetFileSizeKB,
  }) async {
    try {
      final File originalFile = File(imageFile.path);
      final int originalSizeBytes = await originalFile.length();
      final int originalSizeKB = originalSizeBytes ~/ 1024;

      // If already smaller than target, return original
      if (originalSizeKB <= targetFileSizeKB) {
        return imageFile;
      }

      // For now, return original file since we need native compression library
      // In a real implementation, you would use a package like flutter_image_compress
      print('Image compression simulated: ${originalSizeKB}KB -> ${targetFileSizeKB}KB target');
      
      return imageFile;
    } catch (e) {
      print('Error in core image compression: $e');
      return imageFile;
    }
  }

  /// Get estimated file size after compression
  Future<int> getEstimatedCompressedSize(XFile imageFile, String compressionType) async {
    try {
      final File file = File(imageFile.path);
      final int originalSize = await file.length();
      
      // Estimated compression ratios based on type
      double compressionRatio;
      switch (compressionType) {
        case 'emergency':
          compressionRatio = 0.6; // 60% of original
          break;
        case 'incident':
          compressionRatio = 0.4; // 40% of original
          break;
        case 'profile':
          compressionRatio = 0.2; // 20% of original
          break;
        default:
          compressionRatio = 0.5;
      }
      
      return (originalSize * compressionRatio).round();
    } catch (e) {
      print('Error estimating compressed size: $e');
      return 0;
    }
  }

  /// Check if image needs compression based on battery level
  bool shouldCompressForBattery(int batteryLevel) {
    if (batteryLevel <= 20) {
      return true; // Always compress when battery is low
    } else if (batteryLevel <= 50) {
      return true; // Compress when battery is medium
    }
    return false; // Optional compression when battery is good
  }

  /// Get recommended compression settings based on battery and connectivity
  Map<String, dynamic> getRecommendedSettings({
    required int batteryLevel,
    required bool isOnWifi,
    required bool isEmergency,
  }) {
    if (isEmergency) {
      // Emergency: prioritize quality over compression
      return {
        'quality': batteryLevel > 30 ? 80 : 70,
        'maxWidth': 2560,
        'maxHeight': 1440,
        'targetSizeKB': batteryLevel > 30 ? 800 : 600,
      };
    } else if (batteryLevel <= 20) {
      // Low battery: aggressive compression
      return {
        'quality': 50,
        'maxWidth': 1280,
        'maxHeight': 720,
        'targetSizeKB': 200,
      };
    } else if (!isOnWifi) {
      // Mobile data: moderate compression
      return {
        'quality': 60,
        'maxWidth': 1920,
        'maxHeight': 1080,
        'targetSizeKB': 400,
      };
    } else {
      // WiFi + good battery: minimal compression
      return {
        'quality': 75,
        'maxWidth': 2560,
        'maxHeight': 1440,
        'targetSizeKB': 700,
      };
    }
  }

  /// Batch compress multiple images
  Future<List<XFile>> compressImagesBatch(
    List<XFile> imageFiles,
    String compressionType,
  ) async {
    final List<XFile> compressedImages = [];
    
    for (final imageFile in imageFiles) {
      XFile? compressed;
      
      switch (compressionType) {
        case 'emergency':
          compressed = await compressImageForEmergency(imageFile);
          break;
        case 'incident':
          compressed = await compressImageForIncident(imageFile);
          break;
        case 'profile':
          compressed = await compressImageForProfile(imageFile);
          break;
        default:
          compressed = await compressImageForIncident(imageFile);
      }
      
      if (compressed != null) {
        compressedImages.add(compressed);
      }
    }
    
    return compressedImages;
  }
}