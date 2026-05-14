import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/loading_widget.dart' as lw;
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: firestoreService.getConversations(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const lw.LoadingWidget(message: 'Loading messages...');
          }
          if (snapshot.hasError) {
            return const lw.AppErrorWidget(
              message: 'Failed to load messages.',
            );
          }
          final conversations = snapshot.data ?? [];
          if (conversations.isEmpty) {
            return const lw.EmptyStateWidget(
              title: 'No messages yet',
              subtitle: 'Start a conversation from an internship listing.',
              icon: Icons.chat_bubble_outline,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherEmail = conv.otherEmail(uid);
              final otherRole = conv.otherRole(uid);
              final unread = conv.unreadCount[uid] ?? 0;
              final hasUnread = unread > 0;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: _Avatar(email: otherEmail, role: otherRole),
                title: Text(
                  otherEmail,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  conv.lastMessage.isEmpty
                      ? 'No messages yet'
                      : conv.lastMessage,
                  style: TextStyle(
                    color: hasUnread
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(conv.lastMessageAt),
                      style: TextStyle(
                          fontSize: 11,
                          color: hasUnread
                              ? AppTheme.primary
                              : AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    if (hasUnread)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversation: conv),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year % 100}';
    }
  }
}

class _Avatar extends StatelessWidget {
  final String email;
  final String role;

  const _Avatar({required this.email, required this.role});

  @override
  Widget build(BuildContext context) {
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final color =
        role == 'company' ? AppTheme.primary : const Color(0xFF057642);
    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withValues(alpha: 0.5),
      child: Text(
        initial,
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}

