import 'package:flutter/material.dart';
import '../../../core/models/patrol_simple.dart';

/// Action buttons for patrol operations
class PatrolActionButtons extends StatelessWidget {
  final Patrol patrol;
  final PatrolProgress progress;
  final VoidCallback? onStartPatrol;
  final VoidCallback? onEndPatrol;
  final VoidCallback? onScanCheckpoint;
  final VoidCallback? onPausePatrol;
  final VoidCallback? onResumePatrol;

  const PatrolActionButtons({
    super.key,
    required this.patrol,
    required this.progress,
    this.onStartPatrol,
    this.onEndPatrol,
    this.onScanCheckpoint,
    this.onPausePatrol,
    this.onResumePatrol,
  });

  @override
  Widget build(BuildContext context) {
    if (patrol.isPending) {
      return _buildPendingActions(context);
    } else if (patrol.isActive) {
      return _buildActiveActions(context);
    } else if (patrol.isCompleted) {
      return _buildCompletedActions(context);
    } else {
      return _buildDefaultActions(context);
    }
  }

  Widget _buildPendingActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showPatrolInfo(context),
            icon: const Icon(Icons.info_outline),
            label: const Text('View Info'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onStartPatrol,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Patrol'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onScanCheckpoint,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEndPatrol,
                icon: const Icon(Icons.stop),
                label: const Text('End Patrol'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPausePatrol ?? () => _showComingSoon(context),
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showEmergency(context),
                icon: const Icon(Icons.emergency),
                label: const Text('SOS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showPatrolReport(context),
            icon: const Icon(Icons.description),
            label: const Text('View Report'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _sharePatrolReport(context),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showPatrolInfo(context),
            icon: const Icon(Icons.info_outline),
            label: const Text('View Details'),
          ),
        ),
      ],
    );
  }

  void _showPatrolInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patrol.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patrol.description != null) ...[
              Text(patrol.description!),
              const SizedBox(height: 16),
            ],
            
            _buildInfoRow('Status', patrol.status.replaceAll('_', ' ').toUpperCase()),
            _buildInfoRow('Priority', patrol.priority.toUpperCase()),
            _buildInfoRow('Checkpoints', '${progress.totalCheckpoints}'),
            
            if (patrol.estimatedDuration != null)
              _buildInfoRow('Est. Duration', '${patrol.estimatedDuration} minutes'),
            
            if (patrol.siteName != null)
              _buildInfoRow('Site', patrol.siteName!),
            
            if (patrol.assignedUserName != null)
              _buildInfoRow('Assigned to', patrol.assignedUserName!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showPatrolReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Patrol Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportStat('Progress', '${progress.completionPercentage.toStringAsFixed(1)}%'),
            _buildReportStat('Checkpoints', '${progress.visitedCheckpoints}/${progress.totalCheckpoints}'),
            if (progress.isStarted)
              _buildReportStat('Status', 'Completed'),
            
            const SizedBox(height: 16),
            const Text('Detailed report will be available after processing.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sharePatrolReport(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _sharePatrolReport(BuildContext context) {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report sharing coming soon'),
      ),
    );
  }

  void _showEmergency(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency'),
          ],
        ),
        content: const Text(
          'Are you sure you want to trigger an emergency alert? This will notify all supervisors immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Trigger emergency alert
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon'),
      ),
    );
  }
}

/// Quick action buttons for patrol cards
class QuickPatrolActions extends StatelessWidget {
  final Patrol patrol;
  final VoidCallback? onStart;
  final VoidCallback? onContinue;
  final VoidCallback? onView;

  const QuickPatrolActions({
    super.key,
    required this.patrol,
    this.onStart,
    this.onContinue,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (patrol.isPending) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onView,
              child: const Text('View'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: onStart,
              child: const Text('Start'),
            ),
          ),
        ],
      );
    } else if (patrol.isActive) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onView,
              child: const Text('Details'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onView,
          child: const Text('View Details'),
        ),
      );
    }
  }
}

/// Floating action button for patrol operations
class PatrolFloatingActionButton extends StatelessWidget {
  final Patrol? currentPatrol;
  final VoidCallback? onScan;
  final VoidCallback? onEmergency;

  const PatrolFloatingActionButton({
    super.key,
    this.currentPatrol,
    this.onScan,
    this.onEmergency,
  });

  @override
  Widget build(BuildContext context) {
    if (currentPatrol?.isActive == true) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'emergency',
            onPressed: onEmergency,
            backgroundColor: Colors.red,
            child: const Icon(Icons.emergency, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: onScan,
            child: const Icon(Icons.qr_code_scanner),
          ),
        ],
      );
    }

    return FloatingActionButton(
      onPressed: onScan,
      child: const Icon(Icons.qr_code_scanner),
    );
  }
}