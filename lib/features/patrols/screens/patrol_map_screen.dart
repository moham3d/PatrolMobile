import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers/patrol_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/patrol_simple.dart';
import '../../../core/models/checkpoint.dart';
import '../../../core/widgets/role_based_widget.dart';
import '../widgets/checkpoint_status_indicator.dart';

/// Screen displaying patrol routes on an interactive map with checkpoint tracking
class PatrolMapScreen extends ConsumerStatefulWidget {
  final int? patrolId;

  const PatrolMapScreen({super.key, this.patrolId});

  @override
  ConsumerState<PatrolMapScreen> createState() => _PatrolMapScreenState();
}

class _PatrolMapScreenState extends ConsumerState<PatrolMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentLocation;
  bool _isTrackingLocation = false;
  bool _showAllPatrols = false;
  String _selectedFilter = 'active';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _getCurrentLocation();
  }

  void _loadInitialData() {
    final authState = ref.read(authNotifierProvider);
    if (authState is! Authenticated) return;

    final user = authState.user;

    if (widget.patrolId != null) {
      // Load specific patrol
      ref.read(patrolDetailProvider(widget.patrolId!).notifier).loadPatrol();
    } else {
      // Load patrols based on user role
      if (user.canAccess('supervisor') || user.canAccess('site manager')) {
        _showAllPatrols = true;
        ref.read(patrolListProvider.notifier).loadActivePatrols();
      } else {
        ref.read(patrolListProvider.notifier).loadAssignedPatrols();
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = position;
      });

      // Center map on current location
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      // Handle location error silently
    }
  }

  void _toggleLocationTracking() {
    setState(() {
      _isTrackingLocation = !_isTrackingLocation;
    });

    if (_isTrackingLocation) {
      _startLocationTracking();
    }
  }

  void _startLocationTracking() {
    // Start location updates for real-time tracking
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (_isTrackingLocation) {
        setState(() {
          _currentLocation = position;
        });

        // Smoothly move map to follow user
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patrolId != null ? 'Patrol Route' : 'Patrol Map'),
        actions: [
          IconButton(
            icon: Icon(
              _isTrackingLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
            ),
            onPressed: _toggleLocationTracking,
          ),
          RoleBasedWidget(
            allowedRoles: const ['supervisor', 'site manager', 'admin'],
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                setState(() {
                  _selectedFilter = value;
                });
                _loadFilteredPatrols();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'active',
                  child: Text('Active Patrols'),
                ),
                const PopupMenuItem(
                  value: 'pending',
                  child: Text('Pending Patrols'),
                ),
                const PopupMenuItem(
                  value: 'completed',
                  child: Text('Completed Patrols'),
                ),
                const PopupMenuItem(value: 'all', child: Text('All Patrols')),
              ],
            ),
          ),
        ],
      ),
      body: _buildMapView(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentLocation != null)
            FloatingActionButton(
              heroTag: 'center_location',
              mini: true,
              onPressed: () {
                _mapController.move(
                  LatLng(
                    _currentLocation!.latitude,
                    _currentLocation!.longitude,
                  ),
                  15.0,
                );
              },
              child: const Icon(Icons.my_location),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'refresh_patrols',
            onPressed: _loadInitialData,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation != null
                ? LatLng(
                    _currentLocation!.latitude,
                    _currentLocation!.longitude,
                  )
                : const LatLng(37.7749, -122.4194), // Default to San Francisco
            initialZoom: 13.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            // Base map layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.patrolshield.mobile',
            ),

            // Patrol routes and checkpoints
            ..._buildPatrolLayers(),

            // Current location marker
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Patrol information overlay
        _buildPatrolInfoOverlay(),
      ],
    );
  }

  List<Widget> _buildPatrolLayers() {
    if (widget.patrolId != null) {
      return _buildSinglePatrolLayers();
    } else {
      return _buildMultiplePatrolLayers();
    }
  }

  List<Widget> _buildSinglePatrolLayers() {
    return [
      Consumer(
        builder: (context, ref, child) {
          final patrolDetailState = ref.watch(
            patrolDetailProvider(widget.patrolId!),
          );

          return switch (patrolDetailState) {
            PatrolDetailLoaded(:final patrol) => _buildPatrolRouteLayer(patrol),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    ];
  }

  List<Widget> _buildMultiplePatrolLayers() {
    return [
      Consumer(
        builder: (context, ref, child) {
          final patrolListState = ref.watch(patrolListProvider);

          return switch (patrolListState) {
            PatrolListLoaded(:final patrols) => _buildMultiplePatrolRoutes(
              patrols,
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    ];
  }

  Widget _buildPatrolRouteLayer(Patrol patrol) {
    if (patrol.checkpoints == null || patrol.checkpoints!.isEmpty) {
      return const SizedBox.shrink();
    }

    final checkpoints = patrol.checkpoints!;
    final validCheckpoints = checkpoints
        .where((cp) => cp.latitude != null && cp.longitude != null)
        .toList();

    if (validCheckpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    // Route polyline points
    final routePoints = validCheckpoints
        .map((cp) => LatLng(cp.latitude!, cp.longitude!))
        .toList();

    return Stack(
      children: [
        // Route polyline
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              strokeWidth: 4.0,
              color: _getPatrolRouteColor(patrol.status),
            ),
          ],
        ),

        // Checkpoint markers
        MarkerLayer(
          markers: validCheckpoints.asMap().entries.map((entry) {
            final index = entry.key;
            final checkpoint = entry.value;
            return Marker(
              point: LatLng(checkpoint.latitude!, checkpoint.longitude!),
              child: _buildCheckpointMarker(
                checkpoint,
                index + 1,
                patrol.status,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiplePatrolRoutes(List<Patrol> patrols) {
    final validPatrols = patrols
        .where(
          (p) =>
              p.checkpoints != null &&
              p.checkpoints!.any(
                (cp) => cp.latitude != null && cp.longitude != null,
              ),
        )
        .toList();

    if (validPatrols.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Multiple route polylines
        PolylineLayer(
          polylines: validPatrols.map((patrol) {
            final checkpoints = patrol.checkpoints!
                .where((cp) => cp.latitude != null && cp.longitude != null)
                .toList();

            final routePoints = checkpoints
                .map((cp) => LatLng(cp.latitude!, cp.longitude!))
                .toList();

            return Polyline(
              points: routePoints,
              strokeWidth: 3.0,
              color: _getPatrolRouteColor(patrol.status).withValues(alpha: 0.7),
            );
          }).toList(),
        ),

        // All checkpoint markers
        MarkerLayer(
          markers: validPatrols.expand((patrol) {
            final checkpoints = patrol.checkpoints!
                .where((cp) => cp.latitude != null && cp.longitude != null)
                .toList();

            return checkpoints.asMap().entries.map((entry) {
              final index = entry.key;
              final checkpoint = entry.value;
              return Marker(
                point: LatLng(checkpoint.latitude!, checkpoint.longitude!),
                child: _buildCheckpointMarker(
                  checkpoint,
                  index + 1,
                  patrol.status,
                  compact: true,
                ),
              );
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckpointMarker(
    Checkpoint checkpoint,
    int sequenceNumber,
    String patrolStatus, {
    bool compact = false,
  }) {
    final Color markerColor = _getCheckpointColor(checkpoint, patrolStatus);
    final IconData markerIcon = _getCheckpointIcon(checkpoint);

    return GestureDetector(
      onTap: () => _showCheckpointDetails(checkpoint),
      child: Container(
        width: compact ? 30 : 40,
        height: compact ? 30 : 40,
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: compact
            ? Icon(markerIcon, color: Colors.white, size: 16)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(markerIcon, color: Colors.white, size: 16),
                  Text(
                    sequenceNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getPatrolRouteColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getCheckpointColor(Checkpoint checkpoint, String patrolStatus) {
    if (patrolStatus == 'completed') {
      return Colors.green;
    }

    if (checkpoint.lastVisitAt != null) {
      return Colors.green; // Visited
    } else if (patrolStatus == 'in_progress') {
      return Colors.orange; // Pending
    } else {
      return Colors.grey; // Not started
    }
  }

  IconData _getCheckpointIcon(Checkpoint checkpoint) {
    if (checkpoint.lastVisitAt != null) {
      return Icons.check;
    } else {
      return Icons.location_on;
    }
  }

  Widget _buildPatrolInfoOverlay() {
    if (widget.patrolId == null) {
      return _buildPatrolListOverlay();
    } else {
      return _buildSinglePatrolInfoOverlay();
    }
  }

  Widget _buildPatrolListOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Consumer(
        builder: (context, ref, child) {
          final patrolListState = ref.watch(patrolListProvider);

          return switch (patrolListState) {
            PatrolListLoaded(:final patrols) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${patrols.length} $_selectedFilter patrol${patrols.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedFilter.toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _buildSinglePatrolInfoOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Consumer(
        builder: (context, ref, child) {
          final patrolDetailState = ref.watch(
            patrolDetailProvider(widget.patrolId!),
          );

          return switch (patrolDetailState) {
            PatrolDetailLoaded(:final patrol) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          patrol.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPatrolRouteColor(
                            patrol.status,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          patrol.status.toUpperCase(),
                          style: TextStyle(
                            color: _getPatrolRouteColor(patrol.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (patrol.checkpoints != null) ...[
                    const SizedBox(height: 8),
                    CheckpointStatusIndicator(
                      checkpoints: patrol.checkpoints!,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  void _showCheckpointDetails(Checkpoint checkpoint) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getCheckpointIcon(checkpoint),
                  color: _getCheckpointColor(checkpoint, 'in_progress'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    checkpoint.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (checkpoint.description != null) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(checkpoint.description!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(Icons.qr_code, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Code: ${checkpoint.code}'),
              ],
            ),
            const SizedBox(height: 8),
            if (checkpoint.lastVisitAt != null) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text('Visited: ${checkpoint.lastVisitAt}'),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${checkpoint.latitude?.toStringAsFixed(6)}, ${checkpoint.longitude?.toStringAsFixed(6)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to checkpoint scanner
                      // context.push('/scanner/${checkpoint.id}');
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Checkpoint'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _loadFilteredPatrols() {
    final authState = ref.read(authNotifierProvider);
    if (authState is! Authenticated) return;

    final user = authState.user;

    if (user.canAccess('supervisor') || user.canAccess('site manager')) {
      switch (_selectedFilter) {
        case 'active':
          ref.read(patrolListProvider.notifier).loadActivePatrols();
          break;
        case 'pending':
          ref
              .read(patrolListProvider.notifier)
              .loadAssignedPatrols(status: 'pending');
          break;
        case 'completed':
          ref
              .read(patrolListProvider.notifier)
              .loadAssignedPatrols(status: 'completed');
          break;
        case 'all':
          ref.read(patrolListProvider.notifier).loadActivePatrols();
          break;
      }
    } else {
      ref
          .read(patrolListProvider.notifier)
          .loadAssignedPatrols(
            status: _selectedFilter == 'all' ? null : _selectedFilter,
          );
    }
  }
}
