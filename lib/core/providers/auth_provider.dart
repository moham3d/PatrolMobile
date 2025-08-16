import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Authentication state provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Current user provider
final currentUserProvider = StateProvider<User?>((ref) {
  return null;
});

/// Authentication status provider
final authStatusProvider = StateProvider<AuthStatus>((ref) {
  return AuthStatus.unauthenticated;
});

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const AuthState.unauthenticated());

  /// Initialize authentication
  Future<void> initialize() async {
    state = const AuthState.loading();
    
    try {
      await _authService.initialize();
      
      if (_authService.isAuthenticated) {
        state = AuthState.authenticated(_authService.currentUser!);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Login with credentials
  Future<void> login(String username, String password) async {
    state = const AuthState.loading();
    
    try {
      final authResponse = await _authService.login(username, password);
      state = AuthState.authenticated(authResponse.user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Login with biometric
  Future<void> loginWithBiometric() async {
    state = const AuthState.loading();
    
    try {
      final success = await _authService.loginWithBiometric();
      
      if (success && _authService.currentUser != null) {
        state = AuthState.authenticated(_authService.currentUser!);
      } else {
        state = const AuthState.error('Biometric authentication failed');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState.unauthenticated();
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    try {
      await _authService.enableBiometricAuth();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    return await _authService.isBiometricAvailable();
  }

  /// Check permission
  bool hasPermission(String permission) {
    return _authService.hasPermission(permission);
  }

  /// Check role access
  bool canAccess(String role) {
    return _authService.canAccess(role);
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (state is! Authenticated) return;
    
    try {
      final user = await _authService.getCurrentUser();
      state = AuthState.authenticated(user);
    } catch (e) {
      // If refresh fails, user might need to re-authenticate
      state = AuthState.error(e.toString());
    }
  }
}

/// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

/// Authentication state sealed class
sealed class AuthState {
  const AuthState();
  
  const factory AuthState.loading() = Loading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.error(String message) = AuthError;
}

class Loading extends AuthState {
  const Loading();
}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Legacy auth status enum for compatibility
enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Computed providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is Authenticated;
});

final currentUserProvider2 = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is Authenticated ? authState.user : null;
});

final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is Loading;
});

final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthError ? authState.message : null;
});