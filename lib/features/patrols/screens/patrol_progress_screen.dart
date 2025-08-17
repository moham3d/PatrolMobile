import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/patrol_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/patrol_simple.dart';
import '../../../core/widgets/role_based_widget.dart';
import '../widgets/patrol_card.dart';
import '../widgets/patrol_progress_indicator.dart';
import '../widgets/patrol_search_bar.dart';

/// Screen showing patrol progress and checkpoint management
class PatrolProgressScreen extends ConsumerStatefulWidget {
  const PatrolProgressScreen({super.key});

  @override
  ConsumerState<PatrolProgressScreen> createState() => _PatrolProgressScreenState();
}

class _PatrolProgressScreenState extends ConsumerState<PatrolProgressScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _searchQuery;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatrolData();
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
      // Supervisors and managers can see all active patrols
      ref.read(patrolListProvider.notifier).loadActivePatrols();
    } else {
      // Guards see only their assigned patrols
      ref.read(patrolListProvider.notifier).loadAssignedPatrols();
    }
    
    // Load statistics and history
    ref.read(patrolStatsProvider.notifier).loadStatistics();
    ref.read(patrolHistoryProvider.notifier).loadMyHistory(limit: 10);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrol Progress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.route), text: 'Active'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
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
              icon: const Icon(Icons.map),
              onPressed: () => context.push('/patrol-map'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          PatrolSearchBar(
            onSearch: _onSearch,
            selectedStatus: _selectedStatus,
            onStatusChanged: _onStatusChanged,
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivePatrolsTab(),
                _buildHistoryTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(authState.user),
    );
  }

  Widget _buildActivePatrolsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final patrolListState = ref.watch(patrolListProvider);

        return switch (patrolListState) {
          PatrolListInitial() => const Center(
            child: Text('Ready to load patrols'),
          ),
          PatrolListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PatrolListLoaded(:final patrols) => _buildPatrolList(patrols),
          PatrolListError(:final message) => Center(
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
                  'Error loading patrols',
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
        };
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer(
      builder: (context, ref, child) {
        final historyState = ref.watch(patrolHistoryProvider);

        return switch (historyState) {
          PatrolHistoryInitial() => const Center(
            child: Text('Ready to load history'),
          ),
          PatrolHistoryLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PatrolHistoryLoaded(:final history) => _buildHistoryList(history),
          PatrolHistoryError(:final message) => Center(
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
                  'Error loading history',
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
                  onPressed: () => ref.read(patrolHistoryProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        };
      },
    );
  }

  Widget _buildStatsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final statsState = ref.watch(patrolStatsProvider);

        return switch (statsState) {
          PatrolStatsInitial() => const Center(
            child: Text('Ready to load statistics'),
          ),
          PatrolStatsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PatrolStatsLoaded(:final statistics) => _buildStatistics(statistics),
          PatrolStatsError(:final message) => Center(
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
                  'Error loading statistics',
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
                  onPressed: () => ref.read(patrolStatsProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        };
      },
    );
  }

  Widget _buildPatrolList(List<Patrol> patrols) {
    if (patrols.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No patrols found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new patrol assignments',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
            onTap: () => context.push('/patrol/${patrol.id}'),
            showProgress: true,
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(List<PatrolHistoryEntry> history) {
    if (history.isEmpty) {
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
              'No patrol history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some patrols to see your history',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(patrolHistoryProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final entry = history[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: entry.isCompleted 
                    ? Colors.green 
                    : entry.isInProgress 
                        ? Colors.orange 
                        : Colors.grey,
                child: Icon(
                  entry.isCompleted 
                      ? Icons.check 
                      : entry.isInProgress 
                          ? Icons.access_time 
                          : Icons.pause,
                  color: Colors.white,
                ),
              ),
              title: Text(entry.patrolTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Duration: ${entry.formattedDuration}'),
                  Text('Progress: ${entry.checkpointsVisited}/${entry.totalCheckpoints} checkpoints'),
                  PatrolProgressIndicator(
                    progress: entry.completionPercentage / 100,
                    height: 4,
                  ),
                ],
              ),
              trailing: Text(
                entry.startDateTime.toLocal().toString().split(' ')[0],
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => context.push('/patrol/${entry.patrolId}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> statistics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Patrol Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Statistics cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Patrols',
                  '${statistics['total_patrols'] ?? 0}',
                  Icons.route,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '${statistics['completed_patrols'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  '${statistics['active_patrols'] ?? 0}',
                  Icons.access_time,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Avg. Duration',
                  '${statistics['average_duration'] ?? 0}m',
                  Icons.timer,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Completion rate
          if (statistics['completion_rate'] != null) ...[
            Text(
              'Completion Rate',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (statistics['completion_rate'] as num).toDouble() / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '${statistics['completion_rate']}%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(dynamic user) {
    // Only guards get the quick scan button
    if (user.role.toLowerCase() == 'guard') {
      return FloatingActionButton(
        onPressed: () => context.push('/scanner'),
        child: const Icon(Icons.qr_code_scanner),
      );
    }
    
    // Supervisors and managers get a patrol monitoring button
    if (user.canAccess('supervisor')) {
      return FloatingActionButton(
        onPressed: () => context.push('/patrol-monitoring'),
        child: const Icon(Icons.monitor),
      );
    }
    
    return null;
  }
}