import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/emergency_provider.dart';
import '../../../core/models/emergency.dart';
import '../../../core/widgets/role_based_widget.dart';

/// Emergency history screen showing all past emergency alerts
class EmergencyHistoryScreen extends ConsumerStatefulWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  ConsumerState<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState extends ConsumerState<EmergencyHistoryScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load emergency history when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyAlertsProvider.notifier).loadAlerts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergencyState = ref.watch(emergencyAlertsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency History'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          if (_searchQuery.isNotEmpty || _selectedStatus != 'all')
            _buildActiveFiltersBar(),
          
          // Content
          Expanded(
            child: _buildBody(context, emergencyState),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          if (_searchQuery.isNotEmpty) ...[
            Chip(
              label: Text('Search: "$_searchQuery"'),
              onDeleted: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
                _applyFilters();
              },
            ),
            const SizedBox(width: 8),
          ],
          if (_selectedStatus != 'all') ...[
            Chip(
              label: Text('Status: ${_selectedStatus.toUpperCase()}'),
              onDeleted: () {
                setState(() {
                  _selectedStatus = 'all';
                });
                _applyFilters();
              },
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedStatus = 'all';
                _searchController.clear();
              });
              _applyFilters();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, EmergencyAlertsState state) {
    if (state is Loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is EmergencyError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(emergencyAlertsProvider.notifier).loadAlerts(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is Loaded) {
      final alerts = _filterAlerts(state.alerts);
      
      if (alerts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Emergency History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'No emergency alerts match your criteria',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async => ref.read(emergencyAlertsProvider.notifier).loadAlerts(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _buildHistoryCard(context, alert);
          },
        ),
      );
    }

    return const Center(
      child: Text('No history loaded'),
    );
  }

  Widget _buildHistoryCard(BuildContext context, EmergencyAlert alert) {
    final severityColor = _getSeverityColor(alert.severity);
    final statusColor = _getStatusColor(alert.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAlertDetails(context, alert),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status and severity
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alert.severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alert.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getAlertTypeIcon(alert.alertType),
                    size: 16,
                    color: severityColor,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Alert description
              Text(
                alert.description ?? 'No description available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Metadata row
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(alert.triggeredAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    alert.userName ?? 'User #${alert.userId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (alert.locationName != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alert.locationName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Resolution information if resolved
              if (alert.isResolved) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Resolved',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (alert.resolvedAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTime(alert.resolvedAt!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<EmergencyAlert> _filterAlerts(List<EmergencyAlert> alerts) {
    var filtered = alerts;
    
    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered.where((alert) => alert.status.toLowerCase() == _selectedStatus).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((alert) =>
        (alert.description?.toLowerCase().contains(query) ?? false) ||
        alert.alertType.toLowerCase().contains(query) ||
        alert.severity.toLowerCase().contains(query) ||
        (alert.userName?.toLowerCase().contains(query) ?? false) ||
        (alert.locationName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    // Sort by triggered date (newest first)
    filtered.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    
    return filtered;
  }

  void _applyFilters() {
    // Trigger rebuild to apply filters
    setState(() {});
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Emergency History'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search terms',
            hintText: 'Enter description, user, location...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text.trim();
              });
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'all',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
                Navigator.of(context).pop();
                _applyFilters();
              },
              title: const Text('All Alerts'),
            ),
            RadioListTile<String>(
              value: 'active',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
                Navigator.of(context).pop();
                _applyFilters();
              },
              title: const Text('Active'),
            ),
            RadioListTile<String>(
              value: 'acknowledged',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
                Navigator.of(context).pop();
                _applyFilters();
              },
              title: const Text('Acknowledged'),
            ),
            RadioListTile<String>(
              value: 'resolved',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
                Navigator.of(context).pop();
                _applyFilters();
              },
              title: const Text('Resolved'),
            ),
            RadioListTile<String>(
              value: 'cancelled',
              groupValue: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
                Navigator.of(context).pop();
                _applyFilters();
              },
              title: const Text('Cancelled'),
            ),
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

  void _showAlertDetails(BuildContext context, EmergencyAlert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmergencyHistoryDetailSheet(alert: alert),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.red.shade500;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red.shade600;
      case 'acknowledged':
        return Colors.orange.shade600;
      case 'resolved':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getAlertTypeIcon(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'sos':
        return Icons.emergency;
      case 'panic':
        return Icons.warning;
      case 'medical':
        return Icons.medical_services;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.notification_important;
    }
  }

  String _formatDateTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}

/// Bottom sheet showing detailed emergency alert history information
class EmergencyHistoryDetailSheet extends StatelessWidget {
  final EmergencyAlert alert;
  
  const EmergencyHistoryDetailSheet({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(
                _getAlertTypeIcon(alert.alertType),
                color: _getSeverityColor(alert.severity),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Emergency Alert #${alert.id}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildDetailRow(context, 'Type', alert.alertType.toUpperCase()),
          _buildDetailRow(context, 'Severity', alert.severity.toUpperCase()),
          _buildDetailRow(context, 'Status', alert.status.toUpperCase()),
          _buildDetailRow(context, 'Description', alert.description ?? 'No description available'),
          _buildDetailRow(context, 'User', alert.userName ?? 'User #${alert.userId}'),
          _buildDetailRow(context, 'Triggered At', _formatFullDateTime(alert.triggeredAt)),
          
          if (alert.acknowledgedAt != null) ...[
            _buildDetailRow(context, 'Acknowledged At', _formatFullDateTime(alert.acknowledgedAt!)),
            if (alert.acknowledgedBy != null)
              _buildDetailRow(context, 'Acknowledged By', 'User #${alert.acknowledgedBy}'),
          ],
          
          if (alert.resolvedAt != null) ...[
            _buildDetailRow(context, 'Resolved At', _formatFullDateTime(alert.resolvedAt!)),
            if (alert.resolvedBy != null)
              _buildDetailRow(context, 'Resolved By', 'User #${alert.resolvedBy}'),
          ],
          
          if (alert.latitude != null && alert.longitude != null) ...[
            const SizedBox(height: 16),
            Text(
              'Location Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Location Name', alert.locationName ?? 'Unknown'),
            _buildDetailRow(context, 'Coordinates', 
              '${alert.latitude!.toStringAsFixed(6)}, ${alert.longitude!.toStringAsFixed(6)}'),
          ],
          
          const SizedBox(height: 24),
          
          // Actions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.red.shade500;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getAlertTypeIcon(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'sos':
        return Icons.emergency;
      case 'panic':
        return Icons.warning;
      case 'medical':
        return Icons.medical_services;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.notification_important;
    }
  }

  String _formatFullDateTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}