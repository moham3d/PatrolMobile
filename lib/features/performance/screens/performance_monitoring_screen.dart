import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/performance_provider.dart';
import '../../../core/providers/intelligent_sync_provider.dart';

/// Performance monitoring and optimization screen
class PerformanceMonitoringScreen extends ConsumerStatefulWidget {
  const PerformanceMonitoringScreen({super.key});

  @override
  ConsumerState<PerformanceMonitoringScreen> createState() => _PerformanceMonitoringScreenState();
}

class _PerformanceMonitoringScreenState extends ConsumerState<PerformanceMonitoringScreen> {
  @override
  void initState() {
    super.initState();
    // Update metrics when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(performanceMetricsProvider.notifier).updateMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final performanceMetrics = ref.watch(performanceMetricsProvider);
    final batteryStatus = ref.watch(batteryStatusProvider);
    final memoryStatus = ref.watch(memoryStatusProvider);
    final locationStatus = ref.watch(locationStatusProvider);
    final syncStats = ref.watch(syncStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance & Battery'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(performanceMetricsProvider.notifier).updateMetrics();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh metrics',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Battery Status Card
            _buildBatteryStatusCard(context, performanceMetrics, batteryStatus),
            
            const SizedBox(height: 16),
            
            // Memory & Performance Card
            _buildPerformanceCard(context, performanceMetrics, memoryStatus),
            
            const SizedBox(height: 16),
            
            // Optimization Controls Card
            _buildOptimizationControlsCard(context, performanceMetrics),
            
            const SizedBox(height: 16),
            
            // Location Tracking Card
            _buildLocationTrackingCard(context, locationStatus),
            
            const SizedBox(height: 16),
            
            // Sync Status Card
            _buildSyncStatusCard(context, syncStats),
            
            const SizedBox(height: 16),
            
            // Intelligent Sync Card
            _buildIntelligentSyncCard(context),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryStatusCard(BuildContext context, PerformanceMetrics metrics, String batteryStatus) {
    final batteryColor = _getBatteryColor(metrics.batteryLevel);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getBatteryIcon(metrics.batteryLevel),
                  color: batteryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Battery Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        batteryStatus,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: batteryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (metrics.isLowPowerMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Low Power Mode',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: metrics.batteryLevel / 100.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '${metrics.batteryLevel}%',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: batteryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context, PerformanceMetrics metrics, String memoryStatus) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.memory,
                  color: Colors.blue.shade600,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Device Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Device Model', metrics.deviceModel),
            _buildInfoRow('Memory Usage', memoryStatus),
            _buildInfoRow('CPU Usage', '${metrics.cpuUsage.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationControlsCard(BuildContext context, PerformanceMetrics metrics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Colors.green.shade600,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Optimization Controls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Low Power Mode Toggle
            SwitchListTile(
              title: const Text('Low Power Mode'),
              subtitle: const Text('Reduces background activity to save battery'),
              value: metrics.isLowPowerMode,
              onChanged: (value) {
                ref.read(performanceMetricsProvider.notifier).toggleLowPowerMode(value);
              },
              secondary: Icon(
                Icons.power_settings_new,
                color: metrics.isLowPowerMode ? Colors.orange : Colors.grey,
              ),
            ),
            
            const Divider(),
            
            // Location Tracking Toggle
            SwitchListTile(
              title: const Text('Location Tracking'),
              subtitle: const Text('Enable GPS tracking for patrols and emergencies'),
              value: metrics.isLocationOptimized,
              onChanged: (value) {
                if (value) {
                  ref.read(performanceMetricsProvider.notifier).enableLocationTracking();
                } else {
                  ref.read(performanceMetricsProvider.notifier).disableLocationTracking();
                }
              },
              secondary: Icon(
                Icons.location_on,
                color: metrics.isLocationOptimized ? Colors.green : Colors.grey,
              ),
            ),
            
            const Divider(),
            
            // Background Sync Toggle
            SwitchListTile(
              title: const Text('Background Sync'),
              subtitle: const Text('Automatically sync data when connected'),
              value: metrics.isSyncOptimized,
              onChanged: (value) {
                if (value) {
                  ref.read(performanceMetricsProvider.notifier).enableBackgroundSync();
                } else {
                  ref.read(performanceMetricsProvider.notifier).disableBackgroundSync();
                }
              },
              secondary: Icon(
                Icons.sync,
                color: metrics.isSyncOptimized ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTrackingCard(BuildContext context, Map<String, dynamic> locationStatus) {
    final isEnabled = locationStatus['tracking_enabled'] as bool? ?? false;
    final lastUpdate = locationStatus['last_update'] as String?;
    final intervalSeconds = locationStatus['update_interval_seconds'] as int? ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isEnabled ? Colors.green.shade600 : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Location Tracking',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Status', isEnabled ? 'Active' : 'Disabled'),
            _buildInfoRow('Update Interval', '${intervalSeconds}s'),
            _buildInfoRow('Last Update', lastUpdate ?? 'Never'),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context, Map<String, dynamic> syncStats) {
    final isEnabled = syncStats['sync_enabled'] as bool? ?? false;
    final pendingOps = syncStats['pending_operations'] as int? ?? 0;
    final lastSync = syncStats['last_successful_sync'] as String?;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync,
                  color: isEnabled ? Colors.blue.shade600 : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Background Sync',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Status', isEnabled ? 'Active' : 'Disabled'),
            _buildInfoRow('Pending Operations', '$pendingOps'),
            _buildInfoRow('Last Sync', lastSync ?? 'Never'),
          ],
        ),
      ),
    );
  }

  Widget _buildIntelligentSyncCard(BuildContext context) {
    final syncStatistics = ref.watch(autoRefreshSyncStatisticsProvider);
    final syncControl = ref.watch(syncControlProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync_alt,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Intelligent Sync',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                syncStatistics.when(
                  data: (stats) {
                    final isOptimized = (stats['current_interval_minutes'] as int) > 15;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOptimized ? Colors.green.shade100 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOptimized ? 'Optimized' : 'Standard',
                        style: TextStyle(
                          color: isOptimized ? Colors.green.shade700 : Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => Icon(Icons.error, color: Colors.red.shade400, size: 16),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            syncStatistics.when(
              data: (stats) => Column(
                children: [
                  _buildSyncStatRow('Sync Interval', '${stats['current_interval_minutes']} minutes'),
                  _buildSyncStatRow('Battery Level', '${stats['battery_level']}%'),
                  _buildSyncStatRow('Low Power Mode', stats['is_low_power_mode'] ? 'Yes' : 'No'),
                  _buildSyncStatRow('Connectivity', _formatConnectivity(stats['connectivity'])),
                  _buildSyncStatRow('Status', stats['is_initialized'] ? 'Active' : 'Inactive'),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading sync stats: $error',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sync Control Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: syncControl.isLoading ? null : () {
                      ref.read(syncControlProvider.notifier).triggerSync(criticalOnly: true, reason: 'manual_critical');
                    },
                    icon: const Icon(Icons.priority_high),
                    label: const Text('Critical Sync'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: syncControl.isLoading ? null : () {
                      ref.read(syncControlProvider.notifier).triggerSync(reason: 'manual_full');
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Full Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            // Show sync control status
            syncControl.when(
              data: (message) => message != null ? Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(syncControlProvider.notifier).clearStatus(),
                        icon: Icon(Icons.close, size: 16, color: Colors.green.shade600),
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ) : const SizedBox.shrink(),
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Processing sync request...',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sync failed: $error',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(syncControlProvider.notifier).clearStatus(),
                        icon: Icon(Icons.close, size: 16, color: Colors.red.shade600),
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatConnectivity(dynamic connectivity) {
    if (connectivity == null) return 'Unknown';
    return connectivity.toString().split('.').last.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(performanceMetricsProvider.notifier).forceLocationUpdate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Updating location...')),
                  );
                },
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Update Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(performanceMetricsProvider.notifier).forceSync();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Syncing data...')),
                  );
                },
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Dashboard'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel > 50) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  IconData _getBatteryIcon(int batteryLevel) {
    if (batteryLevel > 80) return Icons.battery_full;
    if (batteryLevel > 60) return Icons.battery_6_bar;
    if (batteryLevel > 40) return Icons.battery_4_bar;
    if (batteryLevel > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }
}