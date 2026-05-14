import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/internship_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../chat/chat_screen.dart';

class InternshipDetailScreen extends StatelessWidget {
  final InternshipModel internship;

  const InternshipDetailScreen({super.key, required this.internship});

  Future<void> _launchEmail(BuildContext context) async {
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgNoEmailApp)),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Opening email is not supported in this build.')),
      );
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppConstants.msgNoDialer)),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dialer not available in this build.')),
      );
    }
  }

  Future<void> _messageCompany(BuildContext context) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;

    final companyUid = internship.createdBy.trim();
    if (companyUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This internship is missing company info.'),
        ),
      );
      return;
    }

    final firestoreService = FirestoreService();
    final myEmail = me.email ?? '';
    const myRole = AppConstants.roleUser;
    final companyEmail = internship.contactEmail.trim().isNotEmpty
        ? internship.contactEmail.trim()
        : 'company';
    const companyRole = AppConstants.roleCompany;

    final conv = await firestoreService.getOrCreateConversation(
      myUid: me.uid,
      myEmail: myEmail,
      myRole: myRole,
      otherUid: companyUid,
      otherEmail: companyEmail,
      otherRole: companyRole,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Internship Detail'),
        actions: [
          // Bookmark toggle
          StreamBuilder<List<String>>(
            stream: firestoreService.savedInternshipIds(uid),
            builder: (context, snap) {
              final saved = snap.data ?? [];
              final isSaved = saved.contains(internship.id);
              return IconButton(
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                tooltip: isSaved ? 'Remove bookmark' : 'Save',
                onPressed: () async {
                  await firestoreService.toggleBookmark(uid, internship.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isSaved
                            ? AppConstants.msgBookmarkRemoved
                            : AppConstants.msgBookmarkAdded),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              internship.companyName.isNotEmpty
                                  ? internship.companyName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(internship.title,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(internship.companyName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: internship.location),
                    const SizedBox(height: 8),
                    _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Deadline',
                        value: internship.deadline),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            _SectionCard(
              title: 'About the Role',
              child: Text(internship.description,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(height: 12),

            // Requirements
            _SectionCard(
              title: 'Requirements',
              child: Text(internship.requirement,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(height: 20),

            // Apply buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apply Now',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Contact the company directly to apply.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    if (internship.contactEmail.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _launchEmail(context),
                        icon: const Icon(Icons.email_outlined),
                        label: Text('Email: ${internship.contactEmail}'),
                      ),
                    if (internship.contactPhone.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _launchPhone(context),
                        icon: const Icon(Icons.phone_outlined),
                        label: Text('Call: ${internship.contactPhone}'),
                      ),
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _messageCompany(context),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message Company'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
