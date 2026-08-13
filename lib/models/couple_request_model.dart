import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, rejected }

class CoupleRequestModel {
  final String id;
  final String fromUid;
  final String fromName;
  final String fromUsername;
  final String? fromPhoto;
  final String toUid;
  final String toUsername;
  final RequestStatus status;
  final DateTime createdAt;

  CoupleRequestModel({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromUsername,
    this.fromPhoto,
    required this.toUid,
    required this.toUsername,
    required this.status,
    required this.createdAt,
  });

  factory CoupleRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoupleRequestModel(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      fromName: data['fromName'] ?? '',
      fromUsername: data['fromUsername'] ?? '',
      fromPhoto: data['fromPhoto'],
      toUid: data['toUid'] ?? '',
      toUsername: data['toUsername'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUid': fromUid,
      'fromName': fromName,
      'fromUsername': fromUsername,
      'fromPhoto': fromPhoto,
      'toUid': toUid,
      'toUsername': toUsername,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
