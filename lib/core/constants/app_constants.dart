/// App constants for PatrolShield Mobile
class AppConstants {
  static const String appName = 'PatrolShield Mobile';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String apiBaseUrl = 'https://api.millio.space';
  static const String wsBaseUrl = 'wss://api.millio.space/ws';
  static const String apiVersion = '2.0';
  
  // Mobile API v1 endpoints
  static const String mobileApiBase = '/mobile/v1';
  
  // Authentication
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh';
  static const String meEndpoint = '/auth/me';
  
  // Emergency endpoints
  static const String sosEndpoint = '$mobileApiBase/emergency/sos';
  static const String panicEndpoint = '$mobileApiBase/emergency/panic';
  
  // Checkpoint endpoints
  static const String checkpointsEndpoint = '/checkpoints';
  static const String scanEndpoint = '/checkpoints/scan';
  static const String verifyEndpoint = '/checkpoints/verify';
  static const String visitsEndpoint = '/checkpoints/visits';
  static const String statsEndpoint = '/checkpoints/stats';
  
  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String biometricEnabledKey = 'biometric_enabled';
  
  // Routes
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String sosRoute = '/sos';
  static const String scannerRoute = '/scanner';
  static const String checkpointsRoute = '/checkpoints';
  static const String emergencyDashboardRoute = '/emergency-dashboard';
  static const String emergencyResponseRoute = '/emergency-response';
  static const String emergencyHistoryRoute = '/emergency-history';
  static const String emergencyContactsRoute = '/emergency-contacts';
  static const String emergencyCancelResolveRoute = '/emergency/cancel-resolve';
  
  // Incident routes
  static const String incidentReportRoute = '/incident-report';
  static const String incidentListRoute = '/incidents';
  static const String incidentDetailRoute = '/incident';
  
  // Performance routes
  static const String performanceRoute = '/performance';
  
  // Patrol routes
  static const String patrolProgressRoute = '/patrol-progress';
  static const String patrolDetailRoute = '/patrol';
  static const String patrolMapRoute = '/patrol-map';
  static const String patrolMonitoringRoute = '/patrol-monitoring';
  static const String patrolCompletionRoute = '/patrol-completion';
  
  // Additional storage keys
  static const String userRoleKey = 'user_role';
  
  // User roles
  static const String roleGuard = 'guard';
  static const String roleSupervisor = 'supervisor';
  static const String roleSiteManager = 'site_manager';
  static const String roleAdmin = 'admin';
  
  // Emergency settings
  static const int sosTimeoutSeconds = 3;
  static const int emergencyEscalationMinutes = 5;
  
  // Offline sync settings
  static const int syncIntervalMinutes = 5;
  static const int maxOfflineQueueSize = 1000;
  
  // App settings
  static const Duration tokenRefreshInterval = Duration(hours: 23);
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const double gpsAccuracyThreshold = 10.0; // meters
}