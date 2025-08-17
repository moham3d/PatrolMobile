import 'package:flutter/material.dart';
import '../../../core/models/checkpoint.dart';

/// Widget to display checkpoint status and allow interaction
class CheckpointStatusIndicator extends StatelessWidget {
  final Checkpoint checkpoint;
  final bool isVisited;
  final bool isCurrent;
  final bool isNext;
  final VoidCallback? onTap;
  final bool showScanButton;

  const CheckpointStatusIndicator({
    super.key,
    required this.checkpoint,
    this.isVisited = false,
    this.isCurrent = false,
    this.isNext = false,
    this.onTap,
    this.showScanButton = false,
  });

  @override
  Widget build(BuildContext context) {
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
                      checkpoint.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    
                    if (checkpoint.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        checkpoint.description!,
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
                          color: checkpoint.hasQRCode ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'QR',
                          style: TextStyle(
                            fontSize: 12,
                            color: checkpoint.hasQRCode ? Colors.green : Colors.grey,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Icon(
                          Icons.nfc,
                          size: 16,
                          color: checkpoint.hasNFCTag ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'NFC',
                          style: TextStyle(
                            fontSize: 12,
                            color: checkpoint.hasNFCTag ? Colors.green : Colors.grey,
                          ),
                        ),
                        
                        if (checkpoint.hasLocation) ...[
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