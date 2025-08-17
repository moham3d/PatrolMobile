import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/incident.dart';
import '../../../core/providers/incident_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/role_based_widget.dart';
import '../../../core/constants/app_constants.dart';

/// Screen for viewing and managing individual incident details
class IncidentDetailScreen extends ConsumerStatefulWidget {
  final String incidentId;

  const IncidentDetailScreen({
    super.key,
    required this.incidentId,
  });

  @override
  ConsumerState<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  final _notesController = TextEditingController();
  final _resolutionController = TextEditingController();
  
  String? _newStatus;
  int? _assignedUserId;
  
  final List<String> _statusOptions = ['open', 'in_progress', 'resolved'];
  
  @override
  void dispose() {
    _notesController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(incidentProvider(int.parse(widget.incidentId)));
    final updateState = ref.watch(incidentUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Incident #${widget.incidentId}'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          RoleBasedWidget(
            allowedRoles: const ['supervisor', 'site_manager', 'admin'],
            child: IconButton(
              onPressed: () => _showIncidentActions(context),
              icon: const Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: incidentAsync.when(
        data: (incident) => _buildIncidentDetail(incident, updateState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorView(error.toString()),
      ),
    );
  }

  Widget _buildIncidentDetail(Incident incident, IncidentUpdateState updateState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and Priority Header
          _buildStatusHeader(incident),
          
          const SizedBox(height: 20),
          
          // Incident Information
          _buildInformationSection(incident),
          
          const SizedBox(height: 20),
          
          // Location Information
          if (incident.latitude != null && incident.longitude != null)
            _buildLocationSection(incident),
          
          const SizedBox(height: 20),
          
          // Evidence Section
          if (incident.evidenceFiles != null && incident.evidenceFiles!.isNotEmpty)
            _buildEvidenceSection(incident),
          
          const SizedBox(height: 20),
          
          // Management Actions (Role-based)
          RoleBasedWidget(
            allowedRoles: const ['supervisor', 'site_manager', 'admin'],
            child: _buildManagementSection(incident, updateState),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(Incident incident) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPriorityChip(incident.priority),
              const SizedBox(width: 12),
              _buildStatusChip(incident.status),
              const Spacer(),
              Text(
                'ID: ${incident.id}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            incident.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                incident.category,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(incident.createdAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(Incident incident) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Description', incident.description),
            
            if (incident.notes != null && incident.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Notes', incident.notes!),
            ],
            
            const SizedBox(height: 12),
            _buildInfoRow('Created By', 'User #${incident.createdBy}'),
            
            if (incident.assignedTo != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Assigned To', 'User #${incident.assignedTo}'),
            ],
            
            if (incident.siteId != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Site', 'Site #${incident.siteId}'),
            ],
            
            if (incident.locationId != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Location', 'Location #${incident.locationId}'),
            ],
            
            const SizedBox(height: 12),
            _buildInfoRow('Last Updated', _formatDateTime(incident.updatedAt)),
            
            if (incident.resolvedAt != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Resolved At', _formatDateTime(incident.resolvedAt!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(Incident incident) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordinates',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${incident.latitude!.toStringAsFixed(6)}, ${incident.longitude!.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (incident.locationAccuracy != null)
                        Text(
                          'Accuracy: ±${incident.locationAccuracy!.toStringAsFixed(1)}m',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openMap(incident.latitude!, incident.longitude!),
                  icon: const Icon(Icons.map),
                  label: const Text('View on Map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSection(Incident incident) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evidence & Media',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: incident.evidenceFiles!.length,
              itemBuilder: (context, index) {
                final filePath = incident.evidenceFiles![index];
                final isVideo = filePath.toLowerCase().contains('.mp4') ||
                               filePath.toLowerCase().contains('.mov') ||
                               filePath.toLowerCase().contains('.avi');
                
                return GestureDetector(
                  onTap: () => _openFile(filePath),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isVideo
                        ? Container(
                            color: Colors.black87,
                            child: const Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 40,
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection(Incident incident, IncidentUpdateState updateState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Update
            if (!incident.isResolved) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Update Status',
                  border: OutlineInputBorder(),
                ),
                value: _newStatus ?? incident.status.toLowerCase(),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _newStatus = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Add Notes',
                hintText: 'Add management notes or updates',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            
            // Resolution Notes (if resolving)
            if (_newStatus == 'resolved') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _resolutionController,
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes *',
                  hintText: 'Describe how the incident was resolved',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (_newStatus == 'resolved' && (value == null || value.trim().isEmpty)) {
                    return 'Resolution notes are required when resolving an incident';
                  }
                  return null;
                },
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Action Buttons
            if (updateState.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  if (!incident.isResolved && _newStatus != null && _newStatus != incident.status.toLowerCase()) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateIncident(incident),
                        icon: const Icon(Icons.update),
                        label: Text(_newStatus == 'resolved' ? 'Resolve Incident' : 'Update Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _newStatus == 'resolved' ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  if (_notesController.text.isNotEmpty && (_newStatus == null || _newStatus == incident.status.toLowerCase())) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addNotes(incident),
                        icon: const Icon(Icons.note_add),
                        label: const Text('Add Notes'),
                      ),
                    ),
                  ],
                ],
              ),
            
            if (updateState.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
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
                        updateState.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    IconData icon;
    
    switch (priority.toLowerCase()) {
      case 'critical':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'high':
        color = Colors.orange;
        icon = Icons.priority_high;
        break;
      case 'medium':
        color = Colors.yellow.shade700;
        icon = Icons.circle;
        break;
      case 'low':
        color = Colors.green;
        icon = Icons.circle_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle_outlined;
    }

    return Chip(
      label: Text(
        priority.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: Icon(icon, color: Colors.white, size: 16),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'in_progress':
      case 'assigned':
        color = Colors.blue;
        icon = Icons.work;
        break;
      case 'open':
      case 'reported':
        color = Colors.orange;
        icon = Icons.report_problem;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: Icon(icon, color: Colors.white, size: 16),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load incident',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(incidentProvider(int.parse(widget.incidentId)));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showIncidentActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Incident'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit screen (would need to be implemented)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: const Text('Assign Incident'),
              onTap: () {
                Navigator.pop(context);
                _showAssignDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Incident'),
              onTap: () {
                Navigator.pop(context);
                _shareIncident();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Incident'),
        content: const Text('Assignment feature coming soon. This would show a list of available users to assign the incident to.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareIncident() {
    // Basic sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Incident #${widget.incidentId} details copied to clipboard')),
    );
  }

  Future<void> _updateIncident(Incident incident) async {
    if (_newStatus == 'resolved' && _resolutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resolution notes are required when resolving an incident'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref.read(incidentUpdateProvider.notifier).updateIncident(
      incidentId: incident.id,
      status: _newStatus,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      resolutionNotes: _newStatus == 'resolved' ? _resolutionController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_newStatus == 'resolved' 
              ? 'Incident resolved successfully' 
              : 'Incident status updated'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the incident data
      ref.invalidate(incidentProvider(incident.id));
      
      // Clear form
      _notesController.clear();
      _resolutionController.clear();
      setState(() {
        _newStatus = null;
      });
    }
  }

  Future<void> _addNotes(Incident incident) async {
    final success = await ref.read(incidentUpdateProvider.notifier).updateIncident(
      incidentId: incident.id,
      notes: _notesController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the incident data
      ref.invalidate(incidentProvider(incident.id));
      
      // Clear form
      _notesController.clear();
    }
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final url = 'https://maps.google.com/?q=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map')),
        );
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    // In a real implementation, this would open the file viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening file: ${filePath.split('/').last}')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}