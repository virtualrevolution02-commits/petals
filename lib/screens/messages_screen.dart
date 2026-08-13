import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/couple_model.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_widgets.dart';
import '../utils/paper_animations.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MessagesScreen extends StatefulWidget {
  final CoupleModel couple;
  final String myUid;
  final bool hideBottomDock;

  const MessagesScreen({
    super.key,
    required this.couple,
    required this.myUid,
    this.hideBottomDock = false,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _authService = AuthService();
  final _friendService = FriendService();
  final _searchCtrl = TextEditingController();

  UserModel? _currentUser;
  List<FriendModel> _friends = [];
  StreamSubscription<List<FriendModel>>? _friendsSub;
  String _searchQuery = '';

  String get _partnerName => widget.couple.partnerNameFor(widget.myUid);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startListeners();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUserProfile(widget.myUid);
    if (!mounted) return;
    setState(() => _currentUser = user);
  }

  void _startListeners() {
    _friendsSub = _friendService.watchFriends(widget.myUid).listen((friends) {
      if (!mounted) return;
      setState(() => _friends = friends);
    });
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openPartnerChat() {
    Navigator.push(
      context,
      PaperPageRoute(
        builder: (_) => ChatScreen(
          couple: widget.couple,
          myUid: widget.myUid,
        ),
      ),
    );
  }

  void _openFriendChat(FriendModel friend, UserModel friendUser) {
    final friendCouple = CoupleModel(
      id: 'friend_${friend.id}',
      user1Uid: widget.myUid,
      user2Uid: friendUser.uid,
      user1Name: _currentUser?.displayName ?? 'Me',
      user2Name: friendUser.displayName,
      pairingCode: 'FRIEND',
      createdAt: friend.createdAt,
    );

    Navigator.push(
      context,
      PaperPageRoute(
        builder: (_) => ChatScreen(
          couple: friendCouple,
          myUid: widget.myUid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF161925) : const Color(0xFFECE4D6);
    final textCol = isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark;

    return PaperDioramaBackground(
      isDark: isDark,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textCol),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Icon(Icons.chat_bubble_rounded, color: Color(0xFFED8891), size: 22),
              const SizedBox(width: 8),
              Text(
                'Messages',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. PINNED PARTNER LOVE NOTES CARD ──
              GestureDetector(
                onTap: _openPartnerChat,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF382430) : const Color(0xFFFCE8EB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFED8891),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFED8891),
                        child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _partnerName.isNotEmpty ? _partnerName : 'Partner',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF2C241B),
                                    fontSize: 16.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFED8891),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Partner 💕',
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Private Couple Love Notes & Stickers',
                              style: GoogleFonts.caveat(
                                color: const Color(0xFFED8891),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFED8891), size: 26),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 2. FRIENDS CHAT SECTION HEADER ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Friends Chat (${_friends.length})',
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Filter Bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF272A32) : const Color(0xFFFCFAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD5C9B8)),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.nunito(
                      color: isDark ? Colors.white : const Color(0xFF2C2825),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFED8891), size: 18),
                      prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 20),
                      hintText: 'Filter friends list...',
                      hintStyle: GoogleFonts.nunito(
                        color: isDark ? Colors.white38 : const Color(0xFF8C7D6B),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 3. FRIENDS LIST ──
              if (_friends.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF272A32) : const Color(0xFFFCFAF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD5C9B8)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded, color: Color(0xFFED8891), size: 40),
                      const SizedBox(height: 10),
                      Text(
                        'No Friends Connected Yet',
                        style: GoogleFonts.caveat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search and add friends to start chatting with them!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : PaperColors.inkMedium,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _friends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    final otherUid = friend.friendUidOf(widget.myUid);

                    return FutureBuilder<UserModel?>(
                      future: _authService.getUserProfile(otherUid),
                      builder: (context, snapshot) {
                        final friendUser = snapshot.data;
                        if (friendUser == null) {
                          return const SizedBox();
                        }

                        if (_searchQuery.isNotEmpty &&
                            !friendUser.displayName.toLowerCase().contains(_searchQuery) &&
                            !friendUser.username.toLowerCase().contains(_searchQuery)) {
                          return const SizedBox();
                        }

                        return GestureDetector(
                          onTap: () => _openFriendChat(friend, friendUser),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2F323D) : const Color(0xFFFCFAF7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? const Color(0xFF424654) : const Color(0xFFE2D8C6)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFED8891),
                                  child: Text(
                                    friendUser.displayName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friendUser.displayName,
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : const Color(0xFF2C241B),
                                        ),
                                      ),
                                      Text(
                                        '@${friendUser.username}',
                                        style: GoogleFonts.caveat(
                                          color: const Color(0xFFED8891),
                                          fontSize: 15.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF94A88B), size: 22),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
        bottomNavigationBar: widget.hideBottomDock
            ? null
            : PaperBottomDock(
                currentIndex: 1,
                onHomeTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                onChatTap: () {},
                onProfileTap: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.push(
                    context,
                    PaperPageRoute(
                      builder: (_) => ProfileScreen(
                        couple: widget.couple,
                        myUid: widget.myUid,
                      ),
                    ),
                  );
                },
                onSettingsTap: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.push(
                    context,
                    PaperPageRoute(
                      builder: (_) => SettingsScreen(couple: widget.couple),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
