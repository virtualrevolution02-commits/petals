import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/couple_model.dart';
import '../models/couple_request_model.dart';
import '../models/user_model.dart';

class CoupleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Find user by username ────────────────────────────────────────
  Future<UserModel?> findUserByUsername(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  // ─── Send pairing request ─────────────────────────────────────────
  Future<void> sendPairingRequest({
    required UserModel fromUser,
    required UserModel toUser,
  }) async {
    // Check if a pending request already exists
    final existing = await _db
        .collection('couple_requests')
        .where('fromUid', isEqualTo: fromUser.uid)
        .where('toUid', isEqualTo: toUser.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You already sent a request to this person.');
    }

    final request = CoupleRequestModel(
      id: '',
      fromUid: fromUser.uid,
      fromName: fromUser.displayName,
      fromUsername: fromUser.username,
      fromPhoto: fromUser.photoUrl,
      toUid: toUser.uid,
      toUsername: toUser.username,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );
    await _db.collection('couple_requests').add(request.toMap());
  }

  // ─── Watch incoming requests ──────────────────────────────────────
  Stream<List<CoupleRequestModel>> watchIncomingRequests(String uid) {
    return _db
        .collection('couple_requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CoupleRequestModel.fromFirestore(d))
            .toList());
  }

  // ─── Watch outgoing request ───────────────────────────────────────
  Stream<CoupleRequestModel?> watchOutgoingRequest(String uid) {
    return _db
        .collection('couple_requests')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : CoupleRequestModel.fromFirestore(snap.docs.first));
  }

  // ─── Accept request → create couple ──────────────────────────────
  Future<CoupleModel> acceptRequest(CoupleRequestModel request) async {
    // Get both user profiles
    final fromDoc = await _db.collection('users').doc(request.fromUid).get();
    final fromUser = UserModel.fromFirestore(fromDoc);
    final toDoc = await _db.collection('users').doc(request.toUid).get();
    final toUser = UserModel.fromFirestore(toDoc);

    final coupleRef = _db.collection('couples').doc();
    final couple = CoupleModel(
      id: coupleRef.id,
      user1Uid: request.fromUid,
      user2Uid: request.toUid,
      user1Name: fromUser.displayName,
      user2Name: toUser.displayName,
      pairingCode: '',
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(coupleRef, couple.toMap());
    batch.update(
      _db.collection('couple_requests').doc(request.id),
      {'status': 'accepted', 'coupleId': coupleRef.id},
    );
    batch.update(
      _db.collection('users').doc(request.fromUid),
      {'coupleId': coupleRef.id},
    );
    batch.update(
      _db.collection('users').doc(request.toUid),
      {'coupleId': coupleRef.id},
    );
    await batch.commit();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('couple_id', coupleRef.id);
    await prefs.setString('cached_couple_json', couple.toJsonString());

    return couple;
  }

  // ─── Reject request ───────────────────────────────────────────────
  Future<void> rejectRequest(String requestId) async {
    await _db
        .collection('couple_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  // ─── Get couple by ID ─────────────────────────────────────────────
  Future<CoupleModel?> getCoupleById(String coupleId) async {
    final doc = await _db.collection('couples').doc(coupleId).get();
    if (!doc.exists) return null;
    final couple = CoupleModel.fromFirestore(doc);
    // Cache locally for cold-start navigation
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_couple_json', couple.toJsonString());
    return couple;
  }

  Future<String?> getCoupleIdForUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    String? coupleId = prefs.getString('couple_id');
    if (coupleId != null) return coupleId;

    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      coupleId = userDoc.data()?['coupleId'];
      if (coupleId != null) {
        await prefs.setString('couple_id', coupleId);
      }
    }
    return coupleId;
  }

  Stream<CoupleModel?> watchCouple(String coupleId) {
    return _db
        .collection('couples')
        .doc(coupleId)
        .snapshots()
        .map((doc) => doc.exists ? CoupleModel.fromFirestore(doc) : null);
  }
}
