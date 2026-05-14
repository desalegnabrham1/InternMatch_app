import 'package:flutter/material.dart';
import '../../models/internship_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_widget.dart' as lw;
import '../user/internship_detail_screen.dart';

class ManageInternshipsScreen extends StatefulWidget {
  const ManageInternshipsScreen({super.key});

  @override
  State<ManageInternshipsScreen> createState() =>
      _ManageInternshipsScreenState();
}

class _ManageInternshipsScreenState extends State<ManageInternshipsScreen> {
  final _firestoreService = FirestoreService();

  Future<void> _deleteInternship(InternshipModel internship) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Internship'),
        content: Text(
            'Are you sure you want to delete "${internship.title}" by ${internship.companyName}? This cannot be undone.'),
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
      appBar: AppBar(title: const Text('Manage Internships')),
      body: StreamBuilder<List<InternshipModel>>(
        stream: _firestoreService.getAllInternships(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const lw.LoadingWidget(message: 'Loading internships...');
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
              title: 'No internships found',
              subtitle: 'No internship posts at the moment.',
              icon: Icons.work_off_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: internships.length,
            itemBuilder: (context, index) {
              final item = internships[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InternshipDetailScreen(internship: item),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              item.companyName.isNotEmpty
                                  ? item.companyName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(item.companyName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                  '${item.location}  •  Deadline: ${item.deadline}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.error),
                          tooltip: 'Delete',
                          onPressed: () => _deleteInternship(item),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

