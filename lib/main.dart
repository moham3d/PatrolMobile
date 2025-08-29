import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/api_service.dart';
import 'core/services/emergency_escalation_service.dart';
import 'core/services/emergency_response_service.dart';
import 'core/services/database_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/messaging_service.dart';
import 'core/services/location_sharing_service.dart';
import 'core/services/intelligent_sync_scheduling_service.dart';
import 'core/services/performance_monitoring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize essential services that are absolutely required for app start
  try {
    // Initialize core services that are critical for basic app functionality
    await _initializeCoreServices();

    runApp(const ProviderScope(child: PatrolShieldMobileApp()));
  } catch (e) {
    print('Error during app initialization: $e');
    // Still run the app with minimal functionality if core services fail
    runApp(const ProviderScope(child: PatrolShieldMobileApp()));
  }
}

Future<void> _initializeCoreServices() async {
  // Only initialize absolutely essential services here
  // Keep this minimal to prevent startup hangs

  // Initialize database (critical for offline functionality)
  try {
    await DatabaseService.instance.database;
  } catch (e) {
    print('Failed to initialize database: $e');
    // Continue without database for now
  }
}

class PatrolShieldMobileApp extends ConsumerStatefulWidget {
  const PatrolShieldMobileApp({super.key});

  @override
  ConsumerState<PatrolShieldMobileApp> createState() =>
      _PatrolShieldMobileAppState();
}

class _PatrolShieldMobileAppState extends ConsumerState<PatrolShieldMobileApp> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication and other services after the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBackgroundServices();
    });
  }

  Future<void> _initializeBackgroundServices() async {
    try {
      // Initialize services that can be loaded after app start
      await _initializeOptionalServices();

      // Initialize authentication
      ref.read(authNotifierProvider.notifier).initialize();
    } catch (e) {
      print('Error initializing background services: $e');
      // Continue without these services
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router(ref),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> _initializeOptionalServices() async {
  // Initialize services in background after app UI is shown
  // This prevents the app from hanging on startup

  try {
    await ApiService.instance.initialize();
    print('API Service initialized successfully');
  } catch (e) {
    print('Failed to initialize API Service: $e');
  }

  try {
    await ConnectivityService.instance.initialize();
    print('Connectivity Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Connectivity Service: $e');
  }

  try {
    await SyncService.instance.initialize();
    print('Sync Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Sync Service: $e');
  }

  try {
    await EmergencyEscalationService.instance.initialize();
    print('Emergency Escalation Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Emergency Escalation Service: $e');
  }

  try {
    EmergencyResponseService.instance;
    print('Emergency Response Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Emergency Response Service: $e');
  }

  try {
    await NotificationService.instance.initialize();
    print('Notification Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Notification Service: $e');
  }

  try {
    await MessagingService.instance.initialize();
    print('Messaging Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Messaging Service: $e');
  }

  try {
    await LocationSharingService.instance.initialize();
    print('Location Sharing Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Location Sharing Service: $e');
  }

  try {
    await PerformanceMonitoringService.instance.initialize();
    print('Performance Monitoring Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Performance Monitoring Service: $e');
  }

  try {
    await IntelligentSyncSchedulingService.instance.initialize();
    print('Intelligent Sync Scheduling Service initialized successfully');
  } catch (e) {
    print('Failed to initialize Intelligent Sync Scheduling Service: $e');
  }

  print('All background services initialization completed');
}
