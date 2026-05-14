import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_widget.dart' as lw;

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _firestoreService = FirestoreService();

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to remove "${user.email}" from the system? This only removes their Firestore record.'),
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
        await _firestoreService.deleteUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppConstants.msgUserDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppConstants.msgFailedDeleteUser)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const lw.LoadingWidget(message: 'Loading users...');
          }
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            return lw.AppErrorWidget(
              message: errorMsg.contains('permission-denied')
                  ? 'You do not have permission to view users. Please ensure you are logged in as an admin.'
                  : 'Failed to load users: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const lw.EmptyStateWidget(
              title: 'No users found',
              subtitle: 'No registered users at the moment.',
              icon: Icons.people_outline,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        _roleColor(user.role).withValues(alpha: 0.5),
                    child: Icon(_roleIcon(user.role),
                        color: _roleColor(user.role), size: 22),
                  ),
                  title: Text(user.email,
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _RoleBadge(role: user.role),
                      const SizedBox(height: 2),
                      Text(
                        'Joined: ${_formatDate(user.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: AppTheme.error),
                    tooltip: 'Delete User',
                    onPressed: () => _deleteUser(user),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFCC1016);
      case 'company':
        return const Color(0xFF0A66C2);
      default:
        return const Color(0xFF057642);
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'company':
        return Icons.business;
      default:
        return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin':
        color = const Color(0xFFCC1016);
        break;
      case 'company':
        color = const Color(0xFF0A66C2);
        break;
      default:
        color = const Color(0xFF057642);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
