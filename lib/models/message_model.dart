import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final String? imageUrl;
  final String? emojiReaction;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.imageUrl,
    this.emojiReaction,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (emojiReaction != null) 'emojiReaction': emojiReaction,
    };
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      emojiReaction: data['emojiReaction'],
    );
  }
}
