import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../screens/chat/conversations_screen.dart';

/// An icon button that shows a red badge with the total unread message count.
/// Used in both the User and Company app bars to avoid code duplication.
class UnreadBadgeIcon extends StatelessWidget {
  final FirestoreService firestoreService;
  final String uid;

  const UnreadBadgeIcon({
    super.key,
    required this.firestoreService,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: firestoreService.totalUnreadCount(uid),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Messages',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ConversationsScreen()),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
