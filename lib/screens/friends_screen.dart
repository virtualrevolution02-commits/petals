import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/couple_model.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_widgets.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  final String myUid;
  const FriendsScreen({super.key, required this.myUid});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _friendService = FriendService();
  late TabController _tabController;

  UserModel? _currentUser;
  final _searchCtrl = TextEditingController();
  UserModel? _foundUser;
  bool _isSearching = false;
  bool _isSending = false;
  String? _error;
  String? _success;

  List<UserModel> _suggestedUsers = [];
  bool _isLoadingSuggested = false;

  StreamSubscription<List<FriendRequestModel>>? _incomingSub;
  StreamSubscription<List<FriendRequestModel>>? _outgoingSub;
  StreamSubscription<List<FriendModel>>? _friendsSub;

  List<FriendRequestModel> _incomingRequests = [];
  List<FriendRequestModel> _outgoingRequests = [];
  List<FriendModel> _friendsList = [];

  final Color sageGreen = const Color(0xFF94A88B);
  final Color coralPink = const Color(0xFFED8891);
  final Color feltPink = const Color(0xFFE66B7C);
  final Color creamPaper = const Color(0xFFFAF6EE);
  final Color darkCard = const Color(0xFF383D4A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUser();
    _loadSuggestedUsers();
  }

  Future<void> _loadSuggestedUsers() async {
    setState(() => _isLoadingSuggested = true);
    try {
      final users = await _friendService.getSuggestedUsers(widget.myUid);
      if (!mounted) return;
      setState(() {
        _suggestedUsers = users;
        _isLoadingSuggested = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingSuggested = false);
    }
  }

  Future<void> _sendSuggestedRequest(UserModel user) async {
    if (_currentUser == null) return;
    try {
      await _friendService.sendFriendRequest(
        fromUser: _currentUser!,
        toUser: user,
      );
      if (!mounted) return;
      setState(() {
        _success = 'Friend request sent to @${user.username}! 🌸';
        _suggestedUsers.removeWhere((u) => u.uid == user.uid);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUserProfile(widget.myUid);
    if (!mounted) return;
    setState(() => _currentUser = user);
    _startListeners();
  }

  void _startListeners() {
    _incomingSub = _friendService
        .watchIncomingRequests(widget.myUid)
        .listen((reqs) {
      if (!mounted) return;
      setState(() => _incomingRequests = reqs);
    });

    _outgoingSub = _friendService
        .watchOutgoingRequests(widget.myUid)
        .listen((reqs) {
      if (!mounted) return;
      setState(() => _outgoingRequests = reqs);
    });

    _friendsSub = _friendService.watchFriends(widget.myUid).listen((friends) {
      if (!mounted) return;
      setState(() => _friendsList = friends);
    });
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _friendsSub?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return;
    if (query == _currentUser?.username) {
      setState(() => _error = "That's your own username!");
      return;
    }
    setState(() {
      _isSearching = true;
      _foundUser = null;
      _error = null;
    });

    final user = await _friendService.findUserByUsername(query);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _foundUser = user;
      if (user == null) _error = 'No user found with that username.';
    });
  }

  Future<void> _sendFriendRequest() async {
    if (_foundUser == null || _currentUser == null) return;
    setState(() {
      _isSending = true;
      _error = null;
      _success = null;
    });

    try {
      await _friendService.sendFriendRequest(
        fromUser: _currentUser!,
        toUser: _foundUser!,
      );
      if (!mounted) return;
      setState(() {
        _success = 'Friend request sent to @${_foundUser!.username}!';
        _foundUser = null;
        _searchCtrl.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _acceptRequest(FriendRequestModel request) async {
    try {
      await _friendService.acceptFriendRequest(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected with @${request.fromUsername}! 🌸'),
          backgroundColor: PaperColors.sageCutout,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _rejectRequest(FriendRequestModel request) async {
    await _friendService.rejectFriendRequest(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request declined.')),
    );
  }

  Future<void> _removeFriend(FriendModel friend) async {
    final otherUid = friend.friendUidOf(widget.myUid);
    await _friendService.removeFriend(widget.myUid, otherUid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF161925) : const Color(0xFFECE4D6);
    final textCol = isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textCol),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: Color(0xFFED8891), size: 22),
            const SizedBox(width: 8),
            Text(
              'Petal Friends',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
          ],
        ),
      ),
      body: PaperDioramaBackground(
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              // Segmented Control Tabs
              Container(
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? darkCard : const Color(0xFFE6D8C6),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    color: feltPink,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B635E),
                  labelStyle: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_rounded, size: 15),
                          SizedBox(width: 4),
                          Text('Search'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mail_outline_rounded, size: 15),
                          const SizedBox(width: 4),
                          const Text('Requests'),
                          if (_incomingRequests.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_incomingRequests.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: feltPink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.handshake_outlined, size: 15),
                          const SizedBox(width: 4),
                          Text('Friends (${_friendsList.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Feedback Banners
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: coralPink.withValues(alpha: isDark ? 0.2 : 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: coralPink),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: coralPink, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.nunito(
                            color: isDark ? creamPaper : const Color(0xFF6B1D24),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().shake(),

              if (_success != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sageGreen.withValues(alpha: isDark ? 0.25 : 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sageGreen),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: sageGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _success!,
                          style: GoogleFonts.nunito(
                            color: isDark ? creamPaper : const Color(0xFF1E3F20),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSearchTab(isDark),
                    _buildRequestsTab(isDark),
                    _buildFriendsTab(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. SEARCH TAB ──
  Widget _buildSearchTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF272A32) : const Color(0xFFFCFAF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD5C9B8)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
                    ],
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
                        prefixIcon: const Text(
                          '@',
                          style: TextStyle(color: Color(0xFFED8891), fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        hintText: 'Search username...',
                        hintStyle: GoogleFonts.nunito(
                          color: isDark ? Colors.white38 : const Color(0xFF8C7D6B),
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _searchUser(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PaperPressable(
                onTap: _isSearching ? null : _searchUser,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: sageGreen,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                    ],
                  ),
                  child: _isSearching
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                      : const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // If a searched user is found
          if (_foundUser != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383B44) : const Color(0xFFFCFAF7),
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: const Color(0xFFD5C9B8)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 4))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: coralPink,
                    child: Text(
                      _foundUser!.displayName.isNotEmpty ? _foundUser!.displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _foundUser!.displayName,
                          style: GoogleFonts.nunito(
                            color: isDark ? Colors.white : const Color(0xFF2C2825),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text('@${_foundUser!.username}', style: GoogleFonts.caveat(color: coralPink, fontSize: 16)),
                      ],
                    ),
                  ),
                  PaperPressable(
                    onTap: _isSending ? null : _sendFriendRequest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: coralPink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isSending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Add Friend', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0)
          else ...[
            // ── SUGGESTED FRIENDS LIST ──
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFED8891), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Suggested Friends on Petals',
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoadingSuggested)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFFED8891)),
                ),
              )
            else if (_suggestedUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF272A32) : const Color(0xFFFCFAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD5C9B8)),
                ),
                child: Text(
                  'No new suggested users right now. Type a username above to search!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : PaperColors.inkMedium,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestedUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = _suggestedUsers[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2F323D) : const Color(0xFFFCFAF7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF424654) : const Color(0xFFE2D8C6)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: coralPink,
                          child: Text(
                            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: GoogleFonts.nunito(
                                  color: isDark ? Colors.white : const Color(0xFF2C2825),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text('@${user.username}', style: GoogleFonts.caveat(color: coralPink, fontSize: 16)),
                            ],
                          ),
                        ),
                        PaperPressable(
                          onTap: () => _sendSuggestedRequest(user),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: coralPink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_add_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Add Friend',
                                  style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  // ── 2. REQUESTS TAB ──
  Widget _buildRequestsTab(bool isDark) {
    if (_incomingRequests.isEmpty && _outgoingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read_outlined, color: coralPink, size: 44),
            const SizedBox(height: 8),
            Text(
              'No Pending Friend Requests',
              style: GoogleFonts.caveat(
                fontSize: 22,
                color: isDark ? creamPaper : const Color(0xFF3E3832),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search for friends using their username above!',
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF6B635E),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_incomingRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'INCOMING REQUESTS',
              style: GoogleFonts.caveat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: coralPink,
              ),
            ),
          ),
          ..._incomingRequests.map((req) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF383B44) : const Color(0xFFFCFAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? null : Border.all(color: const Color(0xFFD5C9B8)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: coralPink,
                      child: Text(req.fromName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req.fromName, style: GoogleFonts.nunito(color: isDark ? Colors.white : const Color(0xFF2C2825), fontWeight: FontWeight.bold)),
                          Text('@${req.fromUsername}', style: GoogleFonts.caveat(color: coralPink, fontSize: 16)),
                        ],
                      ),
                    ),
                    PaperPressable(
                      onTap: () => _rejectRequest(req),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF454545) : const Color(0xFFE6D8C6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Decline', style: GoogleFonts.nunito(color: isDark ? Colors.white70 : const Color(0xFF3E3832), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PaperPressable(
                      onTap: () => _acceptRequest(req),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: coralPink,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Accept', style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],

        if (_outgoingRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'SENT REQUESTS (WAITING)',
              style: GoogleFonts.caveat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: sageGreen,
              ),
            ),
          ),
          ..._outgoingRequests.map((req) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF383B44) : const Color(0xFFFCFAF7),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? null : Border.all(color: const Color(0xFFD5C9B8)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: sageGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Request sent to @${req.toUsername}', style: GoogleFonts.nunito(color: isDark ? Colors.white : const Color(0xFF2C2825), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sageGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Pending', style: GoogleFonts.nunito(color: sageGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  // ── 3. FRIENDS TAB ──
  Widget _buildFriendsTab(bool isDark) {
    if (_friendsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diversity_3_outlined, color: coralPink, size: 44),
            const SizedBox(height: 8),
            Text(
              'No Friends Connected Yet',
              style: GoogleFonts.caveat(
                fontSize: 22,
                color: isDark ? creamPaper : const Color(0xFF3E3832),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search for friends to share scrapbook moments together!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF6B635E),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _friendsList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final friend = _friendsList[i];
        final otherUid = friend.friendUidOf(widget.myUid);

        return FutureBuilder<UserModel?>(
          future: _authService.getUserProfile(otherUid),
          builder: (context, snapshot) {
            final friendUser = snapshot.data;
            final name = friendUser?.displayName ?? 'Friend';
            final username = friendUser?.username ?? 'user';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF383B44) : const Color(0xFFFCFAF7),
                borderRadius: BorderRadius.circular(12),
                border: isDark ? null : Border.all(color: const Color(0xFFD5C9B8)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: coralPink,
                    child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.nunito(color: isDark ? Colors.white : const Color(0xFF2C2825), fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('@$username', style: GoogleFonts.caveat(color: coralPink, fontSize: 16)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: sageGreen, size: 22),
                    onPressed: () {
                      final friendCouple = CoupleModel(
                        id: 'friend_${friend.id}',
                        user1Uid: widget.myUid,
                        user2Uid: otherUid,
                        user1Name: _currentUser?.displayName ?? 'Me',
                        user2Name: name,
                        pairingCode: 'FRIEND',
                        createdAt: friend.createdAt,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            couple: friendCouple,
                            myUid: widget.myUid,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 20),
                    onPressed: () => _removeFriend(friend),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
