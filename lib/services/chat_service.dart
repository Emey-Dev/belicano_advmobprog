import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:belicano_advmobprog/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();

        return user;
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) throw StateError('You must be signed in to chat.');

    final String currentUserId = currentUser.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();

    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      status: 'sent',
    );

    final chatRoomID = _chatRoomId(currentUserId, receiverId);
    await _ensureChatRoom(chatRoomID, currentUserId, receiverId);

    // add new message to database
    await _firestore
        .collection("chat")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get message
  Stream<QuerySnapshot> getMessage(String userID, otherUserID) {
    final chatRoomID = _chatRoomId(userID, otherUserID);

    return _firestore
        .collection("chat")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<bool> getTypingStream(String userID, String otherUserID) {
    final chatRoomID = _chatRoomId(userID, otherUserID);
    return _firestore
        .collection('chat')
        .doc(chatRoomID)
        .collection('typing')
        .doc(otherUserID)
        .snapshots()
        .map((snapshot) => snapshot.data()?['isTyping'] == true);
  }

  Future<void> setTyping(String receiverId, bool isTyping) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;

    final chatRoomID = _chatRoomId(currentUser.uid, receiverId);
    if (isTyping) {
      await _ensureChatRoom(chatRoomID, currentUser.uid, receiverId);
    }
    await _firestore
        .collection('chat')
        .doc(chatRoomID)
        .collection('typing')
        .doc(currentUser.uid)
        .set({'isTyping': isTyping, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> markMessagesSeen(String userID, String otherUserID) async {
    final chatRoomID = _chatRoomId(userID, otherUserID);
    final snapshot = await _firestore
        .collection('chat')
        .doc(chatRoomID)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    var updates = 0;

    for (final document in snapshot.docs) {
      final data = document.data();
      if (data['receiverId'] == userID && data['status'] != 'seen') {
        batch.update(document.reference, {'status': 'seen'});
        updates++;
      }
    }

    if (updates > 0) await batch.commit();
  }

  String _chatRoomId(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return ids.join('_');
  }

  Future<void> _ensureChatRoom(
    String chatRoomID,
    String firstUserId,
    String secondUserId,
  ) {
    return _firestore.collection('chat').doc(chatRoomID).set({
      'participants': [firstUserId, secondUserId],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    // Ensure your Users doc actually stores the Firebase Auth UID in a field 'uid'
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}
