import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_role_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../utils/app_theme.dart';
import '../../utils/admin_guard.dart';
import '../auth/login_screen.dart';
import 'manage_users_screen.dart';
import 'manage_internships_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Refresh token on init to ensure custom claims are up-to-date
    _authService.refreshIdToken();
  }

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      fallback: Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppTheme.error),
              SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You do not have admin permissions.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      child: _AdminDashboardContent(authService: _authService),
    );
  }
}

class _AdminDashboardContent extends StatefulWidget {
  final AuthService authService;

  const _AdminDashboardContent({required this.authService});

  @override
  State<_AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<_AdminDashboardContent> {
  Future<void> _signOut() async {
    await widget.authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Admin Panel'),
          ],
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Promote UID to admin (debug)',
              onPressed: () async {
                final ctrl = TextEditingController();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Promote user to admin'),
                    content: TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Target UID',
                        hintText: 'Enter user UID to promote',
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Promote')),
                    ],
                  ),
                );
                if (confirm != true) return;
                final uid = ctrl.text.trim();
                if (uid.isEmpty) return;
                if (!context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                    const SnackBar(content: Text('Promoting...')));
                final success = await AdminRoleService.setUserAdminRole(
                    targetUid: uid, isAdmin: true);
                if (!context.mounted) return;
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(SnackBar(
                    content: Text(
                        success ? 'Promoted to admin' : 'Promotion failed')));
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white, size: 36),
                  SizedBox(height: 10),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage users and internship listings',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Management', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Manage Users card
            _AdminMenuCard(
              icon: Icons.people_alt_outlined,
              title: 'Manage Users',
              subtitle: 'View and manage all registered users',
              color: AppTheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
              ),
            ),
            const SizedBox(height: 12),

            // Manage Internships card
            _AdminMenuCard(
              icon: Icons.work_outline,
              title: 'Manage Internships',
              subtitle: 'Review and delete inappropriate internship posts',
              color: AppTheme.accent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManageInternshipsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
