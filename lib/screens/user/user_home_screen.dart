import 'package:flutter/material.dart';
import '../../models/internship_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/internship_card.dart';
import '../../widgets/loading_widget.dart' as lw;
import '../../widgets/unread_badge_icon.dart';
import '../auth/login_screen.dart';
import 'internship_detail_screen.dart';
import 'saved_internships_screen.dart';
import 'search_screen.dart';
import 'user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _firestoreService.currentUid;
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
              child:
                  const Icon(Icons.work_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(AppConstants.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_outlined),
            tooltip: 'Saved Internships',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedInternshipsScreen()),
            ),
          ),
          UnreadBadgeIcon(
            firestoreService: _firestoreService,
            uid: uid,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find Your Internship',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Discover opportunities that match your skills',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search,
                            color: AppTheme.textSecondary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Search internships...',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Latest Opportunities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),

          // Internship feed
          Expanded(
            child: StreamBuilder<List<InternshipModel>>(
              stream: _firestoreService.getAllInternships(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const lw.LoadingWidget(
                      message: 'Loading internships...');
                }
                if (snapshot.hasError) {
                  return lw.AppErrorWidget(
                    message: 'Failed to load internships.',
                    onRetry: () => setState(() {}),
                  );
                }
                final internships = snapshot.data ?? [];
                if (internships.isEmpty) {
                  return const lw.EmptyStateWidget(
                    title: 'No internships yet',
                    subtitle: 'Check back later for new opportunities.',
                    icon: Icons.work_off_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: internships.length,
                  itemBuilder: (context, index) {
                    final item = internships[index];
                    return StreamBuilder<List<String>>(
                      stream: _firestoreService.savedInternshipIds(uid),
                      builder: (context, savedSnap) {
                        final savedIds = savedSnap.data ?? [];
                        final isSaved = savedIds.contains(item.id);
                        return InternshipCard(
                          internship: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  InternshipDetailScreen(internship: item),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border_outlined,
                              size: 22,
                            ),
                            color: isSaved ? AppTheme.primary : null,
                            tooltip: isSaved ? 'Remove bookmark' : 'Save',
                            onPressed: () =>
                                _firestoreService.toggleBookmark(uid, item.id),
                          ),
                        );
                      },
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
