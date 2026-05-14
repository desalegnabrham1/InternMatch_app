import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isRead,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
    };
  }
}

class ConversationModel {
  final String id; // sorted join of two UIDs: "uid1_uid2"
  final List<String> participants; // [uid1, uid2]
  final Map<String, String> participantEmails; // {uid: email}
  final Map<String, String> participantRoles; // {uid: role}
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount; // {uid: count}

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantEmails,
    required this.participantRoles,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConversationModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantEmails:
          Map<String, String>.from(map['participantEmails'] ?? {}),
      participantRoles: Map<String, String>.from(map['participantRoles'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt:
          (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(
        (map['unreadCount'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantEmails': participantEmails,
      'participantRoles': participantRoles,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadCount': unreadCount,
    };
  }

  /// Return the other participant's uid (not current user).
  String otherUid(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => '');

  String otherEmail(String myUid) =>
      participantEmails[otherUid(myUid)] ?? 'Unknown';

  String otherRole(String myUid) =>
      participantRoles[otherUid(myUid)] ?? 'user';
}
