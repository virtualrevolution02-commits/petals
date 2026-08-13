import 'dart:convert';
import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/moment_model.dart';
import 'widget_service.dart';

class MomentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Stream<List<MomentModel>> watchMoments(String coupleId) {
    return _firestore
        .collection('moments')
        .where('coupleId', isEqualTo: coupleId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => MomentModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<MomentModel>> watchFriendsMoments(List<String> friendUids) {
    if (friendUids.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('moments')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MomentModel.fromFirestore(d))
          .where((m) => friendUids.contains(m.postedBy))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<MomentModel?> getLatestMoment(String coupleId) async {
    final snap = await _firestore
        .collection('moments')
        .where('coupleId', isEqualTo: coupleId)
        .get();
    if (snap.docs.isEmpty) return null;
    final list =
        snap.docs.map((d) => MomentModel.fromFirestore(d)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.first;
  }

  Future<String> uploadImageBytes(Uint8List bytes, String coupleId) async {
    final fileName = '${_uuid.v4()}.jpg';
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'coupleId': coupleId},
    );

    // 1. Try default Firebase Storage instance
    try {
      final ref = _storage.ref('moments/$coupleId/$fileName');
      final taskSnapshot = await ref.putData(bytes, metadata);
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e1) {
      // 2. Try gs://petals-dairy.firebasestorage.app
      try {
        final storage1 = FirebaseStorage.instanceFor(
            bucket: 'gs://petals-dairy.firebasestorage.app');
        final ref = storage1.ref('moments/$coupleId/$fileName');
        final taskSnapshot = await ref.putData(bytes, metadata);
        return await taskSnapshot.ref.getDownloadURL();
      } catch (e2) {
        // 3. Try gs://petals-dairy.appspot.com
        try {
          final storage2 = FirebaseStorage.instanceFor(
              bucket: 'gs://petals-dairy.appspot.com');
          final ref = storage2.ref('moments/$coupleId/$fileName');
          final taskSnapshot = await ref.putData(bytes, metadata);
          return await taskSnapshot.ref.getDownloadURL();
        } catch (e3) {
          // 4. Base64 fallback if Firebase Storage bucket is uninitialized
          final base64String = base64Encode(bytes);
          return 'data:image/jpeg;base64,$base64String';
        }
      }
    }
  }

  Future<String> uploadImage(dynamic imageInput, String coupleId) async {
    if (imageInput is Uint8List) {
      return uploadImageBytes(imageInput, coupleId);
    } else if (imageInput is XFile) {
      final bytes = await imageInput.readAsBytes();
      return uploadImageBytes(bytes, coupleId);
    } else if (imageInput != null) {
      try {
        final dynamic input = imageInput;
        final bytes = await input.readAsBytes() as Uint8List;
        return uploadImageBytes(bytes, coupleId);
      } catch (_) {}
    }
    throw ArgumentError('Unsupported image input format');
  }

  Future<MomentModel> postMoment({
    required String coupleId,
    required String postedBy,
    required String postedByName,
    required dynamic imageFile,
    required String caption,
    String mediaType = 'image',
    String? videoUrl,
    String? audioTrack,
  }) async {
    final imageUrl = await uploadImage(imageFile, coupleId);
    final docRef = _firestore.collection('moments').doc();
    final moment = MomentModel(
      id: docRef.id,
      coupleId: coupleId,
      postedBy: postedBy,
      postedByName: postedByName,
      imageUrl: imageUrl,
      caption: caption,
      likesCount: 0,
      likedBy: [],
      createdAt: DateTime.now(),
      mediaType: mediaType,
      videoUrl: videoUrl,
      audioTrack: audioTrack,
    );
    await docRef.set(moment.toMap());

    // Update home widget
    try {
      await WidgetService.updateWidget(
        imageUrl: imageUrl,
        caption: caption,
        posterName: postedByName,
      );
    } catch (e) {
      debugPrint('Failed to update home widget: $e');
    }

    return moment;
  }

  Future<void> toggleLike(String momentId, String uid) async {
    final ref = _firestore.collection('moments').doc(momentId);
    final doc = await ref.get();
    if (!doc.exists) return;
    final moment = MomentModel.fromFirestore(doc);

    if (moment.likedBy.contains(uid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> deleteMoment(String momentId, String imageUrl) async {
    await _firestore.collection('moments').doc(momentId).delete();
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (_) {}
  }
}
