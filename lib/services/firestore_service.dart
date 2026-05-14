import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/internship_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Internships ──────────────────────────────────────────────────────────

  Stream<List<InternshipModel>> getAllInternships() {
    return _db
        .collection('internships')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InternshipModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<InternshipModel>> getCompanyInternships(String companyUid) {
    return _db
        .collection('internships')
        .where('createdBy', isEqualTo: companyUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => InternshipModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addInternship(InternshipModel internship) async {
    await _db.collection('internships').add(internship.toMap());
  }

  Future<void> updateInternship(InternshipModel internship) async {
    await _db
        .collection('internships')
        .doc(internship.id)
        .update(internship.toMap());
  }

  Future<void> deleteInternship(String id) async {
    await _db.collection('internships').doc(id).delete();
  }

  /// Search internships by keyword and optionally filter by location.
  Future<List<InternshipModel>> searchInternships(
    String query, {
    String? locationFilter,
  }) async {
    final snap = await _db
        .collection('internships')
        .orderBy('createdAt', descending: true)
        .get();

    List<InternshipModel> results =
        snap.docs.map((d) => InternshipModel.fromMap(d.data(), d.id)).toList();

    if (query.trim().isNotEmpty) {
      final lq = query.trim().toLowerCase();
      results = results
          .where((i) =>
              i.title.toLowerCase().contains(lq) ||
              i.companyName.toLowerCase().contains(lq) ||
              i.location.toLowerCase().contains(lq) ||
              i.description.toLowerCase().contains(lq))
          .toList();
    }

    if (locationFilter != null && locationFilter.trim().isNotEmpty) {
      final lf = locationFilter.trim().toLowerCase();
      results =
          results.where((i) => i.location.toLowerCase().contains(lf)).toList();
    }

    return results;
  }

  /// Returns the distinct location strings from all internships for filter UI.
  Future<List<String>> getDistinctLocations() async {
    final snap = await _db.collection('internships').get();
    final locations = snap.docs
        .map((d) => (d.data()['location'] as String? ?? '').trim())
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList();
    locations.sort();
    return locations;
  }

  // ─── Saved / Bookmarked internships ──────────────────────────────────────

  /// Toggle a bookmark: adds the internship ID if not present, removes it if it is.
  Future<void> toggleBookmark(String uid, String internshipId) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) return;
    final saved =
        List<String>.from((snap.data()?['savedInternships'] ?? []) as List);
    if (saved.contains(internshipId)) {
      saved.remove(internshipId);
    } else {
      saved.add(internshipId);
    }
    await ref.update({'savedInternships': saved});
  }

  /// Returns a stream of saved internship IDs for a user.
  Stream<List<String>> savedInternshipIds(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return <String>[];
      return List<String>.from(
          (snap.data()?['savedInternships'] ?? []) as List);
    });
  }

  /// Returns the full InternshipModel objects a user has saved.
  Future<List<InternshipModel>> getSavedInternships(
      List<String> internshipIds) async {
    if (internshipIds.isEmpty) return [];
    // Firestore 'whereIn' is limited to 30 items per query.
    final chunks = <List<String>>[];
    for (var i = 0; i < internshipIds.length; i += 30) {
      chunks.add(internshipIds.sublist(
          i, i + 30 > internshipIds.length ? internshipIds.length : i + 30));
    }
    final results = <InternshipModel>[];
    for (final chunk in chunks) {
      final snap = await _db
          .collection('internships')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
          snap.docs.map((d) => InternshipModel.fromMap(d.data(), d.id)));
    }
    return results;
  }

  // ─── Users ────────────────────────────────────────────────────────────────

  Stream<List<UserModel>> getAllUsers() {
    return _db.collection('users').snapshots().map((snap) {
      final users =
          snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
      // Sort in the app instead of relying on Firestore orderBy
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  /// Update mutable profile fields for any user role.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  String get currentUid => _auth.currentUser?.uid ?? '';

  // ─── Chat / Messaging ─────────────────────────────────────────────────────

  /// Deterministic conversation ID: always sort so both users get the same doc.
  String conversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Get or create a conversation document between two users.
  Future<ConversationModel> getOrCreateConversation({
    required String myUid,
    required String myEmail,
    required String myRole,
    required String otherUid,
    required String otherEmail,
    required String otherRole,
  }) async {
    final docId = conversationId(myUid, otherUid);
    final ref = _db.collection('chats').doc(docId);
    try {
      // Avoid an initial read which may be denied for non-existing docs.
      final partial = {
        'participants': [myUid, otherUid],
        'participantEmails': {myUid: myEmail, otherUid: otherEmail},
        'participantRoles': {myUid: myRole, otherUid: otherRole},
        'unreadCount': {myUid: 0, otherUid: 0},
        'lastMessage': '',
        'lastMessageAt': Timestamp.fromDate(DateTime.now()),
      };

      // Create the doc if missing, or merge participants/emails if exists.
      await ref.set(partial, SetOptions(merge: true));

      // Construct a ConversationModel locally to avoid a read that may be denied.
      final conv = ConversationModel(
        id: docId,
        participants: [myUid, otherUid],
        participantEmails: {myUid: myEmail, otherUid: otherEmail},
        participantRoles: {myUid: myRole, otherUid: otherRole},
        lastMessage: '',
        lastMessageAt: DateTime.now(),
        unreadCount: {myUid: 0, otherUid: 0},
      );
      return conv;
    } on FirebaseException catch (e) {
      // Provide the error code in the thrown exception for clearer UI feedback.
      // ignore: avoid_print
      print('getOrCreateConversation failed (${e.code}): ${e.message}');
      throw FirebaseException(
          plugin: e.plugin, message: '[${e.code}] ${e.message}');
    }
  }

  /// Stream all conversations for the current user, ordered by most recent.
  Stream<List<ConversationModel>> getConversations(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ConversationModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream messages inside a conversation.
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _db
        .collection('chats')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Send a message and update conversation metadata.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      if (receiverId.trim().isEmpty) {
        throw FirebaseException(
            plugin: 'cloud_firestore',
            message: 'ReceiverId is empty for conversation $conversationId');
      }

      final convRef = _db.collection('chats').doc(conversationId);
      await convRef.set(
        {
          'participants': [senderId, receiverId],
          'unreadCount': {senderId: 0, receiverId: 0},
          'lastMessage': '',
          'lastMessageAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );

      final batch = _db.batch();
      final msgRef = convRef.collection('messages').doc();

      final message = MessageModel(
        id: msgRef.id,
        senderId: senderId,
        text: text.trim(),
        sentAt: DateTime.now(),
        isRead: false,
      );

      batch.set(msgRef, message.toMap());

      final updateMap = <String, Object>{
        'lastMessage': text.trim(),
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
      };
      updateMap['unreadCount.$receiverId'] = FieldValue.increment(1);

      batch.update(convRef, updateMap);
      await batch.commit();
    } on FirebaseException catch (e) {
      // Surface Firestore errors with helpful message.
      // ignore: avoid_print
      print('Firestore sendMessage failed (${e.code}): ${e.message}');
      rethrow;
    }
  }

  /// Mark all unread messages in a conversation as read for a user.
  Future<void> markAsRead(String conversationId, String uid) async {
    final convRef = _db.collection('chats').doc(conversationId);
    try {
      await convRef.update({'unreadCount.$uid': 0});
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        await convRef.set(
          {
            'participants': [uid],
            'participantEmails': <String, String>{},
            'participantRoles': <String, String>{},
            'unreadCount': {uid: 0},
            'lastMessage': '',
            'lastMessageAt': Timestamp.fromDate(DateTime.now()),
          },
          SetOptions(merge: true),
        );
      } else {
        rethrow;
      }
    }

    // Also mark individual messages as read (for future use).
    final unread = await convRef
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      if ((doc.data()['senderId'] as String?) != uid) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    if (unread.docs.isNotEmpty) await batch.commit();
  }

  /// Total unread message count across all conversations for a user.
  Stream<int> totalUnreadCount(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.fold<int>(0, (total, d) {
              final data = d.data();
              final counts =
                  Map<String, dynamic>.from(data['unreadCount'] ?? {});
              return total + ((counts[uid] as num?)?.toInt() ?? 0);
            }));
  }
}
