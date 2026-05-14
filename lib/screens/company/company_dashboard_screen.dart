import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/internship_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_widget.dart' as lw;
import '../../widgets/unread_badge_icon.dart';
import '../auth/login_screen.dart';
import 'add_internship_screen.dart';
import 'company_profile_screen.dart';
import 'edit_internship_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteInternship(InternshipModel internship) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Internship'),
        content: Text(
            'Are you sure you want to delete "${internship.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _firestoreService.deleteInternship(internship.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppConstants.msgInternshipDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppConstants.msgFailedDelete)),
          );
        }
      }
    }
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
              child: const Icon(Icons.business, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Company Dashboard'),
          ],
        ),
        actions: [
          UnreadBadgeIcon(
            firestoreService: _firestoreService,
            uid: _uid,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Internship',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddInternshipScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.business_outlined),
            tooltip: 'Company Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddInternshipScreen()),
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Internship',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.business_center, color: Colors.white, size: 36),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Internship Posts',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Manage your internship listings here',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('My Listings',
                style: Theme.of(context).textTheme.titleMedium),
          ),

          Expanded(
            child: StreamBuilder<List<InternshipModel>>(
              stream: _firestoreService.getCompanyInternships(_uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const lw.LoadingWidget(
                      message: 'Loading your listings...');
                }
                if (snapshot.hasError) {
                  return lw.AppErrorWidget(
                    message: 'Failed to load listings.',
                    onRetry: () => setState(() {}),
                  );
                }
                final internships = snapshot.data ?? [];
                if (internships.isEmpty) {
                  return lw.EmptyStateWidget(
                    title: 'No listings yet',
                    subtitle: 'Post your first internship to get started.',
                    icon: Icons.work_off_outlined,
                    action: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddInternshipScreen()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Post Internship'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: internships.length,
                  itemBuilder: (context, index) {
                    final item = internships[index];
                    return _CompanyInternshipCard(
                      internship: item,
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditInternshipScreen(internship: item),
                        ),
                      ),
                      onDelete: () => _deleteInternship(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyInternshipCard extends StatelessWidget {
  final InternshipModel internship;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompanyInternshipCard({
    required this.internship,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      internship.companyName.isNotEmpty
                          ? internship.companyName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(internship.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(internship.location,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text('Deadline: ${internship.deadline}',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              internship.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppTheme.error),
                  label: const Text('Delete',
                      style: TextStyle(color: AppTheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
