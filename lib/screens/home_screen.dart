import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/couple_model.dart';
import '../models/moment_model.dart';
import '../models/friend_model.dart';
import '../services/auth_service.dart';
import '../services/moment_service.dart';
import '../services/widget_service.dart';
import '../services/friend_service.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../models/message_model.dart';
import '../widgets/paper_widgets.dart';
import '../utils/paper_animations.dart';
import 'package:home_widget/home_widget.dart';
import 'auth_screen.dart';
import 'post_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'moment_detail_screen.dart';
import 'settings_screen.dart';
import 'friends_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  final CoupleModel couple;
  final String? cachedUid;

  const HomeScreen({super.key, required this.couple, this.cachedUid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _momentService = MomentService();
  final _friendService = FriendService();
  final _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;
  int _currentBottomNavIndex = 0;
  bool _hasUnreadMessages = false;
  String? _lastSyncedMomentId;
  Map<String, StreamSubscription<List<MessageModel>>> _chatSubs = {};
  Map<String, String> _lastSeenMsgIds = {};
  StreamSubscription<List<FriendModel>>? _friendsListSub;
  StreamSubscription<User?>? _authSub;
  bool _hadFirebaseUser = false;
  bool _firebaseAuthReady = false;
  int _selectedFeedIndex = 0; // 0 = Partner Feed 💕, 1 = Friends Feed 🌸
  final ValueNotifier<bool> _isScrolledNotifier = ValueNotifier<bool>(false);

  String get _myUid => _authService.currentUser?.uid ?? widget.cachedUid ?? '';
  String get _partnerName => widget.couple.partnerNameFor(_myUid);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _scrollController.addListener(_handleScrollDirection);
    _listenToIncomingMessages();

    if (_authService.currentUser != null) {
      _hadFirebaseUser = true;
      _firebaseAuthReady = true;
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user != null) {
        _hadFirebaseUser = true;
        setState(() {
          _firebaseAuthReady = true;
        });
      } else if (_hadFirebaseUser) {
        _navigateToLogin();
      }
    });

    if (!kIsWeb) {
      HomeWidget.widgetClicked.listen((Uri? uri) {
        if (uri?.host == 'upload') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _goToUpload();
          });
        }
      });

      HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
        if (uri?.host == 'upload') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _goToUpload();
          });
        }
      });
    }

    if (!_firebaseAuthReady) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !_firebaseAuthReady) {
          setState(() => _firebaseAuthReady = true);
        }
      });
    }
  }

  void _listenToIncomingMessages() {
    // 1. Subscribe to Partner Chat
    _subscribeToChat(widget.couple.id, _partnerName.isNotEmpty ? _partnerName : 'Partner');

    // 2. Subscribe to all Friend Chats dynamically
    if (_myUid.isNotEmpty) {
      _friendsListSub = _friendService.watchFriends(_myUid).listen((friends) async {
        for (var f in friends) {
          final friendUid = f.friendUidOf(_myUid);
          final friendUser = await _authService.getUserProfile(friendUid);
          final friendName = friendUser?.displayName ?? 'Friend';
          final chatId = 'friend_${f.id}';
          _subscribeToChat(chatId, friendName);
        }
      });
    }
  }

  void _subscribeToChat(String chatId, String senderFallbackName) {
    if (_chatSubs.containsKey(chatId)) return;

    bool isInitialLoadForChat = true;

    _chatSubs[chatId] = _chatService.watchMessages(chatId).listen((messages) {
      if (messages.isEmpty) return;
      final latest = messages.first;

      if (isInitialLoadForChat) {
        isInitialLoadForChat = false;
        _lastSeenMsgIds[chatId] = latest.id;
        return;
      }

      if (latest.senderId != _myUid && latest.id != _lastSeenMsgIds[chatId]) {
        _lastSeenMsgIds[chatId] = latest.id;
        final previewText = latest.imageUrl != null
            ? '📷 Shared a photo'
            : (latest.text.isNotEmpty ? latest.text : 'Sent a note');

        HapticFeedback.heavyImpact();

        if (mounted) {
          setState(() {
            _hasUnreadMessages = true;
          });
        }

        // 1. In-App Floating Paper Popup Banner 💬
        PaperNotificationPopup.show(
          context: context,
          title: '$senderFallbackName 💬',
          message: previewText,
          avatarLetter: senderFallbackName.isNotEmpty ? senderFallbackName[0].toUpperCase() : 'P',
          onTap: () {
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            }
          },
        );

        // 2. System Local Notification
        NotificationService.showNotification(
          title: '$senderFallbackName 💬',
          body: previewText,
        );
      } else {
        _lastSeenMsgIds[chatId] = latest.id;
      }
    });
  }

  void _navigateToLogin() {
    _authSub?.cancel();
    _friendsListSub?.cancel();
    for (var sub in _chatSubs.values) {
      sub.cancel();
    }
    _chatSubs.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _handleScrollDirection() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 80 && !_isScrolledNotifier.value) {
        _isScrolledNotifier.value = true;
      } else if (_scrollController.offset <= 80 && _isScrolledNotifier.value) {
        _isScrolledNotifier.value = false;
      }
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _friendsListSub?.cancel();
    for (var sub in _chatSubs.values) {
      sub.cancel();
    }
    _chatSubs.clear();
    _pageController.dispose();
    _scrollController.dispose();
    _isScrolledNotifier.dispose();
    super.dispose();
  }

  void _goToUpload() {
    Navigator.push(
      context,
      PaperPageRoute(
        builder: (_) => PostScreen(couple: widget.couple, cachedUid: _myUid),
      ),
    );
  }

  void _goToFriends() {
    Navigator.push(
      context,
      PaperPageRoute(
        builder: (_) => FriendsScreen(myUid: _myUid),
      ),
    );
  }

  void _handleBackPress() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? PaperColors.darkCard : const Color(0xFFFCFAF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? Colors.white24 : PaperColors.stampBorder, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.favorite, color: PaperColors.roseCutout, size: 24),
            const SizedBox(width: 8),
            Text(
              'Petals',
              style: GoogleFonts.caveat(
                color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        content: Text(
          'What would you like to do with your Petals session?',
          style: GoogleFonts.outfit(
            color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
              ),
            ),
          ),
          PaperButton(
            label: 'Exit App',
            color: PaperColors.roseCutout,
            onPressed: () => Navigator.pop(context, 'exit'),
          ),
          const SizedBox(width: 8),
          PaperButton(
            label: 'Log Out',
            color: PaperColors.pinRed,
            onPressed: () => Navigator.pop(context, 'logout'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (choice == 'exit') {
      SystemNavigator.pop();
    } else if (choice == 'logout') {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  void _syncWidgetIfNeeded(List<MomentModel> moments) {
    final latest = moments.isNotEmpty ? moments.first : null;
    final newId = latest?.id ?? 'empty';

    if (newId == _lastSyncedMomentId) return;
    _lastSyncedMomentId = newId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final myUid = _myUid;
        final myName = myUid.isNotEmpty ? await _authService.getUserName() : 'Me';
        final partnerName = _partnerName;

        if (latest != null && latest.imageUrl.isNotEmpty) {
          await WidgetService.updateWidget(
            imageUrl: latest.imageUrl,
            caption: latest.caption,
            posterName: latest.postedByName,
            myName: myName,
            partnerName: partnerName,
            time: latest.createdAt,
          );
        } else {
          await WidgetService.updateWidget(
            imageUrl: '',
            caption: partnerName.isNotEmpty ? 'Connected with $partnerName 💕' : 'Connected 💕',
            posterName: 'Waiting for moments...',
            myName: myName,
            partnerName: partnerName,
            time: DateTime.now(),
          );
        }
      } catch (e) {
        debugPrint('HomeScreen: widget sync error: $e');
      }
    });
  }

  Widget _buildMainFeedBody(bool isDark) {
    return Column(
      children: [
        // Segmented Feed Toggle (Partner 💕 vs Friends 🌸)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262934) : const Color(0xFFE6D8C6),
              borderRadius: BorderRadius.circular(19),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFeedIndex = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedFeedIndex == 0 ? PaperColors.roseCutout : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: _selectedFeedIndex == 0 ? Colors.white : (isDark ? Colors.white60 : PaperColors.inkMedium),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Partner',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedFeedIndex == 0 ? Colors.white : (isDark ? Colors.white60 : PaperColors.inkMedium),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFeedIndex = 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedFeedIndex == 1 ? PaperColors.roseCutout : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 14,
                              color: _selectedFeedIndex == 1 ? Colors.white : (isDark ? Colors.white60 : PaperColors.inkMedium),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Friends Feed',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedFeedIndex == 1 ? Colors.white : (isDark ? Colors.white60 : PaperColors.inkMedium),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Feed Content with IndexedStack for zero-flicker tab switching
        Expanded(
          child: IndexedStack(
            index: _selectedFeedIndex,
            children: [
              StreamBuilder<List<MomentModel>>(
                stream: _momentService.watchMoments(widget.couple.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return _buildShimmer();
                  }
                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }
                  final moments = snapshot.data ?? [];
                  _syncWidgetIfNeeded(moments);
                  if (moments.isEmpty) {
                    return _buildEmpty();
                  }
                  return _buildMomentsList(moments, key: const PageStorageKey('partner_feed'));
                },
              ),
              StreamBuilder<List<FriendModel>>(
                stream: _friendService.watchFriends(_myUid),
                builder: (context, friendsSnap) {
                  final friends = friendsSnap.data ?? [];
                  final friendUids = friends.map((f) => f.friendUidOf(_myUid)).toList();

                  if (friendsSnap.connectionState == ConnectionState.waiting && !friendsSnap.hasData) {
                    return _buildShimmer();
                  }

                  if (friendUids.isEmpty) {
                    return _buildEmptyFriendsFeed(isDark);
                  }

                  return StreamBuilder<List<MomentModel>>(
                    stream: _momentService.watchFriendsMoments(friendUids),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return _buildShimmer();
                      }
                      if (snapshot.hasError) {
                        return _buildError(snapshot.error.toString());
                      }
                      final moments = snapshot.data ?? [];
                      if (moments.isEmpty) {
                        return _buildEmptyFriendsMoments(isDark);
                      }
                      return _buildMomentsList(moments, key: const PageStorageKey('friends_feed'));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMomentsList(List<MomentModel> moments, {Key? key}) {
    return RefreshIndicator(
      key: key,
      color: PaperColors.roseCutout,
      onRefresh: () async {},
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: moments.length,
        itemBuilder: (context, index) {
          final moment = moments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RepaintBoundary(
              child: MomentCard(
                moment: moment,
                myUid: _myUid,
                rotationAngle: (index % 2 == 0) ? -0.012 : 0.012,
                onTap: () => Navigator.push(
                  context,
                  PaperPageRoute(
                    builder: (_) => MomentDetailScreen(
                      moment: moment,
                      myUid: _myUid,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: PaperDioramaBackground(
        isDark: isDark,
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: 64,
            backgroundColor: isDark
                ? const Color(0xFF161925).withValues(alpha: 0.95)
                : const Color(0xFFECE4D6).withValues(alpha: 0.95),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black26,
            scrolledUnderElevation: 2,
            elevation: 2,
            titleSpacing: 16,
            title: Row(
              children: [
                const PaperCutLogo(size: 34),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'petals',
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFEBDDC2) : PaperColors.inkDark,
                        height: 1.1,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'you & $_partnerName ',
                          style: GoogleFonts.nunito(
                            color: isDark ? Colors.white60 : PaperColors.inkMedium,
                            fontSize: 12,
                            fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.favorite, color: Color(0xFFDF7E8B), size: 11.5),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.people_alt_outlined, color: Color(0xFFED8891), size: 22),
                tooltip: 'Petal Friends',
                onPressed: _goToFriends,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: GestureDetector(
                    onTap: _goToUpload,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: PaperColors.roseCutout,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF424654) : const Color(0xFFE2D8C6),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            'Capture',
                            style: GoogleFonts.caveat(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: _firebaseAuthReady
              ? PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBottomNavIndex = index;
                      if (index == 1) {
                        _hasUnreadMessages = false;
                      }
                    });
                  },
                  children: [
                    _buildMainFeedBody(isDark),
                    MessagesScreen(couple: widget.couple, myUid: _myUid, hideBottomDock: true),
                    ProfileScreen(couple: widget.couple, myUid: _myUid, hideBottomDock: true),
                    SettingsScreen(couple: widget.couple, hideBottomDock: true),
                  ],
                )
              : _buildShimmer(),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: _isScrolledNotifier,
            builder: (context, isScrolled, _) {
              return PaperBottomDock(
                currentIndex: _currentBottomNavIndex,
                isScrolled: isScrolled,
                hasUnreadMessages: _hasUnreadMessages,
                onHomeTap: () {
                  if (_currentBottomNavIndex == 0) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  } else {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                onChatTap: () {
                  setState(() {
                    _hasUnreadMessages = false;
                  });
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                onProfileTap: () {
                  _pageController.animateToPage(
                    2,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                onSettingsTap: () {
                  _pageController.animateToPage(
                    3,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return GestureDetector(
      onTap: _goToUpload,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Bottom shadow layer
            Container(
              width: 210,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFB05763), // Darker shade of pink for shadow
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(2, 6))],
              ),
            ),
            // Middle layer
            Container(
              width: 210,
              height: 52,
              margin: const EdgeInsets.only(bottom: 4), // Shift up to reveal bottom shadow
              decoration: BoxDecoration(
                color: const Color(0xFFDF7E8B),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Top layer (inner)
            Container(
              width: 198,
              height: 40,
              margin: const EdgeInsets.only(bottom: 4), // Shift up to match middle layer
              decoration: BoxDecoration(
                color: const Color(0xFFDF7E8B),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 2)), // subtle shadow for top layer
                  BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(-1, -1)), // highlight
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tiny Camera Icon inside button
                  Container(
                    width: 20,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBDDC2),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 1, offset: Offset(1, 1))],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 1,
                          left: 3,
                          child: Container(width: 4, height: 2, color: const Color(0xFFDF7E8B)),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDF7E8B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Capture Moment',
                    style: GoogleFonts.nunito(
                      color: const Color(0xFFEBDDC2), // Cream text
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      shadows: const [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: PaperLoadingPlaceholder(height: 320),
      ),
    );
  }

  Widget _buildEmpty() {
    return Stack(
      children: [
        // ── 1. Background Falling 3D Black Paper Leaves ──
        _buildFallingLeaves(),

        // ── 2. Main Center Scrapbook Card (Positioned Higher in Free Space) ──
        Align(
          alignment: const Alignment(0, -0.55),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _buildScrapbookCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildScrapbookCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerBg = isDark ? const Color(0xFF282E42) : const Color(0xFFEADBCA);
    final innerBg = isDark ? const Color(0xFF1E2335) : const Color(0xFFF7F4EB);
    final titleCol = isDark ? const Color(0xFFFAF3E0) : const Color(0xFF2C241B);
    final subTitleCol = isDark ? Colors.white60 : const Color(0xFF5A4D3B);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Base Outer Frame Shadow & Border
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: outerBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFFECE3D2) : const Color(0xFFD4C4AE), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),

              // Inner Cut-out Layer (Sunken effect)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: innerBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      spreadRadius: -1,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Red Circular Camera Badge
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC84B4B),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: innerBg, width: 4),
                      ),
                      child: const Icon(Icons.camera_alt, color: Color(0xFFF6E8D7), size: 28),
                    ),
                    const SizedBox(height: 16),

                    // Card Title & Subtitle
                    Text(
                      'Blank Scrapbook Page 🌼',
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: titleCol,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture and pin your first memory together\nhere!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: subTitleCol,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pin First Moment Button
                    ElevatedButton.icon(
                      onPressed: _goToUpload,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Pin First Moment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD36E7B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Top Left Scrapbook Tape Accent
        Positioned(
          top: -10,
          left: -10,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E0CE),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    'SCRAPBOOK PAGE',
                    style: GoogleFonts.caveat(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Top Right Red Pin Button
        Positioned(
          top: -8,
          right: 12,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFC84B4B),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildRedPin() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFC03C3B),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 4))],
      ),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Color(0xFFEBDDC2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFC03C3B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraBadge() {
    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        color: Color(0xFFC03C3B),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(3, 5))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Flash / Viewfinder bump
          Positioned(
            top: 24,
            left: 24,
            child: Container(
              width: 16,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFEBDDC2),
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 1, offset: Offset(0, 1))],
              ),
            ),
          ),
          // Main Body
          Container(
            width: 50,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEBDDC2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 2))],
            ),
          ),
          // Lens Outer
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFC03C3B),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(1, 1))],
            ),
          ),
          // Lens Inner
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFEBDDC2),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCorner(double angle) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: const Size(35, 35),
        painter: _PhotoCornerPainter(),
      ),
    );
  }

  Widget _buildPaperButton({required String text, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.25), width: 5)),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 5))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tiny Camera Icon inside button
            Container(
              width: 22,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFEBDDC2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 2,
                    left: 3,
                    child: Container(width: 4, height: 2, color: const Color(0xFFDF7E8B)),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDF7E8B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.caveat(
                color: const Color(0xFFEBDDC2),
                fontWeight: FontWeight.w700,
                fontSize: 24,
                shadows: const [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallingLeaves() {
    return Stack(
      children: [
        Positioned(top: 40, left: 20, child: _leaf(-0.5)),
        Positioned(top: 120, right: 30, child: _leaf(0.8)),
        Positioned(top: 240, left: 40, child: _leaf(-0.3)),
        Positioned(bottom: 180, right: 20, child: _leaf(0.2)),
        Positioned(bottom: 90, left: 25, child: _leaf(-0.7)),
        Positioned(bottom: 40, right: 70, child: _leaf(0.5)),
      ],
    );
  }

  Widget _leaf(double angle) {
    return Transform.rotate(
      angle: angle,
      child: const Icon(
        Icons.eco,
        color: Color(0xFF222429),
        size: 40,
        shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(3, 4))],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PaperCard(
          rotationAngle: -0.01,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: PaperColors.pinRed),
              const SizedBox(height: 14),
              Text(
                'Scrapbook Sync Issue',
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: PaperColors.darkInkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Could not retrieve moments. Please check network connection.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: PaperColors.darkInkSecondary,
                ),
              ),
              const SizedBox(height: 20),
              PaperButton(
                label: 'Retry Connection',
                icon: Icons.refresh_rounded,
                color: PaperColors.roseCutout,
                onPressed: () => setState(() {
                  _firebaseAuthReady = false;
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) setState(() => _firebaseAuthReady = true);
                  });
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFriendsFeed(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, color: Color(0xFFED8891), size: 48),
            const SizedBox(height: 12),
            Text(
              'No Friends Connected Yet',
              style: GoogleFonts.caveat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the friends button in the top right to search and connect with your friends!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                color: isDark ? Colors.white60 : PaperColors.inkMedium,
              ),
            ),
            const SizedBox(height: 16),
            PaperButton(
              label: 'Find Friends 🌸',
              color: PaperColors.roseCutout,
              onPressed: _goToFriends,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFriendsMoments(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, color: Color(0xFFED8891), size: 48),
            const SizedBox(height: 12),
            Text(
              'No Friends Moments Yet',
              style: GoogleFonts.caveat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When your connected friends pin moments, they will appear here!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                color: isDark ? Colors.white60 : PaperColors.inkMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MomentCard extends StatefulWidget {
  final MomentModel moment;
  final String myUid;
  final double rotationAngle;
  final VoidCallback onTap;

  const MomentCard({
    super.key,
    required this.moment,
    required this.myUid,
    this.rotationAngle = 0.0,
    required this.onTap,
  });

  @override
  State<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends State<MomentCard>
    with SingleTickerProviderStateMixin {
  final _momentService = MomentService();
  late AnimationController _heartController;
  late bool _isLiked;
  late int _localLikesCount;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _isLiked = widget.moment.likedBy.contains(widget.myUid);
    _localLikesCount = widget.moment.likesCount;
  }

  @override
  void didUpdateWidget(MomentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isToggling) {
      _isLiked = widget.moment.likedBy.contains(widget.myUid);
      _localLikesCount = widget.moment.likesCount;
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isToggling) return;
    _isToggling = true;
    HapticFeedback.lightImpact();

    final nextIsLiked = !_isLiked;
    final nextCount = nextIsLiked
        ? _localLikesCount + 1
        : math.max(0, _localLikesCount - 1);

    setState(() {
      _isLiked = nextIsLiked;
      _localLikesCount = nextCount;
    });

    if (nextIsLiked) {
      _heartController.forward().then((_) => _heartController.reverse());
    }

    try {
      await _momentService.toggleLike(widget.moment.id, widget.myUid);
    } catch (_) {} finally {
      if (mounted) {
        _isToggling = false;
      }
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isMyPost = widget.moment.postedBy == widget.myUid;

    return PaperPolaroid(
      rotationAngle: widget.rotationAngle,
      caption: widget.moment.caption.isNotEmpty ? widget.moment.caption : 'Memory 💕',
      dateText: _formatTime(widget.moment.createdAt),
      onTap: widget.onTap,
      child: Stack(
        children: [
          Positioned.fill(
            child: widget.moment.imageUrl.startsWith('data:image')
                ? Image.memory(
                    base64Decode(widget.moment.imageUrl.split(',').last),
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: widget.moment.imageUrl,
                    fit: BoxFit.cover,
                    memCacheHeight: 600,
                    placeholder: (context, url) => const PaperLoadingPlaceholder(
                      borderRadius: 0,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: PaperColors.kraftPaper,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: PaperColors.inkMedium,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
          ),

          // 🎥 Video Play Icon Overlay (if Video Moment)
          if (widget.moment.mediaType == 'video')
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),



          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _toggleLike,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PaperColors.darkCard.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _heartController,
                          builder: (_, __) => Transform.scale(
                            scale: 1.0 + _heartController.value * 0.3,
                            child: Icon(
                              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isLiked ? PaperColors.roseCutout : Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_localLikesCount',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: PaperChip(
              label: isMyPost ? 'You' : widget.moment.postedByName,
              backgroundColor: isMyPost ? PaperColors.roseCutout : PaperColors.sageCutout,
              textColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PHOTO CORNER BRACKET PAINTER
// ═══════════════════════════════════════════════════════════════════════════

class _PhotoCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEBDDC2)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - 12)
      ..lineTo(size.width - 12, 0)
      ..close();

    canvas.drawShadow(path, Colors.black45, 2.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




