import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// User model representing authenticated users
@JsonSerializable()
class User {
  final int id;
  final String username;
  final String email;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String role;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final List<String>? permissions;
  @JsonKey(name: 'assigned_sites')
  final List<int>? assignedSites;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.permissions,
    this.assignedSites,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Get display name
  String get displayName => fullName;

  /// Check if user is a guard
  bool get isGuard => role.toLowerCase() == 'guard' || role.toLowerCase() == 'mobile guard';

  /// Check if user is a supervisor
  bool get isSupervisor => role.toLowerCase() == 'supervisor';

  /// Check if user is a site manager
  bool get isSiteManager => role.toLowerCase() == 'site manager';

  /// Check if user is an admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return permissions?.contains(permission) ?? false;
  }

  /// Get role priority (higher number = more permissions)
  int get rolePriority {
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

  /// Check if user can access specific role level
  bool canAccess(String requiredRole) {
    final userPriority = rolePriority;
    final requiredPriority = _getRolePriority(requiredRole);
    
    return userPriority >= requiredPriority;
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

  @override
  String toString() {
    return 'User(id: $id, username: $username, role: $role, displayName: $displayName)';
  }
}

/// Authentication response model
@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  final User user;
  @JsonKey(name: 'device_registered')
  final bool deviceRegistered;
  @JsonKey(name: 'offline_data')
  final Map<String, dynamic>? offlineData;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.deviceRegistered,
    this.offlineData,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => 
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  @override
  String toString() {
    return 'AuthResponse(tokenType: $tokenType, expiresIn: $expiresIn, user: ${user.username})';
  }
}