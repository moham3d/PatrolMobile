import 'package:flutter/material.dart';
import '../../../core/models/checkpoint.dart';

/// Widget to display checkpoint status and allow interaction
class CheckpointStatusIndicator extends StatelessWidget {
  final List<Checkpoint>? checkpoints;
  final Checkpoint? checkpoint;
  final bool isVisited;
  final bool isCurrent;
  final bool isNext;
  final VoidCallback? onTap;
  final bool showScanButton;
  final bool compact;

  const CheckpointStatusIndicator({
    super.key,
    this.checkpoints,
    this.checkpoint,
    this.isVisited = false,
    this.isCurrent = false,
    this.isNext = false,
    this.onTap,
    this.showScanButton = false,
    this.compact = false,
  }) : assert(checkpoints != null || checkpoint != null, 'Either checkpoints or checkpoint must be provided');

  @override
  Widget build(BuildContext context) {
    // If checkpoints list is provided, show progress overview
    if (checkpoints != null) {
      return _buildCheckpointListProgress(context);
    }
    
    // Otherwise show single checkpoint indicator
    return _buildSingleCheckpointIndicator(context);
  }

  Widget _buildCheckpointListProgress(BuildContext context) {
    final checkpointList = checkpoints!;
    final totalCheckpoints = checkpointList.length;
    final visitedCount = checkpointList.where((cp) => cp.lastVisitAt != null).length;
    final progress = totalCheckpoints > 0 ? visitedCount / totalCheckpoints : 0.0;

    if (compact) {
      return Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$visitedCount/$totalCheckpoints',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: progress == 1.0 ? Colors.green : Colors.blue,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route,
                color: progress == 1.0 ? Colors.green : Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Checkpoint Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$visitedCount/$totalCheckpoints',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: progress == 1.0 ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : Colors.blue,
            ),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1.0 
                ? 'All checkpoints completed!'
                : '${((1 - progress) * totalCheckpoints).round()} checkpoints remaining',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          
          // Show checkpoint icons
          if (totalCheckpoints <= 10) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: checkpointList.asMap().entries.map((entry) {
                final index = entry.key;
                final cp = entry.value;
                final isVisited = cp.lastVisitAt != null;
                
                return Tooltip(
                  message: cp.name,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isVisited ? Colors.green : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isVisited ? Colors.green.shade700 : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isVisited ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleCheckpointIndicator(BuildContext context) {
    final currentCheckpoint = checkpoint!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrent ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getBorderColor(),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Checkpoint info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentCheckpoint.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    
                    if (currentCheckpoint.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        currentCheckpoint.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Checkpoint details
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code,
                          size: 16,
                          color: currentCheckpoint.hasQRCode ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'QR',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentCheckpoint.hasQRCode ? Colors.green : Colors.grey,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Icon(
                          Icons.nfc,
                          size: 16,
                          color: currentCheckpoint.hasNFCTag ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'NFC',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentCheckpoint.hasNFCTag ? Colors.green : Colors.grey,
                          ),
                        ),
                        
                        if (currentCheckpoint.hasLocation) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'GPS',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Status text
                    if (isVisited || isCurrent || isNext) ...[
                      const SizedBox(height: 8),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action button
              if (showScanButton && (isCurrent || isNext)) ...[
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrent ? Theme.of(context).primaryColor : Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    isCurrent ? 'Scan Now' : 'Next',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ] else if (isVisited) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (isVisited) return Colors.green;
    if (isCurrent) return Colors.blue;
    if (isNext) return Colors.orange;
    return Colors.grey;
  }

  Color _getBorderColor() {
    if (isCurrent) return Colors.blue.shade300;
    return Colors.transparent;
  }

  IconData _getStatusIcon() {
    if (isVisited) return Icons.check;
    if (isCurrent) return Icons.my_location;
    if (isNext) return Icons.navigate_next;
    return Icons.place;
  }

  String _getStatusText() {
    if (isVisited) return 'Completed';
    if (isCurrent) return 'Current checkpoint';
    if (isNext) return 'Next checkpoint';
    return '';
  }
}

/// Mini checkpoint indicator for lists
class MiniCheckpointIndicator extends StatelessWidget {
  final bool isVisited;
  final bool isCurrent;
  final bool isNext;
  final double size;

  const MiniCheckpointIndicator({
    super.key,
    this.isVisited = false,
    this.isCurrent = false,
    this.isNext = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStatusColor(),
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? Colors.blue.shade300 : Colors.transparent,
          width: 2,
        ),
      ),
      child: Icon(
        _getStatusIcon(),
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  Color _getStatusColor() {
    if (isVisited) return Colors.green;
    if (isCurrent) return Colors.blue;
    if (isNext) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (isVisited) return Icons.check;
    if (isCurrent) return Icons.my_location;
    if (isNext) return Icons.navigate_next;
    return Icons.place;
  }
}

/// Checkpoint list for quick overview
class CheckpointList extends StatelessWidget {
  final List<Checkpoint> checkpoints;
  final List<int> visitedCheckpointIds;
  final int? currentCheckpointId;
  final int? nextCheckpointId;
  final Function(Checkpoint)? onCheckpointTap;

  const CheckpointList({
    super.key,
    required this.checkpoints,
    this.visitedCheckpointIds = const [],
    this.currentCheckpointId,
    this.nextCheckpointId,
    this.onCheckpointTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: checkpoints.length,
      itemBuilder: (context, index) {
        final checkpoint = checkpoints[index];
        final isVisited = visitedCheckpointIds.contains(checkpoint.id);
        final isCurrent = currentCheckpointId == checkpoint.id;
        final isNext = nextCheckpointId == checkpoint.id;

        return CheckpointStatusIndicator(
          checkpoint: checkpoint,
          isVisited: isVisited,
          isCurrent: isCurrent,
          isNext: isNext,
          onTap: () => onCheckpointTap?.call(checkpoint),
          showScanButton: true,
        );
      },
    );
  }
}

/// Horizontal checkpoint progress indicator
class HorizontalCheckpointProgress extends StatelessWidget {
  final List<Checkpoint> checkpoints;
  final List<int> visitedCheckpointIds;
  final int? currentCheckpointId;

  const HorizontalCheckpointProgress({
    super.key,
    required this.checkpoints,
    this.visitedCheckpointIds = const [],
    this.currentCheckpointId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: checkpoints.length,
        itemBuilder: (context, index) {
          final checkpoint = checkpoints[index];
          final isVisited = visitedCheckpointIds.contains(checkpoint.id);
          final isCurrent = currentCheckpointId == checkpoint.id;
          final isNext = !isVisited && !isCurrent && (index == 0 || visitedCheckpointIds.contains(checkpoints[index - 1].id));

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                MiniCheckpointIndicator(
                  isVisited: isVisited,
                  isCurrent: isCurrent,
                  isNext: isNext,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  checkpoint.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}