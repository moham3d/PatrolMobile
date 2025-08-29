import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/emergency_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/emergency_service.dart';
import 'emergency_contacts_screen.dart';
import 'emergency_history_screen.dart';

/// Emergency SOS screen for triggering panic alerts
class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emergencyState = ref.watch(emergencyAlertsProvider);
    final emergencyNotifier = ref.read(emergencyAlertsProvider.notifier);
    final currentUser = ref.watch(currentUserProvider2);
    
    // Listen to emergency state changes
    ref.listen<EmergencyAlertsState>(emergencyAlertsProvider, (previous, next) {
      if (next is Triggered) {
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency alert sent! Alert ID: ${next.alert.id}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (next is EmergencyError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency alert failed: ${next.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    final isTriggering = emergencyState is Triggering;
    final isTriggered = emergencyState is Triggered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isTriggered) ...[ 
                // Emergency instruction
                Text(
                  'Emergency Assistance',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap the button below to send an emergency alert with your location to supervisors and security team.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // SOS Button
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isTriggering ? _pulseAnimation.value : 1.0,
                      child: GestureDetector(
                        onTap: isTriggering ? null : () => _triggerSOS(emergencyNotifier),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: isTriggering
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 4,
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.emergency,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'SOS',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 48),
                
                // Instructions
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How it works:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Immediately sends alert to supervisors\n'
                          '• Shares your GPS location\n'
                          '• Triggers emergency response protocol\n'
                          '• Use only for real emergencies',
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Quick access buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEmergencyContacts(context),
                        icon: const Icon(Icons.contacts),
                        label: const Text('Contacts'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callEmergencyServices(context),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call 911'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Additional actions
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEmergencyHistory(context),
                    icon: const Icon(Icons.history),
                    label: const Text('Emergency History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ),
              ] else ...[
                // Alert triggered state
                const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  'Emergency Alert Sent!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your emergency alert has been sent to:\n'
                  '• Security supervisors\n'
                  '• Site managers\n'
                  '• Emergency contacts',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Status card with real alert data
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAlertInfoRow(
                          Icons.emergency, 
                          'Alert ID', 
                          '#${emergencyState.alert.id}',
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildAlertInfoRow(
                          Icons.security, 
                          'Severity', 
                          emergencyState.alert.severity.toUpperCase(),
                          emergencyState.alert.severityColor,
                        ),
                        const SizedBox(height: 8),
                        _buildAlertInfoRow(
                          Icons.schedule, 
                          'Auto-Escalation', 
                          'In ${AppConstants.emergencyEscalationMinutes} minutes if no response',
                          Colors.orange.shade600,
                        ),
                        const SizedBox(height: 8),
                        if (emergencyState.alert.latitude != null && emergencyState.alert.longitude != null)
                          _buildAlertInfoRow(
                            Icons.location_on, 
                            'Location', 
                            'GPS: ${emergencyState.alert.latitude!.toStringAsFixed(6)}, ${emergencyState.alert.longitude!.toStringAsFixed(6)}',
                            Colors.green,
                          ),
                        if (emergencyState.alert.locationName != null) ...[
                          const SizedBox(height: 8),
                          _buildAlertInfoRow(
                            Icons.place, 
                            'Location Name', 
                            emergencyState.alert.locationName!,
                            Colors.green,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildAlertInfoRow(
                          Icons.access_time, 
                          'Alert Time', 
                          emergencyState.alert.triggeredAt.substring(0, 19).replaceAll('T', ' '),
                          Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildAlertInfoRow(
                          Icons.person, 
                          'Status', 
                          emergencyState.alert.status.toUpperCase(),
                          emergencyState.alert.isActive ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go(AppConstants.dashboardRoute),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Back to Dashboard'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelAlert(emergencyNotifier),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel Alert'),
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

  /// Trigger SOS emergency alert using real API
  void _triggerSOS(EmergencyAlertsNotifier emergencyNotifier) async {
    // Start the pulsing animation
    _animationController.repeat(reverse: true);
    
    // Get current user for description
    final currentUser = ref.read(currentUserProvider2);
    final description = currentUser != null 
        ? 'SOS emergency alert from ${currentUser.displayName} (${currentUser.role})'
        : 'SOS emergency alert from mobile app';
    
    // Trigger the emergency alert
    final alert = await emergencyNotifier.triggerSOS(description: description);
    
    if (alert != null) {
      // Stop animation on success - will be handled by state listener
      _animationController.stop();
    }
  }

  /// Cancel active emergency alert
  void _cancelAlert(EmergencyAlertsNotifier emergencyNotifier) {
    final emergencyState = ref.read(emergencyAlertsProvider);
    
    if (emergencyState is! Triggered) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Emergency Alert'),
        content: Text(
          'Are you sure you want to cancel emergency alert #${emergencyState.alert.id}? '
          'This will notify supervisors that the emergency has been resolved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Alert'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Show reason dialog
              final reason = await _showReasonDialog();
              if (reason != null) {
                await emergencyNotifier.cancelAlert(
                  emergencyState.alert.id, 
                  reason: reason,
                );
                if (mounted) {
                  context.go(AppConstants.dashboardRoute);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Alert'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to get cancellation reason
  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancellation Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancelling the emergency alert:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., False alarm, situation resolved',
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
              final reason = controller.text.trim();
              Navigator.of(context).pop(reason.isNotEmpty ? reason : 'Cancelled by user');
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Build alert information row
  Widget _buildAlertInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Show emergency contacts screen
  void _showEmergencyContacts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmergencyContactsScreen(),
      ),
    );
  }

  /// Show emergency history screen
  void _showEmergencyHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmergencyHistoryScreen(),
      ),
    );
  }

  /// Call emergency services directly
  void _callEmergencyServices(BuildContext context) async {
    try {
      final shouldCall = await _showEmergencyCallDialog();
      if (!shouldCall) return;

      await EmergencyService.instance.triggerEmergencyCall(
        createAlert: true,
        description: 'Emergency call initiated from SOS screen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calling Emergency Services and creating alert...'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency call failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show emergency call confirmation dialog
  Future<bool> _showEmergencyCallDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.emergency,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Emergency Call'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will call Emergency Services (911) and create an emergency alert.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Only use this for real emergencies.',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Call 911'),
          ),
        ],
      ),
    ) ?? false;
  }
}