import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/checkpoint.dart';
import '../../../core/models/patrol_simple.dart';
import '../../../core/providers/patrol_provider.dart';

/// Enhanced checkpoint management widget with comprehensive status tracking
class EnhancedCheckpointManager extends ConsumerStatefulWidget {
  final int patrolId;
  final List<Checkpoint> checkpoints;
  final PatrolProgress? progress;
  final bool isInteractive;
  final Function(Checkpoint)? onCheckpointTap;

  const EnhancedCheckpointManager({
    super.key,
    required this.patrolId,
    required this.checkpoints,
    this.progress,
    this.isInteractive = true,
    this.onCheckpointTap,
  });

  @override
  ConsumerState<EnhancedCheckpointManager> createState() => _EnhancedCheckpointManagerState();
}

class _EnhancedCheckpointManagerState extends ConsumerState<EnhancedCheckpointManager> {
  String _selectedFilter = 'all';
  bool _showOnlyPending = false;

  @override
  Widget build(BuildContext context) {
    final filteredCheckpoints = _getFilteredCheckpoints();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with statistics
        _buildCheckpointHeader(),
        
        const SizedBox(height: 16),
        
        // Filter options
        _buildFilterSection(),
        
        const SizedBox(height: 16),
        
        // Progress indicator
        if (widget.progress != null) _buildProgressIndicator(),
        
        const SizedBox(height: 16),
        
        // Checkpoint list
        Expanded(
          child: _buildCheckpointList(filteredCheckpoints),
        ),
      ],
    );
  }

  Widget _buildCheckpointHeader() {
    final totalCheckpoints = widget.checkpoints.length;
    final visitedCount = widget.progress?.visitedCheckpoints ?? 0;
    final progressPercentage = widget.progress?.completionPercentage ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Checkpoint Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$visitedCount / $totalCheckpoints',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercentage / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${progressPercentage.toStringAsFixed(1)}% Complete',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildFilterChip('All', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Visited', 'visited'),
              const SizedBox(width: 8),
              _buildFilterChip('Pending', 'pending'),
            ],
          ),
        ),
        Switch(
          value: _showOnlyPending,
          onChanged: (value) {
            setState(() {
              _showOnlyPending = value;
            });
          },
        ),
        const Text('Pending Only'),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = widget.progress!;
    final nextCheckpoint = progress.nextCheckpoint;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.navigation, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text(
                'Next Checkpoint',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          if (nextCheckpoint != null) ...[
            const SizedBox(height: 8),
            Text(
              nextCheckpoint.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (nextCheckpoint.description != null) ...[
              const SizedBox(height: 4),
              Text(
                nextCheckpoint.description!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'All checkpoints completed!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckpointList(List<Checkpoint> checkpoints) {
    if (checkpoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No checkpoints found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: checkpoints.length,
      itemBuilder: (context, index) {
        final checkpoint = checkpoints[index];
        return _buildCheckpointCard(checkpoint, index);
      },
    );
  }

  Widget _buildCheckpointCard(Checkpoint checkpoint, int index) {
    final isVisited = _isCheckpointVisited(checkpoint);
    final isCurrent = _isCurrentCheckpoint(checkpoint);
    final isNext = _isNextCheckpoint(checkpoint);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrent ? 4 : 1,
      child: InkWell(
        onTap: widget.isInteractive 
            ? () => widget.onCheckpointTap?.call(checkpoint)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isCurrent 
                ? Border.all(color: Colors.blue, width: 2)
                : isNext
                    ? Border.all(color: Colors.orange, width: 1)
                    : null,
          ),
          child: Row(
            children: [
              // Status indicator
              _buildStatusIndicator(checkpoint, isVisited, isCurrent, isNext),
              
              const SizedBox(width: 16),
              
              // Checkpoint info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            checkpoint.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isVisited ? Colors.green.shade700 : null,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isNext && !isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEXT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    if (checkpoint.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        checkpoint.description!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Checkpoint details
                    Row(
                      children: [
                        if (checkpoint.hasQRCode)
                          _buildDetailChip(Icons.qr_code, 'QR', Colors.blue),
                        if (checkpoint.hasNFCTag)
                          _buildDetailChip(Icons.nfc, 'NFC', Colors.purple),
                        if (checkpoint.hasLocation)
                          _buildDetailChip(Icons.location_on, 'GPS', Colors.green),
                      ],
                    ),
                    
                    if (isVisited && checkpoint.lastVisitAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last visited: ${_formatVisitTime(checkpoint.lastVisitAt!)}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action button
              if (widget.isInteractive && (isCurrent || isNext))
                IconButton(
                  onPressed: () => _showScanOptions(checkpoint),
                  icon: const Icon(Icons.qr_code_scanner),
                  color: Colors.blue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Checkpoint checkpoint, bool isVisited, bool isCurrent, bool isNext) {
    if (isVisited) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 24,
        ),
      );
    } else if (isCurrent) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.blue,
          size: 24,
        ),
      );
    } else if (isNext) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: const Icon(
          Icons.schedule,
          color: Colors.orange,
          size: 24,
        ),
      );
    } else {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.circle,
          color: Colors.grey.shade400,
          size: 24,
        ),
      );
    }
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Checkpoint> _getFilteredCheckpoints() {
    List<Checkpoint> filtered = widget.checkpoints;
    
    switch (_selectedFilter) {
      case 'visited':
        filtered = filtered.where((cp) => _isCheckpointVisited(cp)).toList();
        break;
      case 'pending':
        filtered = filtered.where((cp) => !_isCheckpointVisited(cp)).toList();
        break;
    }
    
    if (_showOnlyPending) {
      filtered = filtered.where((cp) => !_isCheckpointVisited(cp)).toList();
    }
    
    return filtered;
  }

  bool _isCheckpointVisited(Checkpoint checkpoint) {
    // Check if checkpoint has been visited based on lastVisitAt or progress data
    return checkpoint.lastVisitAt != null;
  }

  bool _isCurrentCheckpoint(Checkpoint checkpoint) {
    return widget.progress?.currentCheckpoint?.id == checkpoint.id;
  }

  bool _isNextCheckpoint(Checkpoint checkpoint) {
    return widget.progress?.nextCheckpoint?.id == checkpoint.id;
  }

  String _formatVisitTime(String visitTime) {
    try {
      final dateTime = DateTime.parse(visitTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return visitTime;
    }
  }

  void _showScanOptions(Checkpoint checkpoint) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan ${checkpoint.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            if (checkpoint.hasQRCode)
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.blue),
                title: const Text('Scan QR Code'),
                onTap: () {
                  Navigator.of(context).pop();
                  _scanQRCode(checkpoint);
                },
              ),
            
            if (checkpoint.hasNFCTag)
              ListTile(
                leading: const Icon(Icons.nfc, color: Colors.purple),
                title: const Text('Scan NFC Tag'),
                onTap: () {
                  Navigator.of(context).pop();
                  _scanNFCTag(checkpoint);
                },
              ),
            
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Manual Entry'),
              onTap: () {
                Navigator.of(context).pop();
                _manualEntry(checkpoint);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scanQRCode(Checkpoint checkpoint) {
    // Navigate to QR scanner or trigger scan
    // This would integrate with the existing checkpoint scanner
  }

  void _scanNFCTag(Checkpoint checkpoint) {
    // Navigate to NFC scanner or trigger scan
    // This would integrate with the existing checkpoint scanner
  }

  void _manualEntry(Checkpoint checkpoint) {
    // Show manual entry dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual Entry: ${checkpoint.name}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to manually mark this checkpoint as visited?'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Process manual entry
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}