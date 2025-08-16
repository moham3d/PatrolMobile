import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Widget that shows content based on user role and permissions
class RoleBasedWidget extends ConsumerWidget {
  final Widget child;
  final List<String>? allowedRoles;
  final List<String>? requiredPermissions;
  final Widget? fallback;
  final bool showFallback;

  const RoleBasedWidget({
    super.key,
    required this.child,
    this.allowedRoles,
    this.requiredPermissions,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    if (authState is! Authenticated) {
      return showFallback ? (fallback ?? const SizedBox.shrink()) : const SizedBox.shrink();
    }

    final user = authState.user;
    bool hasAccess = true;

    // Check role-based access
    if (allowedRoles != null && allowedRoles!.isNotEmpty) {
      hasAccess = allowedRoles!.any((role) => 
        authNotifier.canAccess(role) || 
        user.role.toLowerCase() == role.toLowerCase()
      );
    }

    // Check permission-based access
    if (hasAccess && requiredPermissions != null && requiredPermissions!.isNotEmpty) {
      hasAccess = requiredPermissions!.every((permission) => 
        authNotifier.hasPermission(permission)
      );
    }

    if (hasAccess) {
      return child;
    }

    return showFallback ? (fallback ?? _buildNoAccessWidget(context)) : const SizedBox.shrink();
  }

  Widget _buildNoAccessWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.orange.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Access restricted. Insufficient permissions for your role.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for supervisor and above access
class SupervisorOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const SupervisorOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: const ['supervisor', 'site manager', 'admin'],
      fallback: fallback,
      showFallback: showFallback,
      child: child,
    );
  }
}

/// Helper widget for site manager and above access
class ManagerOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const ManagerOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: const ['site manager', 'admin'],
      fallback: fallback,
      showFallback: showFallback,
      child: child,
    );
  }
}

/// Helper widget for admin only access
class AdminOnlyWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const AdminOnlyWidget({
    super.key,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    return RoleBasedWidget(
      allowedRoles: const ['admin'],
      fallback: fallback,
      showFallback: showFallback,
      child: child,
    );
  }
}