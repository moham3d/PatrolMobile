import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/patrol_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/patrol_simple.dart';
import '../../../core/widgets/role_based_widget.dart';
import '../widgets/patrol_card.dart';
import '../widgets/patrol_progress_indicator.dart';
import '../widgets/patrol_search_bar.dart';

/// Enhanced patrol dashboard with comprehensive patrol management
class EnhancedPatrolDashboard extends ConsumerStatefulWidget {
  const EnhancedPatrolDashboard({super.key});

  @override
  ConsumerState<EnhancedPatrolDashboard> createState() => _EnhancedPatrolDashboardState();
}

class _EnhancedPatrolDashboardState extends ConsumerState<EnhancedPatrolDashboard> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _searchQuery;
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatrolData();
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPatrolData() {
    final authState = ref.read(authNotifierProvider);
    if (authState is! Authenticated) return;

    final user = authState.user;
    
    // Load different data based on user role
    if (user.canAccess('supervisor') || user.canAccess('site manager')) {
      // Supervisors and managers can see all patrols
      ref.read(patrolListProvider.notifier).loadActivePatrols();
    } else {
      // Guards see only their assigned patrols
      ref.read(patrolListProvider.notifier).loadAssignedPatrols();
    }
    
    // Load statistics and history
    ref.read(patrolStatsProvider.notifier).loadStatistics();
    ref.read(patrolHistoryProvider.notifier).loadMyHistory(limit: 20);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      // Handle location error silently
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    if (query.isEmpty) {
      _loadPatrolData();
    } else {
      ref.read(patrolListProvider.notifier).searchPatrols(
        query: query,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _applyFilters();
  }

  void _onPriorityChanged(String priority) {
    setState(() {
      _selectedPriority = priority;
    });
    _applyFilters();
  }

  void _applyFilters() {
    if (_searchQuery?.isEmpty ?? true) {
      _loadPatrolData();
    } else {
      _onSearch(_searchQuery!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view patrols'),
        ),
      );
    }

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrol Management'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(icon: Icon(Icons.assignment), text: 'Active'),
            Tab(
              icon: Icon(user.canAccess('supervisor') ? Icons.dashboard : Icons.history),
              text: user.canAccess('supervisor') ? 'Monitor' : 'History',
            ),
            const Tab(icon: Icon(Icons.map), text: 'Routes'),
            const Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatrolData,
          ),
          RoleBasedWidget(
            allowedRoles: const ['supervisor', 'site manager', 'admin'],
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/patrols/create'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            color: Colors.blue.shade700,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: PatrolSearchBar(
                    onSearch: _onSearch,
                    hintText: 'Search patrols...',
                  ),
                ),
                // Filter chips
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip('Status', _selectedStatus, [
                              'all', 'pending', 'in_progress', 'completed', 'cancelled'
                            ], _onStatusChanged),
                            const SizedBox(width: 8),
                            _buildFilterChip('Priority', _selectedPriority, [
                              'all', 'low', 'normal', 'high', 'urgent'
                            ], _onPriorityChanged),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivePatrolsTab(),
                _buildMonitoringTab(user),
                _buildRoutesTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(user),
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options, Function(String) onChanged) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      child: Chip(
        label: Text('$label: ${selected.toUpperCase()}'),
        backgroundColor: Colors.white24,
        labelStyle: const TextStyle(color: Colors.white),
        avatar: const Icon(Icons.filter_list, color: Colors.white, size: 16),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Text(option.toUpperCase()),
        );
      }).toList(),
    );
  }

  Widget _buildActivePatrolsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final patrolListState = ref.watch(patrolListProvider);
        
        return switch (patrolListState) {
          PatrolListInitial() => const Center(
            child: Text('Loading patrols...'),
          ),
          PatrolListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PatrolListLoaded(:final patrols) => _buildPatrolList(patrols, 'active'),
          PatrolListError(:final message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error: $message'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadPatrolData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        };
      },
    );
  }

  Widget _buildMonitoringTab(User user) {
    if (user.canAccess('supervisor')) {
      return Consumer(
        builder: (context, ref, child) {
          final patrolListState = ref.watch(patrolListProvider);
          
          return switch (patrolListState) {
            PatrolListLoaded(:final patrols) => _buildMonitoringView(patrols),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      );
    } else {
      // History view for guards
      return Consumer(
        builder: (context, ref, child) {
          final historyState = ref.watch(patrolHistoryProvider);
          
          return switch (historyState) {
            PatrolHistoryLoaded(:final history) => _buildHistoryList(history),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      );
    }
  }

  Widget _buildRoutesTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Interactive Map View'),
              subtitle: const Text('View patrol routes and checkpoints'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.push('/patrols/map'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final patrolListState = ref.watch(patrolListProvider);
                
                return switch (patrolListState) {
                  PatrolListLoaded(:final patrols) => _buildRoutesList(patrols),
                  _ => const Center(child: CircularProgressIndicator()),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statsState = ref.watch(patrolStatsProvider);
        
        return switch (statsState) {
          PatrolStatsLoaded(:final stats) => _buildStatsView(stats),
          _ => const Center(child: CircularProgressIndicator()),
        };
      },
    );
  }

  Widget _buildPatrolList(List<Patrol> patrols, String type) {
    if (patrols.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No ${type} patrols found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Patrols will appear here when assigned'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadPatrolData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: patrols.length,
        itemBuilder: (context, index) {
          final patrol = patrols[index];
          return PatrolCard(
            patrol: patrol,
            showProgress: true,
            onTap: () => context.push('/patrols/${patrol.id}'),
          );
        },
      ),
    );
  }

  Widget _buildMonitoringView(List<Patrol> patrols) {
    final activePatrols = patrols.where((p) => p.status == 'in_progress').toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Active Patrols',
                  activePatrols.length.toString(),
                  Icons.assignment,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Today',
                  patrols.length.toString(),
                  Icons.today,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Active patrols list
          Text(
            'Active Patrols',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (activePatrols.isEmpty)
            const Center(
              child: Text('No active patrols at the moment'),
            )
          else
            ...activePatrols.map((patrol) => PatrolCard(
              patrol: patrol,
              showProgress: true,
              onTap: () => context.push('/patrols/${patrol.id}'),
            )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<dynamic> history) {
    if (history.isEmpty) {
      return const Center(
        child: Text('No patrol history found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(entry.status),
              child: Icon(
                _getStatusIcon(entry.status),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(entry.patrolTitle),
            subtitle: Text(
              '${entry.formattedDuration} • ${entry.checkpointsVisited}/${entry.totalCheckpoints} checkpoints',
            ),
            trailing: Text(
              '${(entry.completionPercentage).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => context.push('/patrols/history/${entry.id}'),
          ),
        );
      },
    );
  }

  Widget _buildRoutesList(List<Patrol> patrols) {
    return ListView.builder(
      itemCount: patrols.length,
      itemBuilder: (context, index) {
        final patrol = patrols[index];
        final checkpointCount = patrol.checkpoints?.length ?? 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.route, color: Colors.white),
            ),
            title: Text(patrol.title),
            subtitle: Text('$checkpointCount checkpoints'),
            trailing: const Icon(Icons.map),
            onTap: () => context.push('/patrols/map/${patrol.id}'),
          ),
        );
      },
    );
  }

  Widget _buildStatsView(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('Completed', stats['completed']?.toString() ?? '0', Colors.green),
              _buildStatCard('In Progress', stats['in_progress']?.toString() ?? '0', Colors.blue),
              _buildStatCard('Average Time', stats['avg_duration']?.toString() ?? 'N/A', Colors.orange),
              _buildStatCard('Success Rate', '${stats['success_rate']?.toString() ?? '0'}%', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(User user) {
    if (user.isGuard) {
      return FloatingActionButton.extended(
        onPressed: () => context.push('/checkpoints/scanner'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Checkpoint'),
        backgroundColor: Colors.orange,
      );
    } else if (user.canAccess('supervisor')) {
      return FloatingActionButton(
        onPressed: () => context.push('/patrols/map'),
        child: const Icon(Icons.map),
        backgroundColor: Colors.blue,
      );
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}