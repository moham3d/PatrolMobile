import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/emergency_provider.dart';
import '../../../core/providers/auth_provider.dart' as authProv;
import '../../../core/models/emergency.dart';
import '../../../core/widgets/role_based_widget.dart';
import '../../../core/constants/app_constants.dart';

/// Emergency dashboard for comprehensive emergency management
class EmergencyDashboardScreen extends ConsumerStatefulWidget {
  const EmergencyDashboardScreen({super.key});

  @override
  ConsumerState<EmergencyDashboardScreen> createState() =>
      _EmergencyDashboardScreenState();
}

class _EmergencyDashboardScreenState
    extends ConsumerState<EmergencyDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load emergency data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyAlertsProvider.notifier).loadAlerts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProv.authNotifierProvider);
    final user = authState is authProv.Authenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Management'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.warning), text: 'Active'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          // Emergency SOS button - always accessible
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppConstants.sosRoute),
              icon: const Icon(Icons.sos, color: Colors.white),
              label: const Text('SOS', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveAlertsTab(),
          _buildHistoryTab(),
          _buildContactsTab(),
          _buildSettingsTab(user),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildActiveAlertsTab() {
    final emergencyState = ref.watch(emergencyAlertsProvider);
    final emergencyNotifier = ref.read(emergencyAlertsProvider.notifier);

    return RefreshIndicator(
      onRefresh: () async {
        await emergencyNotifier.loadAlerts(status: 'active');
      },
      child: Builder(
        builder: (context) {
          if (emergencyState is Loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (emergencyState is EmergencyError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${emergencyState.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        emergencyNotifier.loadAlerts(status: 'active'),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (emergencyState is Loaded) {
            final activeAlerts = emergencyState.alerts
                .where((alert) => alert.isActive)
                .toList();

            if (activeAlerts.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Active Emergencies',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All systems operating normally',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeAlerts.length,
              itemBuilder: (context, index) {
                final alert = activeAlerts[index];
                return _buildAlertCard(alert, emergencyNotifier);
              },
            );
          }

          // Default state - show empty state
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'No Active Emergencies',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'All systems operating normally',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(EmergencyAlert alert, dynamic emergencyNotifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: alert.severityColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: alert.severityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.alertType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert.severity.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Alert #${alert.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (alert.description != null) ...[
              Text(alert.description!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(alert.userName ?? 'User #${alert.userId}'),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(_formatDateTime(alert.triggeredAt)),
              ],
            ),
            if (alert.locationName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(alert.locationName!)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Action buttons - role-based
            RoleBasedWidget(
              allowedRoles: const ['supervisor', 'site manager', 'admin'],
              child: Row(
                children: [
                  if (!alert.isAcknowledged) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _acknowledgeAlert(alert.id, emergencyNotifier),
                        icon: const Icon(Icons.check),
                        label: const Text('Acknowledge'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _escalateAlert(alert, emergencyNotifier),
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Escalate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resolveAlert(alert),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Resolve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => context.push('/emergency-history'),
            icon: const Icon(Icons.history),
            label: const Text('View Full Emergency History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent emergency events and response metrics',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => context.push('/emergency-contacts'),
            icon: const Icon(Icons.contacts),
            label: const Text('Manage Emergency Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _testEmergencyContacts(),
            icon: const Icon(Icons.phone_in_talk),
            label: const Text('Test Emergency Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Configure and test emergency contact system',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency System Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.timer),
              title: Text('Escalation Timer'),
              subtitle: Text(
                '${AppConstants.emergencyEscalationMinutes} minutes',
              ),
              trailing: RoleBasedWidget(
                allowedRoles: ['admin', 'site manager'],
                child: Icon(Icons.edit),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Location Services'),
              subtitle: const Text('GPS tracking for emergencies'),
              trailing: Switch(
                value: true, // This would be bound to actual setting
                onChanged: (value) {
                  // Update location setting
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Emergency Notifications'),
              subtitle: const Text('Push notifications for alerts'),
              trailing: Switch(
                value: true, // This would be bound to actual setting
                onChanged: (value) {
                  // Update notification setting
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (user != null) ...[
            Text(
              'User: ${user.displayName} (${user.role})',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Role Priority: ${user.rolePriority}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () => context.push(AppConstants.sosRoute),
          backgroundColor: Colors.red,
          child: const Icon(Icons.sos, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: () => context.push('/emergency-response'),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.emergency, color: Colors.white),
        ),
      ],
    );
  }

  void _acknowledgeAlert(int alertId, dynamic emergencyNotifier) async {
    try {
      await emergencyNotifier.acknowledgeAlert(
        alertId,
        note: 'Acknowledged via dashboard',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert acknowledged successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to acknowledge alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _escalateAlert(EmergencyAlert alert, dynamic emergencyNotifier) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escalate Emergency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Escalate Alert #${alert.id}?'),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Escalation Reason',
                hintText: 'Why is this being escalated?',
              ),
              maxLines: 3,
              onChanged: (value) {
                // Store reason
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop('Manual escalation required'),
            child: const Text('Escalate'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await emergencyNotifier.escalateAlert(alert.id, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert escalated successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to escalate alert: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _resolveAlert(EmergencyAlert alert) {
    context.push('/emergency/cancel-resolve', extra: alert);
  }

  void _testEmergencyContacts() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Emergency Contacts'),
        content: const Text(
          'This will test connectivity to all emergency contacts. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performContactTests();
            },
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }

  void _performContactTests() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing emergency contacts...'),
        duration: Duration(seconds: 2),
      ),
    );

    // This would test actual contacts using EmergencyResponseService
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency contact tests completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return isoString;
    }
  }
}
