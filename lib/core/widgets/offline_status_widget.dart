import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/offline_provider.dart';

/// Widget to display offline status and sync controls
class OfflineStatusWidget extends ConsumerWidget {
  final bool showDetails;
  final bool compact;

  const OfflineStatusWidget({
    super.key,
    this.showDetails = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityNotifierProvider);
    final syncState = ref.watch(syncNotifierProvider);
    final isOnline = ref.watch(isOnlineProvider);

    if (compact) {
      return _buildCompactStatus(context, isOnline, syncState);
    }

    return _buildDetailedStatus(context, ref, connectivityState, syncState, isOnline);
  }

  Widget _buildCompactStatus(BuildContext context, bool isOnline, SyncState syncState) {
    final Color statusColor = isOnline ? Colors.green : Colors.red;
    final IconData statusIcon = isOnline ? Icons.cloud_done : Icons.cloud_off;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (syncState is SyncInProgress) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedStatus(
    BuildContext context,
    WidgetRef ref,
    ConnectivityState connectivityState,
    SyncState syncState,
    bool isOnline,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connection Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _refreshConnectivity(ref),
                  tooltip: 'Check connectivity',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Connectivity status
            _buildConnectivityRow(context, connectivityState),
            
            const SizedBox(height: 8),
            
            // Sync status
            _buildSyncRow(context, syncState),
            
            const SizedBox(height: 16),
            
            // Offline queue stats
            Consumer(
              builder: (context, ref, child) {
                final queueStatsAsync = ref.watch(offlineQueueStatsProvider);
                
                return queueStatsAsync.when(
                  data: (stats) => _buildQueueStats(context, stats),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error loading stats: $e'),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            _buildActionButtons(context, ref, isOnline, syncState),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityRow(BuildContext context, ConnectivityState state) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (state) {
      case ConnectivityOnline():
        statusText = 'Online';
        statusColor = Colors.green;
        statusIcon = Icons.wifi;
        break;
      case ConnectivityOffline():
        statusText = 'Offline';
        statusColor = Colors.red;
        statusIcon = Icons.wifi_off;
        break;
      case ConnectivityChecking():
        statusText = 'Checking...';
        statusColor = Colors.orange;
        statusIcon = Icons.wifi_find;
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Text(
          'Network: $statusText',
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncRow(BuildContext context, SyncState state) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (state) {
      case SyncIdle():
        statusText = 'Idle';
        statusColor = Colors.grey;
        statusIcon = Icons.sync;
        break;
      case SyncInProgress():
        statusText = 'Syncing...';
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case SyncCompleted(:final syncedItems, :final completedAt):
        statusText = 'Completed ($syncedItems items)';
        statusColor = Colors.green;
        statusIcon = Icons.sync_alt;
        break;
      case SyncError(:final message):
        statusText = 'Error: $message';
        statusColor = Colors.red;
        statusIcon = Icons.sync_problem;
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Sync: $statusText',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (state is SyncInProgress)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildQueueStats(BuildContext context, Map<String, dynamic> stats) {
    final pendingVisits = stats['pending_visits'] ?? 0;
    final pendingActions = stats['pending_actions'] ?? 0;
    final failedVisits = stats['failed_visits'] ?? 0;
    final failedActions = stats['failed_actions'] ?? 0;
    
    final totalPending = pendingVisits + pendingActions;
    final totalFailed = failedVisits + failedActions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offline Queue',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            _buildStatChip(
              context,
              'Pending',
              totalPending.toString(),
              Colors.orange,
              Icons.schedule,
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              context,
              'Failed',
              totalFailed.toString(),
              Colors.red,
              Icons.error,
            ),
          ],
        ),
        
        if (totalPending > 0 || totalFailed > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Checkpoint visits: $pendingVisits pending, $failedVisits failed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Patrol actions: $pendingActions pending, $failedActions failed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    bool isOnline,
    SyncState syncState,
  ) {
    final isSyncing = syncState is SyncInProgress;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isOnline && !isSyncing
                ? () => _triggerSync(ref)
                : null,
            icon: Icon(
              isSyncing ? Icons.sync : Icons.sync_alt,
            ),
            label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isOnline ? () => _downloadOfflineData(ref) : null,
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ),
      ],
    );
  }

  void _refreshConnectivity(WidgetRef ref) {
    ref.read(connectivityNotifierProvider.notifier).checkConnectivity();
  }

  void _triggerSync(WidgetRef ref) {
    ref.read(syncNotifierProvider.notifier).triggerSync();
  }

  void _downloadOfflineData(WidgetRef ref) {
    ref.read(syncNotifierProvider.notifier).downloadOfflineData();
  }
}

/// Simple offline indicator for app bars
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    
    if (isOnline) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}