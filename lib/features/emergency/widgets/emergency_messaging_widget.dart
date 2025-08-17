import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/realtime_provider.dart';
import '../../../core/widgets/role_based_widget.dart';
import '../../../core/services/messaging_service.dart';

/// Emergency messaging screen for real-time communications
class EmergencyMessagingWidget extends ConsumerStatefulWidget {
  const EmergencyMessagingWidget({super.key});

  @override
  ConsumerState<EmergencyMessagingWidget> createState() => _EmergencyMessagingWidgetState();
}

class _EmergencyMessagingWidgetState extends ConsumerState<EmergencyMessagingWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider);
    final messagingState = ref.watch(emergencyMessagingProvider);
    final newMessageAsync = ref.watch(newMessageProvider);

    // Listen for new messages and scroll to bottom
    ref.listen(newMessageProvider, (previous, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.red.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                'Emergency Communications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (messagingState.isSending)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.red.shade600),
                  ),
                ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: messagesAsync.when(
            data: (messages) => ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Error loading messages: $error',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ),
          ),
        ),

        // Error/Success messages
        if (messagingState.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red.shade50,
            child: Text(
              messagingState.error!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
          ),

        if (messagingState.successMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Text(
              messagingState.successMessage!,
              style: TextStyle(color: Colors.green.shade700),
              textAlign: TextAlign.center,
            ),
          ),

        // Message input (only for supervisors and above)
        RoleBasedWidget(
          allowedRoles: const ['supervisor', 'site manager', 'admin'],
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type emergency message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    enabled: !messagingState.isSending,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: messagingState.isSending ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(EmergencyMessage message) {
    final isUrgent = message.isUrgent;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : Colors.grey.shade300,
          width: isUrgent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sender and timestamp
          Row(
            children: [
              Icon(
                _getMessageIcon(message.type),
                size: 16,
                color: isUrgent ? Colors.red.shade600 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                message.senderName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUrgent ? Colors.red.shade800 : Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(message.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Message content
          Text(
            message.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isUrgent ? Colors.red.shade800 : Colors.grey.shade800,
            ),
          ),
          // Message type badge
          if (message.type != 'general')
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(message.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.type.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getMessageIcon(String type) {
    switch (type) {
      case 'emergency':
      case 'sos_escalation':
        return Icons.emergency;
      case 'checkpoint_update':
        return Icons.location_on;
      case 'patrol_assignment':
        return Icons.route;
      default:
        return Icons.message;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'emergency':
      case 'sos_escalation':
        return Colors.red.shade600;
      case 'checkpoint_update':
        return Colors.blue.shade600;
      case 'patrol_assignment':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(emergencyMessagingProvider.notifier).sendEmergencyMessage(
      content: content,
      recipientIds: [], // Backend will handle recipient selection
      type: 'emergency',
      isUrgent: true,
    );

    _messageController.clear();
  }
}