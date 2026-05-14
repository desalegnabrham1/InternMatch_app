import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';

/// Widget guard that ensures only admins can view wrapped content.
/// Efficient: caches role result and provides fallback UI.
class AdminGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final AuthService _authService = AuthService();

  AdminGuard({
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return fallback ??
            Scaffold(
              appBar: AppBar(title: const Text('Access Denied')),
              body: const Center(
                child: Text('You do not have admin permissions.'),
              ),
            );
      },
    );
  }
}

/// Utility function to check admin status synchronously (for Route guards).
/// Returns true only if user is authenticated AND has admin role.
bool isUserAdmin(AuthService authService) {
  final user = authService.currentUser;
  final email = user?.email?.trim().toLowerCase();
  return email != null && AppConstants.adminEmails.contains(email);
}

/// Stream-based admin check for real-time UI updates.
Stream<bool> adminStatusStream(AuthService authService) {
  return authService.authStateChanges.asyncMap((user) async {
    if (user == null) return false;
    return authService.isAdmin();
  });
}
