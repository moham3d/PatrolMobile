import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/patrol_provider.dart';
import '../../../core/models/patrol_simple.dart';
import '../../../core/models/checkpoint.dart';
import '../widgets/patrol_progress_indicator.dart';
import '../widgets/checkpoint_status_indicator.dart';
import '../widgets/patrol_action_buttons.dart';

/// Detailed patrol screen showing route, checkpoints, and progress
class PatrolDetailScreen extends ConsumerStatefulWidget {
  final String patrolId;
  final String? action; // 'start', 'end', etc.

  const PatrolDetailScreen({
    super.key,
    required this.patrolId,
    this.action,
  });

  @override
  ConsumerState<PatrolDetailScreen> createState() => _PatrolDetailScreenState();
}

class _PatrolDetailScreenState extends ConsumerState<PatrolDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load patrol data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatrolData();
      _handleAction();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPatrolData() {
    final patrolId = int.tryParse(widget.patrolId);
    if (patrolId != null) {
      ref.read(currentPatrolProvider.notifier).loadPatrol(patrolId);
    }
  }

  void _handleAction() {
    if (widget.action == 'start') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStartPatrolDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final patrolState = ref.watch(currentPatrolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrol Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Route'),
            Tab(icon: Icon(Icons.flag), text: 'Checkpoints'),
            Tab(icon: Icon(Icons.analytics), text: 'Progress'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatrolData,
          ),
        ],
      ),
      body: switch (patrolState) {
        CurrentPatrolInitial() => const Center(
          child: Text('Ready to load patrol'),
        ),
        CurrentPatrolLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        CurrentPatrolLoaded(:final patrol, :final route, :final progress) =>
          _buildPatrolContent(patrol, route, progress),
        CurrentPatrolError(:final message) => Center(
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

  Widget _buildPatrolContent(Patrol patrol, PatrolRoute route, PatrolProgress progress) {
    return Column(
      children: [
        // Patrol header with basic info
        _buildPatrolHeader(patrol, progress),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRouteTab(route, progress),
              _buildCheckpointsTab(route.checkpoints, progress),
              _buildProgressTab(patrol, progress),
            ],
          ),
        ),
        
        // Action buttons at bottom
        _buildActionBar(patrol, progress),
      ],
    );
  }

  Widget _buildPatrolHeader(Patrol patrol, PatrolProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  patrol.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(patrol.status),
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
          
          const SizedBox(height: 12),
          
          // Progress indicator
          CheckpointProgressIndicator(
            visitedCheckpoints: progress.visitedCheckpoints,
            totalCheckpoints: progress.totalCheckpoints,
          ),
          
          const SizedBox(height: 12),
          
          // Info row
          Row(
            children: [
              if (patrol.siteName != null) ...[
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  patrol.siteName!,
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
              
              if (progress.isStarted) ...[
                Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Started',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTab(PatrolRoute route, PatrolProgress progress) {
    if (!route.checkpoints.any((c) => c.hasLocation)) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No location data available for route display'),
          ],
        ),
      );
    }

    final checkpointsWithLocation = route.checkpoints.where((c) => c.hasLocation).toList();
    final center = _calculateMapCenter(checkpointsWithLocation);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.patrol_shield_mobile',
        ),
        MarkerLayer(
          markers: checkpointsWithLocation.map((checkpoint) {
            final isVisited = progress.recentVisits?.any((v) => v.checkpointId == checkpoint.id) ?? false;
            final isCurrent = progress.currentCheckpoint?.id == checkpoint.id;
            final isNext = progress.nextCheckpoint?.id == checkpoint.id;
            
            return Marker(
              point: LatLng(checkpoint.latitude!, checkpoint.longitude!),
              child: GestureDetector(
                onTap: () => _showCheckpointDetails(checkpoint),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCheckpointMarkerColor(isVisited, isCurrent, isNext),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCheckpointMarkerIcon(isVisited, isCurrent, isNext),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (route.optimizedCheckpoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route.optimizedCheckpoints
                    .where((c) => c.hasLocation)
                    .map((c) => LatLng(c.latitude!, c.longitude!))
                    .toList(),
                color: Theme.of(context).primaryColor,
                strokeWidth: 3.0,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildCheckpointsTab(List<Checkpoint> checkpoints, PatrolProgress progress) {
    if (checkpoints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No checkpoints assigned to this patrol'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: checkpoints.length,
      itemBuilder: (context, index) {
        final checkpoint = checkpoints[index];
        final isVisited = progress.recentVisits?.any((v) => v.checkpointId == checkpoint.id) ?? false;
        final isCurrent = progress.currentCheckpoint?.id == checkpoint.id;
        final isNext = progress.nextCheckpoint?.id == checkpoint.id;
        
        return CheckpointStatusIndicator(
          checkpoint: checkpoint,
          isVisited: isVisited,
          isCurrent: isCurrent,
          isNext: isNext,
          onTap: () => _handleCheckpointTap(checkpoint),
          showScanButton: true,
        );
      },
    );
  }

  Widget _buildProgressTab(Patrol patrol, PatrolProgress progress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Progress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  CircularPatrolProgressIndicator(
                    progress: progress.completionPercentage / 100,
                    size: 80,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProgressStat(
                        'Checkpoints',
                        '${progress.visitedCheckpoints}/${progress.totalCheckpoints}',
                        Icons.flag,
                      ),
                      _buildProgressStat(
                        'Status',
                        patrol.status.replaceAll('_', ' ').toUpperCase(),
                        Icons.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent activity
          if (progress.recentVisits?.isNotEmpty ?? false) ...[
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            ...progress.recentVisits!.map((visit) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getScanMethodIcon(visit.scanMethod),
                  color: Colors.green,
                ),
                title: Text(visit.checkpointName ?? 'Checkpoint #${visit.checkpointId}'),
                subtitle: Text(
                  'Scanned via ${visit.scanMethod.toUpperCase()} • ${_formatDateTime(visit.visitedAt)}',
                ),
                trailing: visit.isSynced 
                  ? const Icon(Icons.cloud_done, color: Colors.green)
                  : const Icon(Icons.cloud_upload, color: Colors.orange),
              ),
            )),
          ],
          
          const SizedBox(height: 16),
          
          // Next actions
          if (progress.nextCheckpoint != null) ...[
            Text(
              'Next Checkpoint',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.place, color: Colors.blue),
                title: Text(progress.nextCheckpoint!.name),
                subtitle: progress.nextCheckpoint!.description != null 
                  ? Text(progress.nextCheckpoint!.description!)
                  : null,
                trailing: ElevatedButton(
                  onPressed: () => context.push('/scanner'),
                  child: const Text('Scan'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(Patrol patrol, PatrolProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: PatrolActionButtons(
          patrol: patrol,
          progress: progress,
          onStartPatrol: _startPatrol,
          onEndPatrol: _endPatrol,
          onScanCheckpoint: () => context.push('/scanner'),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
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
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // Helper methods
  LatLng _calculateMapCenter(List<Checkpoint> checkpoints) {
    if (checkpoints.isEmpty) {
      return const LatLng(0, 0);
    }

    double sumLat = 0;
    double sumLng = 0;
    
    for (final checkpoint in checkpoints) {
      sumLat += checkpoint.latitude!;
      sumLng += checkpoint.longitude!;
    }
    
    return LatLng(
      sumLat / checkpoints.length,
      sumLng / checkpoints.length,
    );
  }

  Color _getCheckpointMarkerColor(bool isVisited, bool isCurrent, bool isNext) {
    if (isVisited) return Colors.green;
    if (isCurrent) return Colors.blue;
    if (isNext) return Colors.orange;
    return Colors.grey;
  }

  IconData _getCheckpointMarkerIcon(bool isVisited, bool isCurrent, bool isNext) {
    if (isVisited) return Icons.check;
    if (isCurrent) return Icons.my_location;
    if (isNext) return Icons.navigate_next;
    return Icons.place;
  }

  IconData _getScanMethodIcon(String method) {
    switch (method) {
      case 'qr':
        return Icons.qr_code;
      case 'nfc':
        return Icons.nfc;
      case 'manual':
        return Icons.edit;
      default:
        return Icons.scanner;
    }
  }

  String _formatDateTime(String dateTime) {
    final dt = DateTime.parse(dateTime);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showCheckpointDetails(Checkpoint checkpoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(checkpoint.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (checkpoint.description != null)
              Text(checkpoint.description!),
            const SizedBox(height: 8),
            Text('Code: ${checkpoint.code}'),
            if (checkpoint.hasQRCode)
              const Text('✓ QR Code available'),
            if (checkpoint.hasNFCTag)
              const Text('✓ NFC Tag available'),
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
              context.push('/scanner');
            },
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }

  void _handleCheckpointTap(Checkpoint checkpoint) {
    // Navigate to scanner or show checkpoint details
    context.push('/scanner?checkpoint=${checkpoint.id}');
  }

  void _showStartPatrolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Patrol'),
        content: const Text('Are you ready to start this patrol? Location data will be recorded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startPatrol();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPatrol() async {
    final patrolId = int.tryParse(widget.patrolId);
    if (patrolId == null) return;

    // Get current location for GPS tracking
    Position? currentLocation;
    try {
      currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Continue without location if permission denied or GPS unavailable
    }

    final success = await ref.read(currentPatrolProvider.notifier).startPatrol(
      patrolId,
      latitude: currentLocation?.latitude,
      longitude: currentLocation?.longitude,
      accuracy: currentLocation?.accuracy,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patrol started successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _endPatrol() async {
    final patrolId = int.tryParse(widget.patrolId);
    if (patrolId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Patrol'),
        content: const Text('Are you sure you want to end this patrol? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Patrol'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(currentPatrolProvider.notifier).endPatrol(
        patrolId,
        // latitude: currentLocation?.latitude,
        // longitude: currentLocation?.longitude,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patrol ended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    }
  }
}