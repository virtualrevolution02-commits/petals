import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoupleModel {
  final String id;
  final String user1Uid;
  final String user2Uid;
  final String user1Name;
  final String user2Name;
  final String pairingCode;
  final DateTime createdAt;
  final String? anniversaryDate;

  CoupleModel({
    required this.id,
    required this.user1Uid,
    required this.user2Uid,
    required this.user1Name,
    required this.user2Name,
    required this.pairingCode,
    required this.createdAt,
    this.anniversaryDate,
  });

  factory CoupleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoupleModel(
      id: doc.id,
      user1Uid: data['user1Uid'] ?? '',
      user2Uid: data['user2Uid'] ?? '',
      user1Name: data['user1Name'] ?? 'Partner 1',
      user2Name: data['user2Name'] ?? 'Partner 2',
      pairingCode: data['pairingCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      anniversaryDate: data['anniversaryDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Uid': user1Uid,
      'user2Uid': user2Uid,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'pairingCode': pairingCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'anniversaryDate': anniversaryDate,
    };
  }

  String partnerNameFor(String uid) {
    if (uid == user1Uid) return user2Name;
    return user1Name;
  }

  String partnerUidFor(String uid) {
    if (uid == user1Uid) return user2Uid;
    return user1Uid;
  }

  /// Serialize to JSON string for SharedPreferences caching.
  String toJsonString() => jsonEncode({
        'id': id,
        'user1Uid': user1Uid,
        'user2Uid': user2Uid,
        'user1Name': user1Name,
        'user2Name': user2Name,
        'pairingCode': pairingCode,
        'createdAt': createdAt.toIso8601String(),
        'anniversaryDate': anniversaryDate,
      });

  /// Deserialize from JSON string stored in SharedPreferences.
  factory CoupleModel.fromJsonString(String jsonStr) {
    final d = jsonDecode(jsonStr) as Map<String, dynamic>;
    return CoupleModel(
      id: d['id'] ?? '',
      user1Uid: d['user1Uid'] ?? '',
      user2Uid: d['user2Uid'] ?? '',
      user1Name: d['user1Name'] ?? 'Partner 1',
      user2Name: d['user2Name'] ?? 'Partner 2',
      pairingCode: d['pairingCode'] ?? '',
      createdAt: d['createdAt'] != null
          ? DateTime.tryParse(d['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      anniversaryDate: d['anniversaryDate'] as String?,
    );
  }
}
