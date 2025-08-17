import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/patrol_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/patrol_simple.dart';
import '../../../core/models/checkpoint.dart';
import '../widgets/enhanced_checkpoint_manager.dart';
import '../widgets/patrol_progress_indicator.dart';

/// Enhanced patrol completion workflow with comprehensive validation
class EnhancedPatrolCompletionWorkflow extends ConsumerStatefulWidget {
  final int patrolId;
  
  const EnhancedPatrolCompletionWorkflow({
    super.key,
    required this.patrolId,
  });

  @override
  ConsumerState<EnhancedPatrolCompletionWorkflow> createState() => _EnhancedPatrolCompletionWorkflowState();
}

class _EnhancedPatrolCompletionWorkflowState extends ConsumerState<EnhancedPatrolCompletionWorkflow> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _completionNotesController = TextEditingController();
  final _issuesController = TextEditingController();
  
  bool _isCompletingPatrol = false;
  bool _hasIssues = false;
  bool _requiresFollowUp = false;
  String _completionType = 'normal'; // normal, early, partial
  Position? _currentLocation;
  
  final List<String> _selectedIssueTypes = [];
  final List<String> _followUpActions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatrolData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _completionNotesController.dispose();
    _issuesController.dispose();
    super.dispose();
  }

  void _loadPatrolData() {
    ref.read(patrolDetailProvider(widget.patrolId).notifier).loadPatrol();
    ref.read(patrolProgressProvider(widget.patrolId).notifier).loadProgress();
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
      // Handle location error
      _showLocationError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patrolDetailState = ref.watch(patrolDetailProvider(widget.patrolId));
    final patrolProgressState = ref.watch(patrolProgressProvider(widget.patrolId));
    final authState = ref.watch(authNotifierProvider);

    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Please log in to complete patrol')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Patrol'),
        elevation: 0,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: 'Review'),
            Tab(icon: Icon(Icons.report_problem), text: 'Issues'),
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'Complete'),
          ],
        ),
      ),
      body: switch (patrolDetailState) {
        PatrolDetailLoading() => const Center(child: CircularProgressIndicator()),
        PatrolDetailLoaded(:final patrol) => _buildCompletionWorkflow(patrol, patrolProgressState),
        PatrolDetailError(:final message) => _buildErrorView(message),
        _ => const Center(child: Text('Initializing...')),
      },
    );
  }

  Widget _buildCompletionWorkflow(Patrol patrol, dynamic progressState) {
    return Column(
      children: [
        // Overall progress header
        _buildOverallProgressHeader(patrol, progressState),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReviewTab(patrol, progressState),
              _buildIssuesTab(),
              _buildCompletionTab(patrol),
            ],
          ),
        ),
        
        // Action buttons
        _buildActionButtons(patrol, progressState),
      ],
    );
  }

  Widget _buildOverallProgressHeader(Patrol patrol, dynamic progressState) {
    final progress = progressState is PatrolProgressLoaded ? progressState.progress : null;
    final completionPercentage = progress?.completionPercentage ?? 0.0;
    final visitedCheckpoints = progress?.visitedCheckpoints ?? 0;
    final totalCheckpoints = progress?.totalCheckpoints ?? patrol.checkpoints?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patrol.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Started: ${_formatStartTime(patrol.startTime)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  children: [
                    Text(
                      '${completionPercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Complete',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '$visitedCheckpoints of $totalCheckpoints checkpoints completed',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab(Patrol patrol, dynamic progressState) {
    final progress = progressState is PatrolProgressLoaded ? progressState.progress : null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion readiness check
          _buildReadinessCheck(patrol, progress),
          
          const SizedBox(height: 24),
          
          // Checkpoint manager
          if (patrol.checkpoints != null && patrol.checkpoints!.isNotEmpty) ...[
            const Text(
              'Checkpoint Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: EnhancedCheckpointManager(
                patrolId: widget.patrolId,
                checkpoints: patrol.checkpoints!,
                progress: progress,
                isInteractive: false,
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Summary statistics
          _buildSummaryStatistics(patrol, progress),
        ],
      ),
    );
  }

  Widget _buildReadinessCheck(Patrol patrol, PatrolProgress? progress) {
    final totalCheckpoints = patrol.checkpoints?.length ?? 0;
    final visitedCheckpoints = progress?.visitedCheckpoints ?? 0;
    final completionPercentage = progress?.completionPercentage ?? 0.0;
    
    final bool allCheckpointsVisited = visitedCheckpoints >= totalCheckpoints;
    final bool minimumCompleted = completionPercentage >= 80.0; // 80% minimum
    final bool hasLocation = _currentLocation != null;
    
    final readinessItems = [
      ReadinessItem(
        title: 'All Checkpoints Visited',
        isCompleted: allCheckpointsVisited,
        description: '$visitedCheckpoints of $totalCheckpoints checkpoints completed',
        icon: Icons.checklist,
      ),
      ReadinessItem(
        title: 'Minimum Completion',
        isCompleted: minimumCompleted,
        description: '${completionPercentage.toStringAsFixed(1)}% completed (minimum 80%)',
        icon: Icons.percent,
      ),
      ReadinessItem(
        title: 'Location Available',
        isCompleted: hasLocation,
        description: hasLocation ? 'GPS location captured' : 'Getting location...',
        icon: Icons.location_on,
      ),
    ];
    
    final bool canComplete = readinessItems.every((item) => item.isCompleted);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canComplete ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canComplete ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                canComplete ? Icons.check_circle : Icons.warning,
                color: canComplete ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                canComplete ? 'Ready to Complete' : 'Completion Checklist',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: canComplete ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...readinessItems.map((item) => _buildReadinessItem(item)),
          
          if (!canComplete) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You can still complete the patrol, but it will be marked as "Partial Completion"',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadinessItem(ReadinessItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: item.isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Icon(item.icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isCompleted ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatistics(Patrol patrol, PatrolProgress? progress) {
    final startTime = patrol.startTime != null ? DateTime.parse(patrol.startTime!) : DateTime.now();
    final duration = DateTime.now().difference(startTime);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patrol Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Duration',
                  _formatDuration(duration),
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Checkpoints',
                  '${progress?.visitedCheckpoints ?? 0}/${patrol.checkpoints?.length ?? 0}',
                  Icons.location_on,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Progress',
                  '${progress?.completionPercentage?.toStringAsFixed(1) ?? 0}%',
                  Icons.percent,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Status',
                  patrol.status.toUpperCase(),
                  Icons.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Issues',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Issues Encountered'),
            subtitle: const Text('Toggle if any issues were found during patrol'),
            value: _hasIssues,
            onChanged: (value) {
              setState(() {
                _hasIssues = value;
              });
            },
          ),
          
          if (_hasIssues) ...[
            const SizedBox(height: 24),
            
            const Text(
              'Issue Types',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Security Concern',
                'Equipment Malfunction',
                'Access Issue',
                'Safety Hazard',
                'Maintenance Required',
                'Other',
              ].map((issue) => _buildIssueTypeChip(issue)).toList(),
            ),
            
            const SizedBox(height: 24),
            
            TextField(
              controller: _issuesController,
              decoration: const InputDecoration(
                labelText: 'Issue Details',
                hintText: 'Describe the issues encountered...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 24),
            
            SwitchListTile(
              title: const Text('Requires Follow-up'),
              subtitle: const Text('Check if these issues need immediate attention'),
              value: _requiresFollowUp,
              onChanged: (value) {
                setState(() {
                  _requiresFollowUp = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIssueTypeChip(String issueType) {
    final isSelected = _selectedIssueTypes.contains(issueType);
    
    return FilterChip(
      label: Text(issueType),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedIssueTypes.add(issueType);
          } else {
            _selectedIssueTypes.remove(issueType);
          }
        });
      },
    );
  }

  Widget _buildCompletionTab(Patrol patrol) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completion Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Completion type
            const Text(
              'Completion Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Normal Completion'),
                  subtitle: const Text('All checkpoints visited and patrol completed as planned'),
                  value: 'normal',
                  groupValue: _completionType,
                  onChanged: (value) {
                    setState(() {
                      _completionType = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Early Completion'),
                  subtitle: const Text('Patrol completed earlier than scheduled'),
                  value: 'early',
                  groupValue: _completionType,
                  onChanged: (value) {
                    setState(() {
                      _completionType = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Partial Completion'),
                  subtitle: const Text('Some checkpoints not visited due to circumstances'),
                  value: 'partial',
                  groupValue: _completionType,
                  onChanged: (value) {
                    setState(() {
                      _completionType = value!;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Completion notes
            TextFormField(
              controller: _completionNotesController,
              decoration: const InputDecoration(
                labelText: 'Completion Notes',
                hintText: 'Add any additional notes about the patrol...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (_completionType == 'partial' && (value == null || value.isEmpty)) {
                  return 'Please explain why the patrol was partially completed';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Location info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Completion Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_currentLocation != null)
                    Text(
                      'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  else
                    const Text('Getting location...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Patrol patrol, dynamic progressState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
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
              onPressed: _isCompletingPatrol ? null : () => _completePatrol(patrol),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
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
                  : const Text('Complete Patrol'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text('Error: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPatrolData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
        'completion_type': _completionType,
        'notes': _completionNotesController.text,
        'has_issues': _hasIssues,
        'issue_types': _selectedIssueTypes,
        'issue_details': _issuesController.text,
        'requires_followup': _requiresFollowUp,
        'latitude': _currentLocation?.latitude,
        'longitude': _currentLocation?.longitude,
        'accuracy': _currentLocation?.accuracy,
      };

      await ref.read(patrolDetailProvider(widget.patrolId).notifier).completePatrol(completionData);
      
      if (mounted) {
        _showCompletionSuccess(patrol);
      }
    } catch (e) {
      if (mounted) {
        _showCompletionError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingPatrol = false;
        });
      }
    }
  }

  void _showCompletionSuccess(Patrol patrol) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Patrol Completed'),
          ],
        ),
        content: Text('${patrol.title} has been successfully completed.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.go('/patrols'); // Navigate to patrol list
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompletionError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to complete patrol: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _completePatrol,
        ),
      ),
    );
  }

  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to get current location. Please check GPS settings.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatStartTime(String? startTime) {
    if (startTime == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(startTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inHours > 0) {
        return '${difference.inHours}h ${difference.inMinutes % 60}m ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    } catch (e) {
      return startTime;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class ReadinessItem {
  final String title;
  final bool isCompleted;
  final String description;
  final IconData icon;

  ReadinessItem({
    required this.title,
    required this.isCompleted,
    required this.description,
    required this.icon,
  });
}