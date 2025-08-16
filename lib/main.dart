import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service
  await ApiService.instance.initialize();
  
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