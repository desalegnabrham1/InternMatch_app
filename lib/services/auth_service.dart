import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Fetch role from custom claims (fast) or Firestore fallback.
  /// Efficient: checks custom claims first, then Firestore if needed.
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      if (_isWhitelistedAdminEmail(user.email)) {
        return AppConstants.roleAdmin;
      }

      // 1. Try custom claims first (no Firestore read, instant)
      final idTokenResult = await user.getIdTokenResult();
      if (idTokenResult.claims?['admin'] == true) {
        return AppConstants.roleAdmin;
      }
      final customRole = idTokenResult.claims?['role']?.toString();
      if (customRole != null) {
        return _normalizeRole(customRole);
      }

      // 2. Fallback: read from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (_isWhitelistedAdminEmail(data?['email']?.toString())) {
          return AppConstants.roleAdmin;
        }
        if (data?['isAdmin'] == true) {
          return AppConstants.roleAdmin;
        }
        final role = _normalizeRole(data?['role']?.toString());
        if (role != null) {
          return role;
        }

        final hasCompanyProfile = _hasAnyValue(data, [
          'companyName',
          'website',
          'description',
        ]);
        if (hasCompanyProfile) {
          return AppConstants.roleCompany;
        }

        final hasStudentProfile = _hasAnyValue(data, [
          'fullName',
          'headline',
          'skills',
        ]);
        if (hasStudentProfile) {
          return AppConstants.roleUser;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Check if current user is admin (via custom claims).
  /// Efficient: single ID token call, no Firestore reads.
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      if (_isWhitelistedAdminEmail(user.email)) {
        return true;
      }

      final idTokenResult = await user.getIdTokenResult();
      if (idTokenResult.claims?['admin'] == true) {
        return true;
      }

      final claimRole = idTokenResult.claims?['role']?.toString();
      if (_normalizeRole(claimRole) == AppConstants.roleAdmin) {
        return true;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      if (_isWhitelistedAdminEmail(data?['email']?.toString())) {
        return true;
      }
      return data?['isAdmin'] == true ||
          _normalizeRole(data?['role']?.toString()) == AppConstants.roleAdmin;
    } catch (_) {
      return false;
    }
  }

  /// Refresh ID token to pick up new custom claims or role changes.
  /// Call this after role is updated server-side.
  Future<void> refreshIdToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.getIdToken(true);
      } catch (_) {}
    }
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, user.uid);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      // Ensure a Firestore user document exists and apply whitelist admin role if configured.
      final user = credential.user;
      if (user != null) {
        try {
          final docRef = _firestore.collection('users').doc(user.uid);
          final doc = await docRef.get();
          final isWhitelisted = _isWhitelistedAdminEmail(user.email);
          if (!doc.exists) {
            final Map<String, Object?> data = {
              'email': normalizedEmail,
              'role': isWhitelisted
                  ? AppConstants.roleAdmin
                  : AppConstants.roleUser,
              'isAdmin': isWhitelisted,
              'createdAt': FieldValue.serverTimestamp(),
            };
            await docRef.set(data);
          } else if (isWhitelisted) {
            // Promote to admin in Firestore if whitelist and not already admin.
            final existing = doc.data();
            final existingRole = existing?['role']?.toString();
            final existingIsAdmin = existing?['isAdmin'] == true;
            if (existingRole != AppConstants.roleAdmin || !existingIsAdmin) {
              await docRef.update({
                'role': AppConstants.roleAdmin,
                'isAdmin': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
          // If Auth user has no displayName but Firestore doc has one, copy it to Auth profile
          try {
            final currentUser = _auth.currentUser;
            if (currentUser != null &&
                (currentUser.displayName == null ||
                    currentUser.displayName!.trim().isEmpty)) {
              final docData = doc.exists ? doc.data() : null;
              final displayName = docData != null
                  ? (docData['fullName'] ?? docData['companyName'])
                  : null;
              if (displayName != null &&
                  displayName.toString().trim().isNotEmpty) {
                await currentUser
                    .updateDisplayName(displayName.toString().trim());
                await currentUser.reload();
              }
            }
          } catch (_) {}
        } catch (_) {
          // Ignore Firestore write errors (security rules may block client-side role writes).
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-login-credentials') {
        return 'Wrong password for this Firebase Authentication account. Reset the password or recreate the Auth user with a known password.';
      }
      if (e.code == 'user-not-found') {
        return 'No Firebase Authentication account exists for this email.';
      }
      if (e.code == 'user-disabled') {
        return 'This Firebase Authentication account is disabled.';
      }
      if (e.code == 'operation-not-allowed') {
        return 'Email/password sign-in is disabled in Firebase Authentication. Enable it in the Firebase Console.';
      }
      if (e.code == 'invalid-email') {
        return 'The email address format is invalid.';
      }
      return _mapAuthError(e.code);
    } on FirebaseException catch (e) {
      return _mapFirebaseError(e.code, e.message);
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<String?> register(String email, String password, String role,
      [Map<String, Object?>? profileData]) async {
    User? createdUser;
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        return 'Account creation failed. Please try again.';
      }
      // If a display name is available in profileData, update the Auth user profile
      try {
        final displayName = profileData != null
            ? (profileData['fullName'] ?? profileData['companyName'])
                ?.toString()
            : null;
        if (displayName != null && displayName.trim().isNotEmpty) {
          await createdUser.updateDisplayName(displayName.trim());
          await createdUser.reload();
        }
      } catch (_) {}
      final Map<String, Object?> data = {
        'email': normalizedEmail,
        'role': _normalizeRole(role) ?? role.trim().toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (profileData != null) {
        data.addAll(profileData);
      }
      await _firestore.collection('users').doc(createdUser.uid).set(data);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } on FirebaseException catch (e) {
      if (createdUser != null) {
        try {
          await _firestore.collection('users').doc(createdUser.uid).delete();
        } catch (_) {}
        try {
          await createdUser.delete();
        } catch (_) {}
        try {
          await _auth.signOut();
        } catch (_) {}
      }
      return _mapFirebaseError(e.code, e.message);
    } catch (e) {
      if (createdUser != null) {
        try {
          await _firestore.collection('users').doc(createdUser.uid).delete();
        } catch (_) {}
        try {
          await createdUser.delete();
        } catch (_) {}
        try {
          await _auth.signOut();
        } catch (_) {}
      }
      return 'Registration failed: $e';
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (_) {}
  }

  // Google sign-in using `google_sign_in` package.
  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});

        final result = await _auth.signInWithPopup(provider);
        final user = result.user!;
        try {
          final docRef = _firestore.collection('users').doc(user.uid);
          final doc = await docRef.get();
          if (!doc.exists) {
            await docRef.set({
              'email': user.email,
              'role': AppConstants.roleUser,
              'createdAt': FieldValue.serverTimestamp(),
              'fullName': user.displayName ?? '',
            });
          }
        } catch (_) {
          // Keep Google sign-in successful even if profile creation is blocked.
        }

        return null;
      }

      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) return 'Sign-in aborted.';
      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      final user = result.user!;
      try {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'email': user.email,
            'role': AppConstants.roleUser,
            'createdAt': FieldValue.serverTimestamp(),
            'fullName': user.displayName ?? '',
          });
        }
      } catch (_) {
        // Keep Google sign-in successful even if profile creation is blocked.
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        return 'Google sign-in is not enabled in Firebase Authentication. Enable the Google provider in the Firebase Console.';
      }
      return 'Google sign-in failed: ${e.code}${e.message != null ? ' - ${e.message}' : ''}';
    } on FirebaseException catch (e) {
      return _mapFirebaseError(e.code, e.message);
    } catch (e) {
      return 'Google sign-in failed: $e';
    }
  }

  // GitHub sign-in: web popup is supported; mobile requires a server-side
  // OAuth flow or an external browser + credential exchange configured
  // with Firebase. This implementation uses the web popup when available
  // and returns a helpful message on mobile.
  Future<String?> signInWithGitHub() async {
    try {
      if (kIsWeb) {
        final provider = GithubAuthProvider();
        final result = await _auth.signInWithPopup(provider);
        final user = result.user!;
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'role': AppConstants.roleCompany,
            'createdAt': FieldValue.serverTimestamp(),
            'fullName': user.displayName ?? '',
          });
        }
        return null;
      }

      return 'GitHub sign-in requires additional platform configuration. Follow Firebase docs to set up GitHub OAuth for mobile.';
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'GitHub sign-in failed.';
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Invalid email or password. Ensure this account exists in Firebase Authentication (Firestore users data alone is not enough).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Authentication.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  String _mapFirebaseError(String code, String? message) {
    switch (code) {
      case 'permission-denied':
        return 'Firestore access denied. Check your Firestore rules.';
      case 'not-found':
        return 'Required data was not found.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'unauthenticated':
        return 'You are not authenticated. Please sign in again.';
      case 'internal':
        return 'Firebase internal error. Please try again.';
      default:
        if (message != null && message.isNotEmpty) {
          return message;
        }
        return 'Firebase error: $code';
    }
  }

  String? _normalizeRole(String? role) {
    if (role == null) return null;
    final normalized = role.trim().toLowerCase();
    if (normalized == AppConstants.roleUser ||
        normalized == AppConstants.roleCompany ||
        normalized == AppConstants.roleAdmin) {
      return normalized;
    }
    return null;
  }

  bool _hasAnyValue(Map<String, dynamic>? data, List<String> keys) {
    if (data == null) return false;
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return true;
      }
      if (value is Iterable && value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _isWhitelistedAdminEmail(String? email) {
    if (email == null) return false;
    return AppConstants.adminEmails.contains(email.trim().toLowerCase());
  }
}
