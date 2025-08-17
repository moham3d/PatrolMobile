import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/emergency.dart';
import '../../../core/services/emergency_response_service.dart';
import '../../../core/providers/emergency_provider.dart';

/// Enhanced emergency contact management screen
class EnhancedEmergencyContactsScreen extends ConsumerStatefulWidget {
  const EnhancedEmergencyContactsScreen({super.key});

  @override
  ConsumerState<EnhancedEmergencyContactsScreen> createState() => _EnhancedEmergencyContactsScreenState();
}

class _EnhancedEmergencyContactsScreenState extends ConsumerState<EnhancedEmergencyContactsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedContactType = 'all';
  Map<int, ContactTestResult?> _testResults = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(emergencyContactsProvider),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedContactType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Contacts')),
              const PopupMenuItem(value: 'emergency', child: Text('Emergency Only')),
              const PopupMenuItem(value: 'security', child: Text('Security Only')),
              const PopupMenuItem(value: 'management', child: Text('Management Only')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
            Tab(icon: Icon(Icons.speed_dial), text: 'Quick Dial'),
            Tab(icon: Icon(Icons.test_tube), text: 'Test Results'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactsTab(contactsAsync),
          _buildQuickDialTab(contactsAsync),
          _buildTestResultsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildContactsTab(AsyncValue<List<EmergencyContact>> contactsAsync) {
    return contactsAsync.when(
      data: (contacts) {
        final filteredContacts = _filterContacts(contacts);
        
        if (filteredContacts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(emergencyContactsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredContacts.length,
            itemBuilder: (context, index) {
              final contact = filteredContacts[index];
              return _buildEnhancedContactCard(contact);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildQuickDialTab(AsyncValue<List<EmergencyContact>> contactsAsync) {
    return contactsAsync.when(
      data: (contacts) {
        final emergencyContacts = contacts.where((c) => c.type == 'emergency').toList();
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Emergency 911 button
              _buildQuickDialButton(
                icon: Icons.emergency,
                label: 'Emergency 911',
                description: 'Call emergency services immediately',
                color: Colors.red,
                onTap: () => _callEmergencyServices(),
              ),
              
              const SizedBox(height: 16),
              
              // Quick dial for emergency contacts
              ...emergencyContacts.map((contact) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuickDialButton(
                  icon: contact.icon,
                  label: contact.name,
                  description: contact.description ?? contact.phone,
                  color: _getContactTypeColor(contact.type),
                  onTap: () => _callContact(contact),
                ),
              )),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTestResultsTab() {
    if (_testResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Test Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Test emergency contacts to see connectivity results',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _testResults.length,
      itemBuilder: (context, index) {
        final entry = _testResults.entries.elementAt(index);
        final contactId = entry.key;
        final result = entry.value;
        
        if (result == null) return const SizedBox.shrink();
        
        return _buildTestResultCard(contactId, result);
      },
    );
  }

  Widget _buildEnhancedContactCard(EmergencyContact contact) {
    final typeColor = _getContactTypeColor(contact.type);
    final testResult = _testResults[contact.id];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Contact icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    contact.icon,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Contact info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.phone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (contact.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          contact.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Contact type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contact.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _testContact(contact),
                    icon: Icon(_getTestResultIcon(testResult)),
                    label: const Text('Test'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _getTestResultColor(testResult),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callContact(contact),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            
            // Test result indicator
            if (testResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTestResultColor(testResult).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTestResultIcon(testResult),
                      size: 16,
                      color: _getTestResultColor(testResult),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        testResult.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getTestResultColor(testResult),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDialButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestResultCard(int contactId, ContactTestResult result) {
    final color = result.success ? Colors.green : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contact #$contactId',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTestTime(result.testedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _callEmergencyServices,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.emergency),
      label: const Text('Emergency 911'),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Emergency Contacts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No emergency contacts match your filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
            'Error loading contacts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(emergencyContactsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<EmergencyContact> _filterContacts(List<EmergencyContact> contacts) {
    if (_selectedContactType == 'all') return contacts;
    return contacts.where((c) => c.type == _selectedContactType).toList();
  }

  Future<void> _testContact(EmergencyContact contact) async {
    try {
      final responseService = ref.read(emergencyResponseServiceProvider);
      final result = await responseService.testEmergencyContact(contact);
      
      setState(() {
        _testResults[contact.id] = result;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test ${result.success ? 'successful' : 'failed'}: ${result.message}'),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callContact(EmergencyContact contact) async {
    try {
      final emergencyService = ref.read(emergencyServiceProvider);
      final success = await emergencyService.callEmergencyContact(contact);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling ${contact.name}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call ${contact.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callEmergencyServices() async {
    try {
      final emergencyService = ref.read(emergencyServiceProvider);
      final success = await emergencyService.callEmergencyServices();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calling Emergency Services (911)...'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call emergency services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getContactTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return Colors.red.shade600;
      case 'security':
        return Colors.blue.shade600;
      case 'management':
        return Colors.purple.shade600;
      case 'police':
        return Colors.indigo.shade600;
      case 'fire':
        return Colors.orange.shade600;
      case 'medical':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getTestResultIcon(ContactTestResult? result) {
    if (result == null) return Icons.science;
    return result.success ? Icons.check_circle : Icons.error;
  }

  Color _getTestResultColor(ContactTestResult? result) {
    if (result == null) return Colors.grey;
    return result.success ? Colors.green : Colors.red;
  }

  String _formatTestTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else {
        return '${difference.inHours}h ago';
      }
    } catch (e) {
      return timestamp;
    }
  }
}