import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/incident.dart';
import '../../../core/providers/incident_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/role_based_widget.dart';
import '../../../core/constants/app_constants.dart';

/// Screen for viewing and managing incidents
class IncidentListScreen extends ConsumerStatefulWidget {
  const IncidentListScreen({super.key});

  @override
  ConsumerState<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends ConsumerState<IncidentListScreen> {
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedCategory;
  
  final List<String> _statusFilters = ['All', 'Open', 'In Progress', 'Resolved'];
  final List<String> _priorityFilters = ['All', 'Critical', 'High', 'Medium', 'Low'];
  final List<String> _categoryFilters = [
    'All',
    'Security Breach',
    'Suspicious Activity', 
    'Property Damage',
    'Safety Hazard',
    'Medical Emergency',
    'Fire/Smoke',
    'Equipment Malfunction',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIncidents();
    });
  }

  void _loadIncidents() {
    final authState = ref.read(authNotifierProvider);
    if (authState is Authenticated) {
      ref.read(incidentListProvider.notifier).refresh(
        status: _selectedStatus == 'All' ? null : _selectedStatus?.toLowerCase(),
        priority: _selectedPriority == 'All' ? null : _selectedPriority?.toLowerCase(),
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        siteId: authState.user.assignedSites?.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentListState = ref.watch(incidentListProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadIncidents,
            icon: const Icon(Icons.refresh),
          ),
          RoleBasedWidget(
            allowedRoles: const ['supervisor', 'site_manager', 'admin'],
            child: IconButton(
              onPressed: () => context.push(AppConstants.incidentReportRoute),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(),
          
          // Incidents List
          Expanded(
            child: _buildIncidentsList(incidentListState),
          ),
        ],
      ),
      floatingActionButton: RoleBasedWidget(
        allowedRoles: const ['guard', 'supervisor', 'site_manager', 'admin'],
        child: FloatingActionButton(
          onPressed: () => context.push(AppConstants.incidentReportRoute),
          backgroundColor: Colors.orange.shade600,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              Text(
                'Filter Incidents',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: _selectedStatus ?? 'All',
                  items: _statusFilters.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    _loadIncidents();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  value: _selectedPriority ?? 'All',
                  items: _priorityFilters.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                    _loadIncidents();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsList(IncidentListState state) {
    if (state.isLoading && state.incidents.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null && state.incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load incidents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadIncidents,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.incidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No incidents found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Incidents you report or are assigned to will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push(AppConstants.incidentReportRoute),
              icon: const Icon(Icons.add),
              label: const Text('Report Incident'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadIncidents(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.incidents.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.incidents.length) {
            // Load more indicator
            if (state.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(incidentListProvider.notifier).loadMore(
                        status: _selectedStatus == 'All' ? null : _selectedStatus?.toLowerCase(),
                        priority: _selectedPriority == 'All' ? null : _selectedPriority?.toLowerCase(),
                        category: _selectedCategory == 'All' ? null : _selectedCategory,
                      );
                    },
                    child: const Text('Load More'),
                  ),
                ),
              );
            }
          }

          final incident = state.incidents[index];
          return _buildIncidentCard(incident);
        },
      ),
    );
  }

  Widget _buildIncidentCard(Incident incident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/incident-detail/${incident.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority and status
              Row(
                children: [
                  _buildPriorityChip(incident.priority),
                  const SizedBox(width: 8),
                  _buildStatusChip(incident.status),
                  const Spacer(),
                  Text(
                    '#${incident.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                incident.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                incident.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Footer with category and date
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    incident.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(incident.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              
              // Location if available
              if (incident.latitude != null && incident.longitude != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Location: ${incident.latitude!.toStringAsFixed(4)}, ${incident.longitude!.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
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

  Widget _buildPriorityChip(String priority) {
    Color color;
    IconData icon;
    
    switch (priority.toLowerCase()) {
      case 'critical':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'high':
        color = Colors.orange;
        icon = Icons.priority_high;
        break;
      case 'medium':
        color = Colors.yellow.shade700;
        icon = Icons.circle;
        break;
      case 'low':
        color = Colors.green;
        icon = Icons.circle_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle_outlined;
    }

    return Chip(
      label: Text(
        priority.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: Icon(icon, color: Colors.white, size: 16),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'in_progress':
      case 'assigned':
        color = Colors.blue;
        icon = Icons.work;
        break;
      case 'open':
      case 'reported':
        color = Colors.orange;
        icon = Icons.report_problem;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: Icon(icon, color: Colors.white, size: 16),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}