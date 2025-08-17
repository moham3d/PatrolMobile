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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize core services
  await ApiService.instance.initialize();
  
  // Initialize offline database
  await DatabaseService.instance.database;
  
  // Initialize connectivity monitoring
  await ConnectivityService.instance.initialize();
  
  // Initialize data sync service
  await SyncService.instance.initialize();
  
  // Initialize emergency services
  await EmergencyEscalationService.instance.initialize();
  EmergencyResponseService.instance;
  
  runApp(
    const ProviderScope(
      child: PatrolShieldMobileApp(),
    ),
  );
}

class PatrolShieldMobileApp extends ConsumerStatefulWidget {
  const PatrolShieldMobileApp({super.key});

  @override
  ConsumerState<PatrolShieldMobileApp> createState() => _PatrolShieldMobileAppState();
}

class _PatrolShieldMobileAppState extends ConsumerState<PatrolShieldMobileApp> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).initialize();
    });
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