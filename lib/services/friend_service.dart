import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search users by username (excluding current user)
  Future<UserModel?> findUserByUsername(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase().trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  // Send a friend request
  Future<void> sendFriendRequest({
    required UserModel fromUser,
    required UserModel toUser,
  }) async {
    // 1. Check if already friends
    final friendCheck1 = await _firestore
        .collection('friendships')
        .where('user1Uid', isEqualTo: fromUser.uid)
        .where('user2Uid', isEqualTo: toUser.uid)
        .limit(1)
        .get();

    final friendCheck2 = await _firestore
        .collection('friendships')
        .where('user1Uid', isEqualTo: toUser.uid)
        .where('user2Uid', isEqualTo: fromUser.uid)
        .limit(1)
        .get();

    if (friendCheck1.docs.isNotEmpty || friendCheck2.docs.isNotEmpty) {
      throw Exception('You are already friends with @${toUser.username}!');
    }

    // 2. Check if a request already exists
    final existingReq = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: fromUser.uid)
        .where('toUid', isEqualTo: toUser.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingReq.docs.isNotEmpty) {
      throw Exception('Request already sent to @${toUser.username}!');
    }

    final docRef = _firestore.collection('friend_requests').doc();
    final req = FriendRequestModel(
      id: docRef.id,
      fromUid: fromUser.uid,
      fromName: fromUser.displayName,
      fromUsername: fromUser.username,
      toUid: toUser.uid,
      toUsername: toUser.username,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await docRef.set(req.toMap());
  }

  // Stream incoming pending friend requests for user
  Stream<List<FriendRequestModel>> watchIncomingRequests(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequestModel.fromFirestore(d)).toList());
  }

  // Stream outgoing pending friend requests from user
  Stream<List<FriendRequestModel>> watchOutgoingRequests(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequestModel.fromFirestore(d)).toList());
  }

  // Accept friend request
  Future<FriendModel> acceptFriendRequest(FriendRequestModel request) async {
    // 1. Mark request accepted
    await _firestore
        .collection('friend_requests')
        .doc(request.id)
        .update({'status': 'accepted'});

    // 2. Create friendship document
    final docRef = _firestore.collection('friendships').doc();
    final friendship = FriendModel(
      id: docRef.id,
      user1Uid: request.fromUid,
      user2Uid: request.toUid,
      createdAt: DateTime.now(),
    );

    await docRef.set(friendship.toMap());
    return friendship;
  }

  // Reject / Decline friend request
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }

  // Stream all established friendships for user
  Stream<List<FriendModel>> watchFriends(String uid) {
    return _firestore
        .collection('friendships')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FriendModel.fromFirestore(d))
            .where((f) => f.user1Uid == uid || f.user2Uid == uid)
            .toList());
  }

  // Get list of friend UIDs for feed filtering
  Future<List<String>> getFriendUids(String uid) async {
    final snap1 = await _firestore
        .collection('friendships')
        .where('user1Uid', isEqualTo: uid)
        .get();

    final snap2 = await _firestore
        .collection('friendships')
        .where('user2Uid', isEqualTo: uid)
        .get();

    final set = <String>{};
    for (var d in snap1.docs) {
      final f = FriendModel.fromFirestore(d);
      set.add(f.user2Uid);
    }
    for (var d in snap2.docs) {
      final f = FriendModel.fromFirestore(d);
      set.add(f.user1Uid);
    }
    return set.toList();
  }

  // Unfriend / Remove friend connection
  Future<void> removeFriend(String currentUid, String friendUid) async {
    final snap1 = await _firestore
        .collection('friendships')
        .where('user1Uid', isEqualTo: currentUid)
        .where('user2Uid', isEqualTo: friendUid)
        .get();
    for (var doc in snap1.docs) {
      await doc.reference.delete();
    }

    final snap2 = await _firestore
        .collection('friendships')
        .where('user1Uid', isEqualTo: friendUid)
        .where('user2Uid', isEqualTo: currentUid)
        .get();
    for (var doc in snap2.docs) {
      await doc.reference.delete();
    }
  }

  // Get suggested users (all registered users except current user and existing friends)
  Future<List<UserModel>> getSuggestedUsers(String currentUid) async {
    final friendUids = await getFriendUids(currentUid);
    final snap = await _firestore.collection('users').limit(20).get();

    final suggested = <UserModel>[];
    for (var doc in snap.docs) {
      final u = UserModel.fromFirestore(doc);
      if (u.uid != currentUid && !friendUids.contains(u.uid)) {
        suggested.add(u);
      }
    }
    return suggested;
  }
}
