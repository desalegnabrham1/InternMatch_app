import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/internship_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/internship_card.dart';
import '../../widgets/loading_widget.dart' as lw;
import 'internship_detail_screen.dart';

class SavedInternshipsScreen extends StatelessWidget {
  const SavedInternshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Internships')),
      body: StreamBuilder<List<String>>(
        stream: firestoreService.savedInternshipIds(uid),
        builder: (context, idsSnapshot) {
          if (idsSnapshot.connectionState == ConnectionState.waiting) {
            return const lw.LoadingWidget(message: 'Loading saved...');
          }
          final ids = idsSnapshot.data ?? [];
          if (ids.isEmpty) {
            return const lw.EmptyStateWidget(
              title: 'No saved internships',
              subtitle:
                  'Bookmark internships from the detail page to save them here.',
              icon: Icons.bookmark_border_outlined,
            );
          }
          return FutureBuilder<List<InternshipModel>>(
            future: firestoreService.getSavedInternships(ids),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const lw.LoadingWidget(message: 'Loading saved...');
              }
              if (snap.hasError) {
                return const lw.AppErrorWidget(
                    message: 'Failed to load saved internships.');
              }
              final internships = snap.data ?? [];
              if (internships.isEmpty) {
                return const lw.EmptyStateWidget(
                  title: 'No saved internships',
                  subtitle:
                      'Bookmark internships from the detail page to save them here.',
                  icon: Icons.bookmark_border_outlined,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: internships.length,
                itemBuilder: (context, index) {
                  final item = internships[index];
                  return InternshipCard(
                    internship: item,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            InternshipDetailScreen(internship: item),
                      ),
                    ),
                    trailing: StreamBuilder<List<String>>(
                      stream: firestoreService.savedInternshipIds(uid),
                      builder: (context, savedSnap) {
                        final saved = savedSnap.data ?? [];
                        final isSaved = saved.contains(item.id);
                        return IconButton(
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border_outlined,
                          ),
                          color: isSaved ? AppTheme.primary : null,
                          tooltip: isSaved ? 'Remove bookmark' : 'Save',
                          onPressed: () =>
                              firestoreService.toggleBookmark(uid, item.id),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
