import 'package:cloud_firestore/cloud_firestore.dart';

class MomentModel {
  final String id;
  final String coupleId;
  final String postedBy;
  final String postedByName;
  final String imageUrl;
  final String caption;
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;
  final String mediaType; // 'image' or 'video'
  final String? videoUrl;
  final String? audioTrack;

  MomentModel({
    required this.id,
    required this.coupleId,
    required this.postedBy,
    required this.postedByName,
    required this.imageUrl,
    required this.caption,
    required this.likesCount,
    required this.likedBy,
    required this.createdAt,
    this.mediaType = 'image',
    this.videoUrl,
    this.audioTrack,
  });

  factory MomentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MomentModel(
      id: doc.id,
      coupleId: data['coupleId'] ?? '',
      postedBy: data['postedBy'] ?? '',
      postedByName: data['postedByName'] ?? 'Partner',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaType: data['mediaType'] ?? 'image',
      videoUrl: data['videoUrl'],
      audioTrack: data['audioTrack'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coupleId': coupleId,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'imageUrl': imageUrl,
      'caption': caption,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'mediaType': mediaType,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (audioTrack != null) 'audioTrack': audioTrack,
    };
  }

  MomentModel copyWith({
    int? likesCount,
    List<String>? likedBy,
    String? mediaType,
    String? videoUrl,
    String? audioTrack,
  }) {
    return MomentModel(
      id: id,
      coupleId: coupleId,
      postedBy: postedBy,
      postedByName: postedByName,
      imageUrl: imageUrl,
      caption: caption,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt,
      mediaType: mediaType ?? this.mediaType,
      videoUrl: videoUrl ?? this.videoUrl,
      audioTrack: audioTrack ?? this.audioTrack,
    );
  }
}
