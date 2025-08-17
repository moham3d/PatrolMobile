import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/patrol_simple.dart';
import 'patrol_progress_indicator.dart';

/// Card widget for displaying patrol information
class PatrolCard extends StatelessWidget {
  final Patrol patrol;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool showActions;

  const PatrolCard({
    super.key,
    required this.patrol,
    this.onTap,
    this.showProgress = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      patrol.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              
              if (patrol.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  patrol.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Info row
              Row(
                children: [
                  if (patrol.assignedUserName != null) ...[
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      patrol.assignedUserName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  if (patrol.siteName != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        patrol.siteName!,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Additional info
              Row(
                children: [
                  if (patrol.checkpointCount > 0) ...[
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${patrol.checkpointCount} checkpoints',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  if (patrol.estimatedDuration != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${patrol.estimatedDuration}m',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  _buildPriorityIndicator(),
                ],
              ),
              
              // Progress indicator
              if (showProgress) ...[
                const SizedBox(height: 12),
                PatrolProgressIndicator(
                  progress: patrol.completionPercentage / 100,
                  showPercentage: true,
                ),
              ],
              
              // Due date warning
              if (patrol.isOverdue) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Overdue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Action buttons
              if (showActions && patrol.isPending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/patrol/${patrol.id}'),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _startPatrol(context),
                        child: const Text('Start Patrol'),
                      ),
                    ),
                  ],
                ),
              ] else if (showActions && patrol.isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/patrol/${patrol.id}'),
                        child: const Text('Continue'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push('/scanner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Scan Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (patrol.status) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        statusText = 'Pending';
        break;
      case 'in_progress':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        statusText = 'In Progress';
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusText = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        statusText = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusText = patrol.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    if (patrol.priority == 'low') {
      return const SizedBox.shrink();
    }

    Color color;
    IconData icon;

    switch (patrol.priority) {
      case 'urgent':
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case 'high':
        color = Colors.orange;
        icon = Icons.keyboard_arrow_up;
        break;
      case 'medium':
        color = Colors.blue;
        icon = Icons.remove;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          patrol.priority.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _startPatrol(BuildContext context) {
    // Navigate to patrol detail screen with start action
    context.push('/patrol/${patrol.id}?action=start');
  }
}