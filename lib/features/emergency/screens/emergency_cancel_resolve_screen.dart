import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/emergency.dart';
import '../../../core/providers/emergency_provider.dart';
import '../../../core/widgets/role_based_widget.dart';

/// Emergency cancel/resolve screen for managing active alerts
class EmergencyCancelResolveScreen extends ConsumerStatefulWidget {
  final EmergencyAlert alert;

  const EmergencyCancelResolveScreen({
    super.key,
    required this.alert,
  });

  @override
  ConsumerState<EmergencyCancelResolveScreen> createState() => _EmergencyCancelResolveScreenState();
}

class _EmergencyCancelResolveScreenState extends ConsumerState<EmergencyCancelResolveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _followUpController = TextEditingController();
  
  String _selectedAction = 'resolve';
  String _resolutionType = 'resolved';
  final List<String> _followUpActions = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _notesController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Alert #${widget.alert.id}'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Alert summary card
              _buildAlertSummaryCard(),
              
              const SizedBox(height: 24),
              
              // Action selection
              _buildActionSelection(),
              
              const SizedBox(height: 24),
              
              // Resolution type selection (only if resolving)
              if (_selectedAction == 'resolve') ...[
                _buildResolutionTypeSelection(),
                const SizedBox(height: 24),
              ],
              
              // Notes section
              _buildNotesSection(),
              
              const SizedBox(height: 24),
              
              // Follow-up actions (only if resolving)
              if (_selectedAction == 'resolve') ...[
                _buildFollowUpActionsSection(),
                const SizedBox(height: 24),
              ],
              
              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertSummaryCard() {
    final severityColor = widget.alert.severityColor;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.alert.severity.toUpperCase(),
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
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.alert.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(widget.alert.triggeredAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              widget.alert.description,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.alert.userName ?? 'User #${widget.alert.userId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                if (widget.alert.locationName != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.alert.locationName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Action',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        SupervisorOnlyWidget(
          child: RadioListTile<String>(
            value: 'resolve',
            groupValue: _selectedAction,
            onChanged: (value) {
              setState(() {
                _selectedAction = value!;
              });
            },
            title: const Text('Resolve Alert'),
            subtitle: const Text('Mark the emergency situation as resolved'),
            secondary: Icon(Icons.check_circle, color: Colors.green.shade600),
          ),
        ),
        
        SupervisorOnlyWidget(
          child: RadioListTile<String>(
            value: 'cancel',
            groupValue: _selectedAction,
            onChanged: (value) {
              setState(() {
                _selectedAction = value!;
              });
            },
            title: const Text('Cancel Alert'),
            subtitle: const Text('Cancel the alert (false alarm or duplicate)'),
            secondary: Icon(Icons.cancel, color: Colors.orange.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolution Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _resolutionType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'resolved', child: Text('Successfully Resolved')),
            DropdownMenuItem(value: 'false_alarm', child: Text('False Alarm')),
            DropdownMenuItem(value: 'duplicate', child: Text('Duplicate Alert')),
            DropdownMenuItem(value: 'referred', child: Text('Referred to Others')),
            DropdownMenuItem(value: 'escalated', child: Text('Escalated to Higher Authority')),
          ],
          onChanged: (value) {
            setState(() {
              _resolutionType = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a resolution type';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedAction == 'resolve' ? 'Resolution Notes' : 'Cancellation Reason',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: _selectedAction == 'resolve' 
                ? 'Describe how the emergency was resolved...'
                : 'Explain why the alert is being cancelled...',
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide ${_selectedAction == 'resolve' ? 'resolution notes' : 'cancellation reason'}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFollowUpActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Follow-up Actions (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Existing follow-up actions
        if (_followUpActions.isNotEmpty) ...[
          ..._followUpActions.map((action) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Chip(
              label: Text(action),
              onDeleted: () {
                setState(() {
                  _followUpActions.remove(action);
                });
              },
            ),
          )),
          const SizedBox(height: 8),
        ],
        
        // Add new follow-up action
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _followUpController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., File incident report, Schedule maintenance...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addFollowUpAction,
              icon: const Icon(Icons.add_circle),
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedAction == 'resolve' ? Colors.green : Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _selectedAction == 'resolve' ? 'Resolve Alert' : 'Cancel Alert',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  void _addFollowUpAction() {
    final action = _followUpController.text.trim();
    if (action.isNotEmpty && !_followUpActions.contains(action)) {
      setState(() {
        _followUpActions.add(action);
        _followUpController.clear();
      });
    }
  }

  Future<void> _processAction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final notifier = ref.read(emergencyAlertsProvider.notifier);
      
      if (_selectedAction == 'resolve') {
        await notifier.resolveAlert(
          widget.alert.id,
          resolution: _notesController.text.trim(),
          resolutionType: _resolutionType,
          followUpActions: _followUpActions.isNotEmpty ? _followUpActions : null,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency alert resolved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      } else {
        await notifier.cancelAlert(
          widget.alert.id,
          reason: _notesController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency alert cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_selectedAction} alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
}