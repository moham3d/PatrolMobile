import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/emergency/screens/sos_screen.dart';
import '../../features/emergency/screens/emergency_response_screen.dart';
import '../../features/emergency/screens/emergency_history_screen.dart';
import '../../features/emergency/screens/emergency_contacts_screen.dart';
import '../../features/emergency/screens/emergency_cancel_resolve_screen.dart';
import '../../features/emergency/screens/emergency_dashboard_screen.dart';
import '../../features/checkpoints/screens/scanner_screen.dart';
import '../../features/checkpoints/screens/checkpoint_list_screen.dart';
import '../../features/patrols/screens/patrol_progress_screen.dart';
import '../../features/patrols/screens/patrol_detail_screen.dart';
import '../providers/auth_provider.dart';
import '../constants/app_constants.dart';
import '../models/emergency.dart';

/// App routing configuration using GoRouter
class AppRouter {
  static GoRouter router(WidgetRef ref) => GoRouter(
    initialLocation: AppConstants.loginRoute,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState is Authenticated;
      final isLoginRoute = state.fullPath == AppConstants.loginRoute;

      // If not authenticated and not on login route, redirect to login
      if (!isAuthenticated && !isLoginRoute) {
        return AppConstants.loginRoute;
      }

      // If authenticated and on login route, redirect to dashboard
      if (isAuthenticated && isLoginRoute) {
        return AppConstants.dashboardRoute;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Authentication routes
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Main app routes (protected)
      GoRoute(
        path: AppConstants.dashboardRoute,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Emergency routes
      GoRoute(
        path: AppConstants.sosRoute,
        name: 'sos',
        builder: (context, state) => const SOSScreen(),
      ),
      
      GoRoute(
        path: '/emergency-dashboard',
        name: 'emergency_dashboard',
        builder: (context, state) => const EmergencyDashboardScreen(),
      ),
      
      GoRoute(
        path: '/emergency-response',
        name: 'emergency_response',
        builder: (context, state) => const EmergencyResponseScreen(),
      ),
      
      GoRoute(
        path: '/emergency-history',
        name: 'emergency_history',
        builder: (context, state) => const EmergencyHistoryScreen(),
      ),
      
      GoRoute(
        path: '/emergency-contacts',
        name: 'emergency_contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      
      GoRoute(
        path: '/emergency/cancel-resolve',
        name: 'emergency_cancel_resolve',
        builder: (context, state) {
          final alert = state.extra as EmergencyAlert;
          return EmergencyCancelResolveScreen(alert: alert);
        },
      ),
      
      // Checkpoint routes
      GoRoute(
        path: '/checkpoints',
        name: 'checkpoints',
        builder: (context, state) => const CheckpointListScreen(),
      ),
      
      GoRoute(
        path: AppConstants.scannerRoute,
        name: 'scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      
      // Patrol routes
      GoRoute(
        path: AppConstants.patrolProgressRoute,
        name: 'patrol_progress',
        builder: (context, state) => const PatrolProgressScreen(),
      ),
      
      GoRoute(
        path: '/patrol/:patrolId',
        name: 'patrol_detail',
        builder: (context, state) {
          final patrolId = state.pathParameters['patrolId']!;
          final action = state.uri.queryParameters['action'];
          return PatrolDetailScreen(
            patrolId: patrolId,
            action: action,
          );
        },
      ),
    ],
    
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.dashboardRoute),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}