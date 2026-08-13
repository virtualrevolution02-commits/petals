import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String id;
  final String fromUid;
  final String fromName;
  final String fromUsername;
  final String toUid;
  final String toUsername;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromUsername,
    required this.toUid,
    required this.toUsername,
    this.status = 'pending',
    required this.createdAt,
  });

  factory FriendRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendRequestModel(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      fromName: data['fromName'] ?? '',
      fromUsername: data['fromUsername'] ?? '',
      toUid: data['toUid'] ?? '',
      toUsername: data['toUsername'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUid': fromUid,
      'fromName': fromName,
      'fromUsername': fromUsername,
      'toUid': toUid,
      'toUsername': toUsername,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
