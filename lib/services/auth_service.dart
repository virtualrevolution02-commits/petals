import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Username generation ──────────────────────────────────────────
  static const _flowers = [
    'rose', 'lily', 'daisy', 'iris', 'violet', 'jasmine',
    'lotus', 'tulip', 'poppy', 'clover', 'petal', 'bloom',
  ];

  String _generateUsername(String displayName) {
    final flower = _flowers[Random().nextInt(_flowers.length)];
    final namePart = displayName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .substring(0, displayName.trim().length.clamp(0, 8));
    final digits = (Random().nextInt(9000) + 1000).toString();
    return '$flower.$namePart.$digits';
  }

  // ─── Save user to Firestore on first login ────────────────────────
  Future<UserModel> _createOrUpdateUser(User firebaseUser, {String? displayName}) async {
    final ref = _db.collection('users').doc(firebaseUser.uid);
    final doc = await ref.get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    final name = displayName ?? firebaseUser.displayName ?? 'User';
    final username = _generateUsername(name);
    final user = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: name,
      username: username,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
    await ref.set(user.toMap());
    return user;
  }

  // ─── Google Sign-In ───────────────────────────────────────────────
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential credential;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        credential = await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(authCredential);
      }
      await _setLoggedInFlag(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stored_uid', credential.user!.uid);
      return await _createOrUpdateUser(credential.user!);
    } catch (e) {
      rethrow;
    }
  }

  // ─── Email/Password ───────────────────────────────────────────────
  Future<UserModel?> registerWithEmail(
      String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await credential.user!.updateDisplayName(displayName);
    await _setLoggedInFlag(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stored_uid', credential.user!.uid);
    return await _createOrUpdateUser(credential.user!, displayName: displayName);
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    await _setLoggedInFlag(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stored_uid', credential.user!.uid);
    return await _createOrUpdateUser(credential.user!);
  }

  // ─── Get current user profile ─────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ─── User Name helpers ────────────────────────────────────────────
  Future<String> getUserName() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      final profile = await getUserProfile(uid);
      if (profile != null && profile.displayName.isNotEmpty) {
        return profile.displayName;
      }
    }
    return currentUser?.displayName ?? 'Partner';
  }

  Future<void> saveUserName(String name) async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _db
          .collection('users')
          .doc(uid)
          .set({'displayName': name}, SetOptions(merge: true));
    }
    await currentUser?.updateDisplayName(name);
  }

  Future<void> updateUserBio(String bio) async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _db
          .collection('users')
          .doc(uid)
          .set({'bio': bio}, SetOptions(merge: true));
    }
  }

  Future<void> updateTicketButtonLabel(String label) async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _db
          .collection('users')
          .doc(uid)
          .set({'ticketButtonLabel': label}, SetOptions(merge: true));
    }
  }

  Future<void> updateUserPhotoUrl(String photoUrl) async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _db
          .collection('users')
          .doc(uid)
          .set({'photoUrl': photoUrl}, SetOptions(merge: true));
    }
  }

  Future<void> updateProfileSetup({
    required String uid,
    required String displayName,
    required String username,
    required String bio,
    required bool isPrivate,
    String? photoUrl,
  }) async {
    final targetUid = uid.isNotEmpty ? uid : (currentUser?.uid ?? '');
    if (targetUid.isEmpty) throw Exception('User session invalid. Please sign in again.');

    final cleanName = displayName.trim();
    final cleanUsername = username.trim().toLowerCase().replaceAll('@', '');

    if (cleanName.isEmpty) throw Exception('Display name cannot be empty');
    if (cleanUsername.isEmpty) throw Exception('Username handle cannot be empty');

    // Check username uniqueness if changed
    try {
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (query.docs.isNotEmpty && query.docs.first.id != targetUid) {
        throw Exception('@$cleanUsername is already taken by another user!');
      }
    } catch (e) {
      if (e.toString().contains('already taken')) rethrow;
      debugPrint('Username check timeout or bypass: $e');
    }

    final data = <String, dynamic>{
      'displayName': cleanName,
      'username': cleanUsername,
      'bio': bio,
      'isPrivate': isPrivate,
      'isProfileSetup': true,
    };
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }

    await _db.collection('users').doc(targetUid).set(data, SetOptions(merge: true));
    try {
      await currentUser?.updateDisplayName(cleanName);
    } catch (_) {}
  }

  Future<void> updateProfile({
    required String displayName,
    required String username,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    final cleanName = displayName.trim();
    final cleanUsername = username.trim().toLowerCase().replaceAll('@', '');

    if (cleanName.isEmpty) throw Exception('Display name cannot be empty');
    if (cleanUsername.isEmpty) throw Exception('Username cannot be empty');

    // Check username uniqueness
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: cleanUsername)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty && query.docs.first.id != uid) {
      throw Exception('@$cleanUsername is already taken by another user!');
    }

    await _db.collection('users').doc(uid).set({
      'displayName': cleanName,
      'username': cleanUsername,
    }, SetOptions(merge: true));

    await currentUser?.updateDisplayName(cleanName);
  }

  Future<void> _setLoggedInFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', value);
  }

  // ─── Sign out ─────────────────────────────────────────────────────
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('couple_id');
    await prefs.remove('stored_uid');
    await prefs.remove('cached_couple_json');
    await _setLoggedInFlag(false);
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
