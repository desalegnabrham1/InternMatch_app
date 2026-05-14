import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to call Cloud Functions for admin role assignment.
/// Works with the setAdminRole Cloud Function (see ADMIN_SETUP.md).
class AdminRoleService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Promote/demote a user to admin.
  /// Only admins can call this. Server verifies via custom claims.
  ///
  /// Example:
  /// ```dart
  /// final success = await AdminRoleService.setUserAdminRole(
  ///   targetUid: 'user123',
  ///   isAdmin: true,
  /// );
  /// ```
  static Future<bool> setUserAdminRole({
    required String targetUid,
    required bool isAdmin,
  }) async {
    try {
      final callable = _functions.httpsCallable('setAdminRole');
      final result = await callable.call({
        'uid': targetUid,
        'isAdmin': isAdmin,
      });

      // Refresh the current user's token to pick up changes
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.getIdToken(true);
      }

      final data = result.data;
      if (data is Map) {
        return data['success'] == true;
      }

      return false;
    } catch (e, st) {
      developer.log(
        'Error setting admin role',
        name: 'AdminRoleService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Get all admin users (if a Cloud Function exists for this).
  /// Customize based on your backend.
  static Future<List<String>> getAdminUsers() async {
    try {
      final callable = _functions.httpsCallable('getAdminUsers');
      final result = await callable.call();
      final data = result.data;
      if (data is Map) {
        return List<String>.from(data['adminUids'] ?? const <String>[]);
      }

      return [];
    } catch (e, st) {
      developer.log(
        'Error fetching admin users',
        name: 'AdminRoleService',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Revoke admin access for a user.
  static Future<bool> revokeAdminRole(String targetUid) async {
    return setUserAdminRole(targetUid: targetUid, isAdmin: false);
  }
}
