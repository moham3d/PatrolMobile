import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/user.dart';
import '../../../core/models/incident.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/incident_service.dart';
import '../../../core/services/image_compression_service.dart';
import '../../../core/services/performance_monitoring_service.dart';
import '../../../core/exceptions/api_exception.dart';

/// Incident reporting screen for creating new incidents
class IncidentReportScreen extends ConsumerStatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  ConsumerState<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends ConsumerState<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedPriority;
  final List<XFile> _attachedMedia = [];
  Position? _currentLocation;
  bool _isSubmitting = false;
  
  // Incident categories based on user role
  final Map<String, List<String>> _roleBasedCategories = {
    'guard': [
      'Security Breach',
      'Suspicious Activity',
      'Property Damage',
      'Safety Hazard',
      'Medical Emergency',
      'Fire/Smoke',
      'Equipment Malfunction',
      'Other'
    ],
    'supervisor': [
      'Security Breach',
      'Suspicious Activity',
      'Property Damage',
      'Safety Hazard',
      'Medical Emergency',
      'Fire/Smoke',
      'Equipment Malfunction',
      'Staff Issue',
      'Client Complaint',
      'Policy Violation',
      'Training Need',
      'Other'
    ],
    'site_manager': [
      'Security Breach',
      'Suspicious Activity',
      'Property Damage',
      'Safety Hazard',
      'Medical Emergency',
      'Fire/Smoke',
      'Equipment Malfunction',
      'Staff Issue',
      'Client Complaint',
      'Policy Violation',
      'Training Need',
      'Budget/Cost Issue',
      'Regulatory Compliance',
      'Contract Issue',
      'Other'
    ],
  };
  
  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isSubmitting ? null : _submitIncident,
            icon: _isSubmitting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
      body: authState is Authenticated
          ? _buildIncidentForm(authState.user)
          : const Center(child: Text('Authentication required')),
    );
  }

  Widget _buildIncidentForm(User currentUser) {
    final availableCategories = _roleBasedCategories[currentUser.role.toLowerCase()] ?? 
                                _roleBasedCategories['guard']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.report_problem,
                      color: Colors.orange.shade600,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incident Report',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Document incidents for proper tracking and resolution',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Incident Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Incident Title *',
                hintText: 'Brief description of the incident',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an incident title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 16),
            
            // Category Selection
            _buildCategorySelector(availableCategories),
            
            const SizedBox(height: 16),
            
            // Priority Selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Priority Level *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              initialValue: _selectedPriority,
              items: _priorities.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      _getPriorityIcon(priority),
                      const SizedBox(width: 8),
                      Text(priority),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a priority level';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Detailed Description *',
                hintText: 'Describe what happened, when, and any relevant details',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a detailed description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 16),
            
            // Location Information
            _buildLocationCard(),
            
            const SizedBox(height: 16),
            
            // Media Capture
            _buildMediaCapture(),
            
            const SizedBox(height: 16),
            
            // Additional Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Any additional information or observations',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_add),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitIncident,
                icon: _isSubmitting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Incident Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => context.pop(),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List<String> categories) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Incident Category *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.shade100 : Colors.grey.shade200,
                      border: Border.all(
                        color: isSelected ? Colors.orange.shade600 : Colors.grey.shade400,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.orange.shade800 : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentLocation != null) ...[
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordinates: ${_currentLocation!.latitude.toStringAsFixed(6)}, '
                      '${_currentLocation!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Captured: ${DateTime.now().toLocal().toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Text('Location not available'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCapture() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Evidence & Media',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_attachedMedia.isNotEmpty) ...[
              Text(
                'Attached Media (${_attachedMedia.length} file(s))',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedMedia.length,
                  itemBuilder: (context, index) {
                    final file = _attachedMedia[index];
                    final isVideo = file.path.toLowerCase().contains('.mp4') ||
                                  file.path.toLowerCase().contains('.mov') ||
                                  file.path.toLowerCase().contains('.avi');
                    
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isVideo
                                ? Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.black87,
                                    child: const Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  )
                                : Image.network(
                                    file.path,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _attachedMedia.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _captureMedia(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _captureMedia(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose Photo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _captureVideo(ImageSource.camera),
                    icon: const Icon(Icons.videocam),
                    label: const Text('Record Video'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _captureVideo(ImageSource.gallery),
                    icon: const Icon(Icons.video_library),
                    label: const Text('Choose Video'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Icon(Icons.warning, color: Colors.red);
      case 'high':
        return const Icon(Icons.priority_high, color: Colors.orange);
      case 'medium':
        return const Icon(Icons.circle, color: Colors.yellow);
      case 'low':
        return const Icon(Icons.circle_outlined, color: Colors.green);
      default:
        return const Icon(Icons.circle_outlined);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = position;
        });
      }
    } catch (e) {
      // Error getting location - expected in development/testing
      if (mounted) {
        print('Error getting location: $e'); // Keep for debugging
      }
    }
  }

  Future<void> _captureMedia(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null && mounted) {
        // Show compression in progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Optimizing image...'),
            duration: Duration(seconds: 1),
          ),
        );

        // Compress image based on battery level and context
        final performanceService = PerformanceMonitoringService.instance;
        final compressionService = ImageCompressionService.instance;
        
        XFile? compressedImage;
        if (performanceService.batteryLevel <= 20) {
          // Aggressive compression for low battery
          compressedImage = await compressionService.compressImageForProfile(image);
        } else {
          // Standard incident compression
          compressedImage = await compressionService.compressImageForIncident(image);
        }
        
        setState(() {
          _attachedMedia.add(compressedImage ?? image);
        });

        // Show compression result
        if (compressedImage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image optimized for ${performanceService.batteryLevel}% battery'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureVideo(ImageSource source) async {
    try {
      final performanceService = PerformanceMonitoringService.instance;
      
      // Check battery level before video capture
      if (performanceService.batteryLevel <= 15) {
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Low Battery Warning'),
              content: Text(
                'Battery level is at ${performanceService.batteryLevel}%. '
                'Video recording may drain battery quickly. Continue?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
          
          if (proceed != true) return;
        }
      }

      final ImagePicker picker = ImagePicker();
      
      // Adjust video quality based on battery level
      Duration maxDuration;
      if (performanceService.batteryLevel <= 20) {
        maxDuration = const Duration(minutes: 2); // Shorter for low battery
      } else if (performanceService.batteryLevel <= 50) {
        maxDuration = const Duration(minutes: 3); // Medium duration
      } else {
        maxDuration = const Duration(minutes: 5); // Full duration
      }
      
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
      
      if (video != null && mounted) {
        setState(() {
          _attachedMedia.add(video);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video captured (${maxDuration.inMinutes}min max due to ${performanceService.batteryLevel}% battery)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an incident category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = ref.read(authNotifierProvider);
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }
      
      final user = authState.user;

      // Upload media files first if any
      List<String> evidenceFiles = [];
      if (_attachedMedia.isNotEmpty) {
        // Note: File upload implementation would be needed here
        // For now, we'll simulate with file paths
        evidenceFiles = _attachedMedia.map((file) => file.path).toList();
      }

      // Create incident via service
      final response = await IncidentService.instance.createIncident(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        priority: _selectedPriority ?? 'medium',
        siteId: user.assignedSites?.isNotEmpty == true ? user.assignedSites!.first : null,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        locationAccuracy: _currentLocation?.accuracy,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        evidenceFiles: evidenceFiles.isNotEmpty ? evidenceFiles : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incident #${response.incident?.id ?? 'unknown'} submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        context.pop(); // Return to previous screen
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit incident: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}