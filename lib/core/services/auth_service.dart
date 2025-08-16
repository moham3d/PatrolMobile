import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../exceptions/api_exception.dart';
import 'api_service.dart';

/// Authentication service for PatrolShield backend
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._internal();
  
  AuthService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  User? _currentUser;
  String? _currentToken;
  
  /// Get current authenticated user
  User? get currentUser => _currentUser;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null && _currentToken != null;

  /// Initialize authentication service
  Future<void> initialize() async {
    await _loadStoredAuth();
  }

  /// Login with username and password
  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await ApiService.instance.post<Map<String, dynamic>>(
        AppConstants.loginEndpoint,
        data: FormData.fromMap({
          'username': username,
          'password': password,
        }),
      );

      if (response.data == null) {
        throw const AuthException(
          message: 'Invalid response from server',
          code: 'INVALID_RESPONSE',
        );
      }

      final authResponse = AuthResponse.fromJson(response.data!);
      
      // Store authentication data
      await _storeAuthData(authResponse);
      
      return authResponse;
    } on DioException catch (e) {
      throw AuthException.fromApiException(ApiException.fromDioError(e));
    } catch (e) {
      throw AuthException(
        message: 'Login failed: $e',
        code: 'LOGIN_ERROR',
      );
    }
  }

  /// Get current user information from backend
  Future<User> getCurrentUser() async {
    try {
      final response = await ApiService.instance.get<Map<String, dynamic>>(
        AppConstants.meEndpoint,
      );

      if (response.data == null) {
        throw const AuthException(
          message: 'Failed to get user information',
          code: 'USER_INFO_ERROR',
        );
      }

      final user = User.fromJson(response.data!);
      _currentUser = user;
      
      return user;
    } on DioException catch (e) {
      throw AuthException.fromApiException(ApiException.fromDioError(e));
    }
  }

  /// Refresh authentication token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      
      if (refreshToken == null) {
        throw const AuthException(
          message: 'No refresh token available',
          code: 'NO_REFRESH_TOKEN',
        );
      }

      final response = await ApiService.instance.post<Map<String, dynamic>>(
        AppConstants.refreshEndpoint,
        data: {
          'refresh_token': refreshToken,
        },
      );

      if (response.data == null) {
        throw const AuthException(
          message: 'Failed to refresh token',
          code: 'REFRESH_ERROR',
        );
      }

      final authResponse = AuthResponse.fromJson(response.data!);
      await _storeAuthData(authResponse);
    } on DioException catch (e) {
      await logout(); // Clear invalid tokens
      throw AuthException.fromApiException(ApiException.fromDioError(e));
    }
  }

  /// Logout and clear all stored data
  Future<void> logout() async {
    _currentUser = null;
    _currentToken = null;
    
    await ApiService.instance.clearAuthToken();
    await _clearStoredAuth();
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      return isAvailable && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication for current user
  Future<void> enableBiometricAuth() async {
    if (_currentUser == null) {
      throw const AuthException(
        message: 'No user logged in',
        code: 'NO_USER',
      );
    }

    final isAuthenticated = await _localAuth.authenticate(
      localizedReason: 'Enable biometric authentication for PatrolShield',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (isAuthenticated) {
      await _storage.write(
        key: AppConstants.biometricEnabledKey,
        value: 'true',
      );
    } else {
      throw const AuthException(
        message: 'Biometric authentication failed',
        code: 'BIOMETRIC_FAILED',
      );
    }
  }

  /// Login with biometric authentication
  Future<bool> loginWithBiometric() async {
    try {
      final isEnabled = await _storage.read(key: AppConstants.biometricEnabledKey);
      
      if (isEnabled != 'true') {
        throw const AuthException(
          message: 'Biometric authentication not enabled',
          code: 'BIOMETRIC_NOT_ENABLED',
        );
      }

      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access PatrolShield',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await _loadStoredAuth();
        return isAuthenticated && _currentUser != null;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  /// Check if user can access specific role level
  bool canAccess(String requiredRole) {
    if (_currentUser == null) return false;
    
    final userPriority = _currentUser!.rolePriority;
    final requiredPriority = _getRolePriority(requiredRole);
    
    return userPriority >= requiredPriority;
  }

  /// Store authentication data securely
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    _currentUser = authResponse.user;
    _currentToken = authResponse.accessToken;
    
    await ApiService.instance.setAuthToken(authResponse.accessToken);
    
    // Store tokens securely
    await _storage.write(
      key: AppConstants.authTokenKey,
      value: authResponse.accessToken,
    );
    
    if (authResponse.refreshToken != null) {
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: authResponse.refreshToken!,
      );
    }
    
    // Store user data
    await _storage.write(
      key: AppConstants.userDataKey,
      value: _currentUser!.toJson().toString(),
    );
  }

  /// Load stored authentication data
  Future<void> _loadStoredAuth() async {
    try {
      final token = await _storage.read(key: AppConstants.authTokenKey);
      final userDataStr = await _storage.read(key: AppConstants.userDataKey);
      
      if (token != null && userDataStr != null) {
        _currentToken = token;
        await ApiService.instance.setAuthToken(token);
        
        // Try to get current user from backend
        await getCurrentUser();
      }
    } catch (e) {
      // If loading fails, clear stored data
      await _clearStoredAuth();
    }
  }

  /// Clear all stored authentication data
  Future<void> _clearStoredAuth() async {
    await _storage.delete(key: AppConstants.authTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
    await _storage.delete(key: AppConstants.biometricEnabledKey);
  }

  /// Get role priority for comparison
  int _getRolePriority(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 4;
      case 'operations manager':
        return 3;
      case 'site manager':
        return 2;
      case 'supervisor':
        return 1;
      case 'guard':
      case 'mobile guard':
        return 0;
      default:
        return -1;
    }
  }
}