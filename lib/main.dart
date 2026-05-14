import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/company/company_dashboard_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';
import 'utils/app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InternMatchApp());
}

class InternMatchApp extends StatelessWidget {
  const InternMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _resolveHome(AuthService authService) async {
    if (await authService.isAdmin()) {
      return const AdminDashboardScreen();
    }

    final role = await authService.getUserRole();
    switch (role) {
      case AppConstants.roleCompany:
        return const CompanyDashboardScreen();
      default:
        return const UserHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<Widget>(
          future: _resolveHome(authService),
          builder: (context, homeSnapshot) {
            if (homeSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.background,
                body: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              );
            }

            return homeSnapshot.data ?? const UserHomeScreen();
          },
        );
      },
    );
  }
}
