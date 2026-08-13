import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel {
  final String id;
  final String user1Uid;
  final String user2Uid;
  final DateTime createdAt;

  FriendModel({
    required this.id,
    required this.user1Uid,
    required this.user2Uid,
    required this.createdAt,
  });

  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendModel(
      id: doc.id,
      user1Uid: data['user1Uid'] ?? '',
      user2Uid: data['user2Uid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Uid': user1Uid,
      'user2Uid': user2Uid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String friendUidOf(String currentUid) {
    return currentUid == user1Uid ? user2Uid : user1Uid;
  }
}
