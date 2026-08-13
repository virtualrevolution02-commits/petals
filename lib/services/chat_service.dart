import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of realtime messages for a couple, sorted by createdAt descending
  Stream<List<MessageModel>> watchMessages(String coupleId) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  /// Send a new message or love note
  Future<void> sendMessage({
    required String coupleId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      await _firestore
          .collection('couples')
          .doc(coupleId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// React to a message with an emoji sticker
  Future<void> addReaction({
    required String coupleId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _firestore
          .collection('couples')
          .doc(coupleId)
          .collection('messages')
          .doc(messageId)
          .update({'emojiReaction': emoji});
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }
}
