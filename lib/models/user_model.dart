import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String username;
  final String? photoUrl;
  final String? coupleId;
  final String bio;
  final String ticketButtonLabel;
  final bool isPrivate;
  final bool isProfileSetup;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoUrl,
    this.coupleId,
    this.bio = 'Capturing sweet paper moments together 💕',
    this.ticketButtonLabel = 'Copy Ticket Code',
    this.isPrivate = false,
    this.isProfileSetup = false,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawName = (data['displayName'] ?? '').toString().trim();
    final rawUser = (data['username'] ?? '').toString().trim();
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: rawName.isNotEmpty ? rawName : 'Petals User',
      username: rawUser.isNotEmpty ? rawUser : 'user_${doc.id.substring(0, doc.id.length.clamp(0, 5))}',
      photoUrl: data['photoUrl'],
      coupleId: data['coupleId'],
      bio: data['bio'] ?? 'Capturing sweet paper moments together 💕',
      ticketButtonLabel: data['ticketButtonLabel'] ?? 'Copy Ticket Code',
      isPrivate: data['isPrivate'] ?? false,
      isProfileSetup: data['isProfileSetup'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
      'coupleId': coupleId,
      'bio': bio,
      'ticketButtonLabel': ticketButtonLabel,
      'isPrivate': isPrivate,
      'isProfileSetup': isProfileSetup,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
