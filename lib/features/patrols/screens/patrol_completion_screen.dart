import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/patrol_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/patrol_simple.dart';
import '../../../core/models/checkpoint.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/enhanced_checkpoint_status_indicator.dart';

/// Screen for completing patrols with enhanced workflow
class PatrolCompletionScreen extends ConsumerStatefulWidget {
  final int patrolId;
  
  const PatrolCompletionScreen({
    super.key,
    required this.patrolId,
  });

  @override
  ConsumerState<PatrolCompletionScreen> createState() => _PatrolCompletionScreenState();
}

class _PatrolCompletionScreenState extends ConsumerState<PatrolCompletionScreen> {
  final _completionNotesController = TextEditingController();
  final _issuesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCompletingPatrol = false;
  bool _hasIssues = false;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadPatrolData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _completionNotesController.dispose();
    _issuesController.dispose();
    super.dispose();
  }

  void _loadPatrolData() {
    ref.read(patrolDetailProvider(widget.patrolId).notifier).loadPatrol();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      // Handle location error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final patrolDetailState = ref.watch(patrolDetailProvider(widget.patrolId));
    final authState = ref.watch(authNotifierProvider);

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to complete patrol'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Patrol'),
        elevation: 0,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: switch (patrolDetailState) {
        PatrolDetailInitial() => const Center(
          child: Text('Initializing...'),
        ),
        PatrolDetailLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        PatrolDetailLoaded(:final patrol) => _buildCompletionForm(patrol),
        PatrolDetailError(:final message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading patrol',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPatrolData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      },
    );
  }

  Widget _buildCompletionForm(Patrol patrol) {
    final checkpointsCompleted = patrol.checkpoints?.where((cp) => cp.lastVisitAt != null).length ?? 0;
    final totalCheckpoints = patrol.checkpoints?.length ?? 0;
    final allCheckpointsCompleted = checkpointsCompleted == totalCheckpoints && totalCheckpoints > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patrol Summary Card
            _buildPatrolSummaryCard(patrol),
            
            const SizedBox(height: 24),
            
            // Checkpoint Progress
            if (patrol.checkpoints != null && patrol.checkpoints!.isNotEmpty) ...[
              Text(
                'Checkpoint Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CheckpointStatusIndicator(
                checkpoints: patrol.checkpoints!,
                compact: false,
              ),
              const SizedBox(height: 24),
            ],
            
            // Completion Status
            _buildCompletionStatusCard(allCheckpointsCompleted, checkpointsCompleted, totalCheckpoints),
            
            const SizedBox(height: 24),
            
            // Completion Notes
            Text(
              'Completion Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _completionNotesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this patrol completion...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide completion notes';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Issues Section
            Row(
              children: [
                Checkbox(
                  value: _hasIssues,
                  onChanged: (value) {
                    setState(() {
                      _hasIssues = value ?? false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Report issues encountered during patrol',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            
            if (_hasIssues) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _issuesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe any issues, incidents, or observations...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_hasIssues && (value == null || value.trim().isEmpty)) {
                    return 'Please describe the issues encountered';
                  }
                  return null;
                },
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCompletingPatrol ? null : () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isCompletingPatrol || !allCheckpointsCompleted 
                        ? null 
                        : () => _completePatrol(patrol),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allCheckpointsCompleted ? Colors.green : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isCompletingPatrol
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Complete Patrol',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Warning message if not all checkpoints completed
            if (!allCheckpointsCompleted) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All checkpoints must be completed before the patrol can be finished.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPatrolSummaryCard(Patrol patrol) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    patrol.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(patrol.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    patrol.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(patrol.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            if (patrol.description != null) ...[
              const SizedBox(height: 8),
              Text(
                patrol.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Additional patrol info
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (patrol.assignedUserName != null)
                  _buildInfoChip(Icons.person, 'Assigned to: ${patrol.assignedUserName!}'),
                if (patrol.siteName != null)
                  _buildInfoChip(Icons.location_on, 'Site: ${patrol.siteName!}'),
                if (patrol.estimatedDuration != null)
                  _buildInfoChip(Icons.timer, 'Duration: ${patrol.estimatedDuration}min'),
                _buildInfoChip(Icons.priority_high, 'Priority: ${patrol.priority.toUpperCase()}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionStatusCard(bool allCompleted, int completed, int total) {
    return Card(
      color: allCompleted ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              allCompleted ? Icons.check_circle : Icons.schedule,
              color: allCompleted ? Colors.green.shade600 : Colors.orange.shade600,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allCompleted ? 'Ready to Complete' : 'Patrol in Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: allCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    allCompleted 
                        ? 'All checkpoints have been completed successfully'
                        : '$completed of $total checkpoints completed',
                    style: TextStyle(
                      color: allCompleted ? Colors.green.shade600 : Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _completePatrol(Patrol patrol) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCompletingPatrol = true;
    });

    try {
      final completionData = {
        'completion_notes': _completionNotesController.text.trim(),
        'has_issues': _hasIssues,
        'issues_description': _hasIssues ? _issuesController.text.trim() : null,
        'completed_at': DateTime.now().toIso8601String(),
        'completion_location': _currentLocation != null 
            ? {
                'latitude': _currentLocation!.latitude,
                'longitude': _currentLocation!.longitude,
                'accuracy': _currentLocation!.accuracy,
              }
            : null,
      };

      await ref.read(patrolDetailProvider(widget.patrolId).notifier)
          .completePatrol(completionData);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Patrol "${patrol.title}" completed successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to dashboard or patrol list
        context.go(AppConstants.dashboardRoute);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to complete patrol: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingPatrol = false;
        });
      }
    }
  }
}