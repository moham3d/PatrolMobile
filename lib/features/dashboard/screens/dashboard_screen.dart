import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/user.dart';
import '../../../core/widgets/role_based_widget.dart';

/// Main dashboard screen for authenticated users
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    // Handle auth state changes
    if (authState is! Authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppConstants.loginRoute);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PatrolShield Dashboard'),
            Text(
              DashboardBody.getRoleDisplayName(authState.user.role),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          // Role badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DashboardBody.getStatusColor(authState.user.role).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              authState.user.role.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: DashboardBody.getStatusColor(authState.user.role),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(authNotifier),
          ),
        ],
      ),
      body: DashboardBody(user: authState.user),
      floatingActionButton: const SOSFloatingActionButton(),
    );
  }

  void _handleLogout(AuthNotifier authNotifier) {
    authNotifier.logout();
  }
}

/// Dashboard body content
class DashboardBody extends ConsumerWidget {
  final User user;
  
  const DashboardBody({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeCard(context, user),
          const SizedBox(height: 16),
          
          // Quick actions
          _buildQuickActions(context, ref),
          const SizedBox(height: 16),
          
          // Status overview with role-based visibility
          SupervisorOnlyWidget(
            showFallback: true,
            fallback: _buildGuardStatusOverview(context),
            child: _buildStatusOverview(context),
          ),
          const SizedBox(height: 16),
          
          // Recent activity
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'System Administrator';
      case 'site manager':
        return 'Site Manager';
      case 'supervisor':
        return 'Security Supervisor';
      case 'guard':
      case 'mobile guard':
        return 'Security Guard';
      default:
        return role;
    }
  }

  static Color getStatusColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'site manager':
        return Colors.blue;
      case 'supervisor':
        return Colors.orange;
      case 'guard':
      case 'mobile guard':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildWelcomeCard(BuildContext context, User user) {
    final roleDisplayName = DashboardBody.getRoleDisplayName(user.role);
    final statusColor = DashboardBody.getStatusColor(user.role);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    user.firstName.isNotEmpty && user.lastName.isNotEmpty
                        ? '${user.firstName[0]}${user.lastName[0]}'
                        : user.username[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user.displayName.isNotEmpty ? user.displayName : user.username}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        roleDisplayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'On Duty',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final quickActions = _getQuickActionsForRole(user.role, context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return _buildActionCard(
              context,
              icon: action.icon,
              title: action.title,
              subtitle: action.subtitle,
              onTap: action.onTap,
              enabled: action.enabled,
            );
          },
        ),
      ],
    );
  }

  List<QuickAction> _getQuickActionsForRole(String role, BuildContext context) {
    final List<QuickAction> actions = [];
    
    // All roles can scan checkpoints and trigger SOS
    actions.add(QuickAction(
      icon: Icons.sos,
      title: 'Emergency SOS',
      subtitle: 'Trigger Alert',
      onTap: () => context.go(AppConstants.sosRoute),
      enabled: true,
    ));
    
    actions.add(QuickAction(
      icon: Icons.qr_code_scanner,
      title: 'Scan Checkpoint',
      subtitle: 'QR/NFC Scanner',
      onTap: () => context.go(AppConstants.scannerRoute),
      enabled: true,
    ));
    
    actions.add(QuickAction(
      icon: Icons.location_on,
      title: 'View Checkpoints',
      subtitle: 'Browse All',
      onTap: () => context.go(AppConstants.checkpointsRoute),
      enabled: true,
    ));
    
    // Add patrol progress for all roles
    actions.add(QuickAction(
      icon: Icons.route,
      title: 'Patrol Progress',
      subtitle: 'Track Routes',
      onTap: () => context.go(AppConstants.patrolProgressRoute),
      enabled: true,
    ));
    
    // All roles can report incidents
    actions.add(QuickAction(
      icon: Icons.report_problem,
      title: 'Report Incident',
      subtitle: 'Create Report',
      onTap: () {
        // TODO: Navigate to incident reporting
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident reporting coming soon')),
        );
      },
      enabled: true,
    ));
    
    // Supervisors and above can manage guards
    if (user.isSupervisor || user.isSiteManager || user.isAdmin) {
      actions.add(QuickAction(
        icon: Icons.people,
        title: 'Manage Guards',
        subtitle: 'View & Assign',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guard management coming soon')),
          );
        },
        enabled: true,
      ));
      
      // Emergency response for supervisors+
      actions.add(QuickAction(
        icon: Icons.emergency_outlined,
        title: 'Emergency Response',
        subtitle: 'Manage Alerts',
        onTap: () => context.go('/emergency-response'),
        enabled: true,
      ));
      
      // Emergency dashboard for comprehensive emergency management
      actions.add(QuickAction(
        icon: Icons.dashboard,
        title: 'Emergency Dashboard',
        subtitle: 'Full Emergency View',
        onTap: () => context.go(AppConstants.emergencyDashboardRoute),
        enabled: true,
      ));
    }
    
    // Site managers and above can access analytics
    if (user.isSiteManager || user.isAdmin) {
      actions.add(QuickAction(
        icon: Icons.analytics,
        title: 'Analytics',
        subtitle: 'Reports & Stats',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Analytics coming soon')),
          );
        },
        enabled: true,
      ));
    }
    
    // Admins can manage sites
    if (user.isAdmin) {
      actions.add(QuickAction(
        icon: Icons.business,
        title: 'Manage Sites',
        subtitle: 'Site Configuration',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Site management coming soon')),
          );
        },
        enabled: true,
      ));
    }
    
    return actions;
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: enabled ? null : Colors.grey.shade100,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: enabled ? Theme.of(context).primaryColor : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: enabled ? null : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: enabled ? null : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                context,
                title: 'Checkpoints',
                value: '0/5',
                subtitle: 'Completed',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                context,
                title: 'Incidents',
                value: '0',
                subtitle: 'Open',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                context,
                title: 'Shift Time',
                value: '2h 15m',
                subtitle: 'Elapsed',
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.info_outline),
                ),
                title: const Text('Activity placeholder'),
                subtitle: const Text('Recent activity will be shown here'),
                trailing: Text(
                  '2h ago',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGuardStatusOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'My Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                context,
                title: 'Checkpoints',
                value: '0/5',
                subtitle: 'Today',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                context,
                title: 'Shift Time',
                value: '2h 15m',
                subtitle: 'Active',
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Emergency SOS floating action button
class SOSFloatingActionButton extends StatelessWidget {
  const SOSFloatingActionButton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.go(AppConstants.sosRoute),
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.emergency),
      label: const Text('SOS'),
      heroTag: 'sos_button',
    );
  }
}

/// Quick action model for role-based actions
class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });
}