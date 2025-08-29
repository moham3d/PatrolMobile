import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/checkpoint_provider.dart';
import '../../../core/widgets/role_based_widget.dart';

/// Checkpoint list screen showing available checkpoints
class CheckpointListScreen extends ConsumerStatefulWidget {
  const CheckpointListScreen({super.key});

  @override
  ConsumerState<CheckpointListScreen> createState() => _CheckpointListScreenState();
}

class _CheckpointListScreenState extends ConsumerState<CheckpointListScreen> {
  @override
  void initState() {
    super.initState();
    // Load checkpoints when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkpointsProvider.notifier).loadCheckpoints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkpointsState = ref.watch(checkpointsProvider);
    final isLoading = ref.watch(isLoadingCheckpointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkpoints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/scanner'),
            tooltip: 'Scan Checkpoint',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(checkpointsProvider.notifier).refreshCheckpoints();
        },
        child: _buildBody(checkpointsState, isLoading),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scanner'),
        tooltip: 'Scan Checkpoint',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildBody(CheckpointsState state, bool isLoading) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading checkpoints...'),
          ],
        ),
      );
    }

    if (state is CheckpointsError) {
      return Center(
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
              'Error loading checkpoints',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(checkpointsProvider.notifier).loadCheckpoints();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is CheckpointsLoaded) {
      final checkpoints = state.checkpoints;
      
      if (checkpoints.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No checkpoints found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'There are no checkpoints assigned to you.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(checkpointsProvider.notifier).refreshCheckpoints();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: checkpoints.length,
        itemBuilder: (context, index) {
          final checkpoint = checkpoints[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: checkpoint.isActive 
                  ? Colors.green.shade100 
                  : Colors.grey.shade100,
                child: Icon(
                  Icons.location_on,
                  color: checkpoint.isActive 
                    ? Colors.green.shade700 
                    : Colors.grey.shade600,
                ),
              ),
              title: Text(
                checkpoint.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code: ${checkpoint.code}'),
                  if (checkpoint.locationName != null)
                    Text('Location: ${checkpoint.locationName}'),
                  if (checkpoint.siteName != null)
                    Text('Site: ${checkpoint.siteName}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (checkpoint.hasQRCode)
                    Icon(Icons.qr_code, color: Colors.blue.shade600),
                  if (checkpoint.hasNFCTag)
                    Icon(Icons.nfc, color: Colors.orange.shade600),
                  const SizedBox(width: 8),
                  Icon(
                    checkpoint.isActive ? Icons.check_circle : Icons.pause_circle,
                    color: checkpoint.isActive ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              onTap: () => _showCheckpointDetails(checkpoint),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showCheckpointDetails(checkpoint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(checkpoint.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Code', checkpoint.code),
            if (checkpoint.description != null)
              _buildDetailRow('Description', checkpoint.description!),
            if (checkpoint.locationName != null)
              _buildDetailRow('Location', checkpoint.locationName!),
            if (checkpoint.siteName != null)
              _buildDetailRow('Site', checkpoint.siteName!),
            _buildDetailRow('Status', checkpoint.isActive ? 'Active' : 'Inactive'),
            if (checkpoint.hasQRCode || checkpoint.hasNFCTag) ...[
              const SizedBox(height: 8),
              const Text('Scan Methods:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (checkpoint.hasQRCode) const Text('• QR Code'),
              if (checkpoint.hasNFCTag) const Text('• NFC Tag'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/scanner');
            },
            child: const Text('Scan Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}