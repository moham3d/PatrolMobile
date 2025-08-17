import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/emergency_provider.dart';
import '../../../core/models/emergency.dart';
import '../../../core/constants/app_constants.dart';

/// Emergency response screen for supervisors to manage active alerts
class EmergencyResponseScreen extends ConsumerStatefulWidget {
  const EmergencyResponseScreen({super.key});

  @override
  ConsumerState<EmergencyResponseScreen> createState() => _EmergencyResponseScreenState();
}

class _EmergencyResponseScreenState extends ConsumerState<EmergencyResponseScreen> {
  @override
  void initState() {
    super.initState();
    // Load emergency alerts when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyAlertsProvider.notifier).loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergencyState = ref.watch(emergencyAlertsProvider);
    final emergencyNotifier = ref.read(emergencyAlertsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Response'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => emergencyNotifier.loadAlerts(),
          ),
        ],
      ),
      body: _buildBody(context, emergencyState, emergencyNotifier),
    );
  }

  Widget _buildBody(BuildContext context, EmergencyAlertsState state, EmergencyAlertsNotifier notifier) {
    if (state is Loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is EmergencyError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.loadAlerts(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is Loaded) {
      final alerts = state.alerts;
      
      if (alerts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Colors.green.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Alerts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'All systems are running normally',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => notifier.loadAlerts(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildAlertCard(context, alert, notifier);
          },
        ),
      );
    }

    return const Center(
      child: Text('No alerts loaded'),
    );
  }

  Widget _buildAlertCard(BuildContext context, EmergencyAlert alert, EmergencyAlertsNotifier notifier) {
    final severityColor = _getSeverityColor(alert.severity);
    final statusColor = _getStatusColor(alert.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () => _showAlertDetails(context, alert, notifier),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(alert.triggeredAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Alert description
              Text(
                alert.description,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // User info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    alert.userName ?? 'User #${alert.userId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (alert.latitude != null && alert.longitude != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alert.locationName ?? 'Location available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  if (alert.status == 'active') ...[
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _acknowledgeAlert(alert, notifier),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Acknowledge'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _resolveAlert(context, alert, notifier),
                        icon: const Icon(Icons.done),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        onPressed: () => _escalateAlert(context, alert, notifier),
                        icon: const Icon(Icons.trending_up),
                        color: Colors.red,
                        tooltip: 'Escalate',
                      ),
                    ),
                  ] else if (alert.status == 'acknowledged') ...[
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _resolveAlert(context, alert, notifier),
                        icon: const Icon(Icons.done),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        onPressed: () => _escalateAlert(context, alert, notifier),
                        icon: const Icon(Icons.trending_up),
                        color: Colors.red,
                        tooltip: 'Escalate',
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        'Alert ${alert.status}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.red.shade500;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red.shade600;
      case 'acknowledged':
        return Colors.orange.shade600;
      case 'resolved':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return timestamp;
    }
  }

  void _acknowledgeAlert(EmergencyAlert alert, EmergencyAlertsNotifier notifier) async {
    // Show acknowledgment dialog
    final acknowledgmentNote = await _showAcknowledgmentDialog(context);
    
    try {
      await notifier.acknowledgeAlert(alert.id, note: acknowledgmentNote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert acknowledged with enhanced tracking'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to acknowledge alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resolveAlert(BuildContext context, EmergencyAlert alert, EmergencyAlertsNotifier notifier) async {
    final resolutionData = await _showEnhancedResolutionDialog(context);
    if (resolutionData != null) {
      try {
        await notifier.resolveAlert(
          alert.id,
          resolution: resolutionData['notes'],
          resolutionType: resolutionData['type'],
          followUpActions: resolutionData['followUp']?.cast<String>(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert resolved with enhanced tracking'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resolve alert: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showAcknowledgmentDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acknowledge Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Acknowledge that you have received and are responding to this alert.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Acknowledgment notes (optional)',
                hintText: 'Add any relevant notes...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showEnhancedResolutionDialog(BuildContext context) async {
    final notesController = TextEditingController();
    String selectedType = 'resolved';
    final followUpActions = <String>[];
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Resolve Alert'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resolution Type:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'false_alarm', child: Text('False Alarm')),
                    DropdownMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    DropdownMenuItem(value: 'referred', child: Text('Referred to Others')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text('Resolution Notes:'),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Describe how the alert was resolved...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Follow-up Actions (optional):'),
                const SizedBox(height: 8),
                ...followUpActions.map((action) => Chip(
                  label: Text(action),
                  onDeleted: () {
                    setState(() {
                      followUpActions.remove(action);
                    });
                  },
                )),
                TextButton.icon(
                  onPressed: () async {
                    final action = await _showAddFollowUpDialog(context);
                    if (action != null && action.isNotEmpty) {
                      setState(() {
                        followUpActions.add(action);
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Follow-up Action'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({
                'type': selectedType,
                'notes': notesController.text.trim(),
                'followUp': followUpActions,
              }),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Resolve'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showAddFollowUpDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Follow-up Action'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Follow-up action',
            hintText: 'e.g., File incident report, Schedule maintenance...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(BuildContext context, EmergencyAlert alert, EmergencyAlertsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmergencyAlertDetailsSheet(
        alert: alert,
        notifier: notifier,
      ),
    );
  }

  /// Open location in external map app
  void _openLocationInMap(BuildContext context, EmergencyAlert alert) async {
    if (alert.latitude == null || alert.longitude == null) return;
    
    try {
      final lat = alert.latitude!;
      final lng = alert.longitude!;
      final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: show coordinates in a snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location: $lat, $lng'),
              action: SnackBarAction(
                label: 'Copy',
                onPressed: () {
                  // In a real app, copy to clipboard using flutter/services
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Bottom sheet showing detailed alert information
class EmergencyAlertDetailsSheet extends StatelessWidget {
  final EmergencyAlert alert;
  final EmergencyAlertsNotifier notifier;
  
  const EmergencyAlertDetailsSheet({
    super.key,
    required this.alert,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Emergency Alert Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildDetailRow(context, 'Alert ID', '#${alert.id}'),
          _buildDetailRow(context, 'Status', alert.status.toUpperCase()),
          _buildDetailRow(context, 'Severity', alert.severity.toUpperCase()),
          _buildDetailRow(context, 'Description', alert.description),
          _buildDetailRow(context, 'User', alert.userName ?? 'User #${alert.userId}'),
          _buildDetailRow(context, 'Triggered At', _formatTimestamp(alert.triggeredAt)),
          
          if (alert.acknowledgedAt != null) 
            _buildDetailRow(context, 'Acknowledged At', _formatTimestamp(alert.acknowledgedAt!)),
          if (alert.resolvedAt != null) 
            _buildDetailRow(context, 'Resolved At', _formatTimestamp(alert.resolvedAt!)),
          
          if (alert.latitude != null && alert.longitude != null) ...[
            const SizedBox(height: 8),
            Text(
              'Location Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Location', alert.locationName ?? 'Unknown'),
            _buildDetailRow(context, 'Coordinates', 
              '${alert.latitude!.toStringAsFixed(6)}, ${alert.longitude!.toStringAsFixed(6)}'),
            _buildDetailRow(context, 'Accuracy', '${alert.latitude!.toStringAsFixed(1)} meters'),
          ],
          
          const SizedBox(height: 24),
          
          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: alert.latitude != null && alert.longitude != null 
                    ? () {
                        Navigator.of(context).pop();
                        _openLocationInMap(context, alert);
                      }
                    : null,
                  child: const Text('View Location'),
                ),
              ),
            ],
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
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
      ),
    );
  }

  void _escalateAlert(BuildContext context, EmergencyAlert alert, EmergencyAlertsNotifier notifier) async {
    final escalationReason = await _showEscalationDialog(context);
    if (escalationReason != null && escalationReason.isNotEmpty) {
      try {
        await notifier.escalateAlert(alert.id, escalationReason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert escalated successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to escalate alert: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<String?> _showEscalationDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Escalate Alert'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will immediately escalate the alert to higher-level personnel and trigger additional emergency protocols.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Escalation reason',
                hintText: 'Why is this alert being escalated?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Escalate'),
          ),
        ],
      ),
    );
  }
}