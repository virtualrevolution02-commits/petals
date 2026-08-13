import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/couple_service.dart';
import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../models/couple_request_model.dart';
import '../widgets/paper_widgets.dart';
import 'home_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  final _coupleService = CoupleService();
  late TabController _tabController;

  UserModel? _currentUser;
  final _searchCtrl = TextEditingController();
  UserModel? _foundUser;
  bool _isSearching = false;
  bool _isSending = false;
  String? _error;
  String? _success;

  StreamSubscription<List<CoupleRequestModel>>? _incomingSubscription;
  StreamSubscription<CoupleRequestModel?>? _outgoingSubscription;
  List<CoupleRequestModel> _incomingRequests = [];
  CoupleRequestModel? _outgoingRequest;

  // Exact Color Tokens from High-Fidelity Spec Image
  final Color bgColor = const Color(0xFF222530); // Dark Charcoal-Navy
  final Color sageGreen = const Color(0xFF94A88B); // Soft Sage Green
  final Color coralPink = const Color(0xFFED8891); // Soft Dusty Pink
  final Color feltPink = const Color(0xFFE66B7C); // Accent Pink Felt
  final Color creamPaper = const Color(0xFFFAF6EE); // Cream Textured Paper
  final Color darkCard = const Color(0xFF383D4A); // Dark Charcoal Card

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final user = await _authService.getUserProfile(uid);
    if (!mounted) return;
    setState(() => _currentUser = user);
    _startListeners(uid);
  }

  void _startListeners(String uid) {
    _incomingSubscription = _coupleService
        .watchIncomingRequests(uid)
        .listen((requests) {
      if (!mounted) return;
      setState(() => _incomingRequests = requests);
    });

    _outgoingSubscription = _coupleService
        .watchOutgoingRequest(uid)
        .listen((req) {
      if (!mounted) return;
      setState(() => _outgoingRequest = req);
    });
  }

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    _outgoingSubscription?.cancel();
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
    setState(() { _isSearching = true; _foundUser = null; _error = null; });
    final user = await _coupleService.findUserByUsername(query);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _foundUser = user;
      if (user == null) _error = 'No user found with that username.';
    });
  }

  Future<void> _sendRequest() async {
    if (_foundUser == null || _currentUser == null) return;
    setState(() { _isSending = true; _error = null; _success = null; });
    try {
      await _coupleService.sendPairingRequest(
        fromUser: _currentUser!,
        toUser: _foundUser!,
      );
      if (!mounted) return;
      setState(() {
        _success = 'Request sent to @${_foundUser!.username}!';
        _foundUser = null;
        _searchCtrl.clear();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _accept(CoupleRequestModel request) async {
    try {
      final couple = await _coupleService.acceptRequest(request);
      final uid = _authService.currentUser?.uid ?? '';
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(couple: couple, cachedUid: uid)),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reject(CoupleRequestModel request) async {
    await _coupleService.rejectRequest(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request declined.')),
    );
  }

  void _copyUsername() {
    final username = _currentUser?.username ?? 'daisy.yohesh.7509';
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: username));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket code copied to clipboard!')),
    );
  }

  void _skipToProfile() {
    final uid = _authService.currentUser?.uid ?? '';
    final soloCouple = CoupleModel(
      id: 'solo_$uid',
      user1Uid: uid,
      user2Uid: '',
      user1Name: _currentUser?.displayName ?? 'You',
      user2Name: 'Partner',
      pairingCode: 'SOLO',
      createdAt: DateTime.now(),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(couple: soloCouple, cachedUid: uid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161925) : const Color(0xFFECE4D6);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── 1. Background Sky & Floating Petals ──
          Positioned.fill(
            child: Container(
              color: bgColor,
            ),
          ),

          // Floating Paper Petals Particle Rain
          const Positioned.fill(
            child: PaperPetalsRainOverlay(),
          ),

          // ── 2. Felt Cloud Die-cuts (Matching Spec Image) ──
          // Top Left Cloud
          const Positioned(
            top: 25,
            left: -15,
            child: DriftingCloudWrapper(
              driftDistance: 10,
              duration: Duration(seconds: 8),
              child: SingleFeltCloudWidget(width: 130, height: 65, color: Color(0xFF5A6677)),
            ),
          ),
          // Top Right Cloud
          const Positioned(
            top: 20,
            right: -20,
            child: DriftingCloudWrapper(
              driftDistance: -12,
              duration: Duration(seconds: 7),
              child: DualLayerFeltCloudWidget(width: 155, height: 75),
            ),
          ),
          // Mid-Right Floating Cloud (Ref Image 1 & 3 Match)
          const Positioned(
            top: 145,
            right: -15,
            child: DriftingCloudWrapper(
              driftDistance: -8,
              duration: Duration(seconds: 9),
              child: SingleFeltCloudWidget(width: 110, height: 55, color: Color(0xFF6B7889)),
            ),
          ),

          // Bottom Multi-Layered Sage Paper Hill Landscape (Animated Paper Diorama)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 210,
              child: AnimatedSagePaperLandscape(),
            ),
          ),

          // Bottom Left Paper Flower Accent
          Positioned(
            bottom: 25,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF6EE),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 3))],
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFFED8891), shape: BoxShape.circle),
                child: const Icon(Icons.local_florist, color: Colors.white, size: 16),
              ),
            ),
          ),



          // ── 5. Scrollable Main Content (Distributed vertically to fill screen) ──
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Upper Group (Header Logo, Title, Skip Action, Ticket Card) ──
                          Column(
                            children: [
                              const SizedBox(height: 2),

                              // ── A. Circular Heart Logo Mark (Spec Image Match) ──
                              _buildHeartLogo()
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), curve: Curves.elasticOut),

                              const SizedBox(height: 8),

                              // ── B. Title ("Connect Scrapbook") ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: coralPink,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Connect Petals',
                                    style: GoogleFonts.caveat(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: coralPink,
                                      letterSpacing: 0.5,
                                      shadows: const [
                                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2)),
                                      ],
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 200.ms),

                              const SizedBox(height: 10),

                              // ── C. Top Action Pill Button ("Explore Profile ➔") ──
                              PaperPressable(
                                onTap: _skipToProfile,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: sageGreen,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 4)),
                                    ],
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.explore_outlined, color: Color(0xFF2C302E), size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Explore Profile',
                                          style: GoogleFonts.nunito(
                                            color: const Color(0xFF2C302E),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('➔', style: TextStyle(color: Color(0xFF2C302E), fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 300.ms),

                              const SizedBox(height: 12),

                              // ── D. YOUR TICKET CARD (Layered Ticket - Spec Image Match) ──
                              _buildTicketCard(
                                username: _currentUser?.username ?? 'daisy.yohesh.7509',
                                displayName: _currentUser?.displayName ?? 'yohesh',
                              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Lower Group (Find Partner Tabs, Search Input, Banners) ──
                          Column(
                            children: [
                              // ── E. Segmented Control Tabs (Find Partner / Requests) ──
                              Container(
                                height: 44,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: isDark ? darkCard : const Color(0xFFE6D8C6),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2)),
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
                                  unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B635E),
                                  labelStyle: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                  tabs: [
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.search, size: 16),
                                          SizedBox(width: 6),
                                          Text('Find Partner'),
                                        ],
                                      ),
                                    ),
                                    Tab(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.mail_outline, size: 16),
                                          const SizedBox(width: 6),
                                          const Text('Requests'),
                                          if (_incomingRequests.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${_incomingRequests.length}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: feltPink,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 500.ms),

                              const SizedBox(height: 16),

                              // ── F. Tab Content Area (Partner Search Input / Requests List) ──
                              AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, _) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: _tabController.index == 0 ? _buildFindTab() : _buildRequestsTab(),
                                  );
                                },
                              ).animate().fadeIn(delay: 600.ms),

                              // Error & Success Feedback Banners
                              if (_error != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: coralPink.withValues(alpha: isDark ? 0.2 : 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: coralPink),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: coralPink, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: GoogleFonts.nunito(color: isDark ? creamPaper : const Color(0xFF6B1D24), fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().shake(),

                              if (_success != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: sageGreen.withValues(alpha: isDark ? 0.25 : 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: sageGreen),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: sageGreen, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _success!,
                                          style: GoogleFonts.nunito(color: isDark ? creamPaper : const Color(0xFF1E3F20), fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(),

                              const SizedBox(height: 28), // Bottom spacing for landscape
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER CIRCULAR PAPER CUT FLOWER LOGO ──
  Widget _buildHeartLogo() {
    return const PaperCutLogo(size: 76);
  }

  // ── YOUR TICKET CARD (Spec Image Match) ──
  Widget _buildTicketCard({required String username, required String displayName}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dark Charcoal Base Card Frame
        Container(
          width: double.infinity,
          height: 205,
          decoration: BoxDecoration(
            color: const Color(0xFF383D4A),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(4, 8)),
              BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(-1, -1)),
            ],
          ),
        ),

        // Pink Wavy Scalloped Paper Edge Layer
        Positioned(
          top: 8, left: 8, right: 8, bottom: 8,
          child: CustomPaint(
            painter: WavyBorderPainter(color: coralPink),
          ),
        ),

        // Flecked Cream Textured Paper Ticket Face (Ref Image Match)
        Positioned(
          top: 14, left: 14, right: 14, bottom: 14,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: FleckedCreamPaperPainter(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('👋', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          'Hi, $displayName!',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3E3832),
                            fontSize: 15.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: GoogleFonts.caveat(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: coralPink,
                        letterSpacing: 0.5,
                        shadows: const [
                          Shadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    PaperPressable(
                      onTap: _copyUsername,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: darkCard,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(2, 4)),
                            BoxShadow(color: Colors.white10, blurRadius: 1, offset: Offset(-1, -1)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Copy Ticket Code',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Pinned/Tilted "YOUR TICKET" Kraft Tag (Animated Swinging Paper Tag)
        Positioned(
          top: -14, left: 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 18, right: 12, top: 5, bottom: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5D7C0), // Kraft cream paper tag
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(2, 3)),
                  ],
                ),
                child: Text(
                  'YOUR TICKET',
                  style: GoogleFonts.caveat(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E3424),
                  ),
                ),
              ),
              // Brass Pin Dot
              Positioned(
                left: 4,
                top: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC9A25A),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 2, offset: Offset(1, 1))],
                  ),
                ),
              ),
            ],
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(
            begin: -0.12,
            end: -0.04,
            duration: 2400.ms,
            curve: Curves.easeInOutSine,
            alignment: Alignment.topLeft,
          )
          .moveY(
            begin: 0,
            end: -2.5,
            duration: 2400.ms,
            curve: Curves.easeInOutSine,
          ),
        ),
      ],
    );
  }

  // ── FIND PARTNER TAB CONTENT (Prominent & Larger Search UI) ──
  Widget _buildFindTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24), // Top margin for elevated tag
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Input + Button Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Dark Torn Paper Input Box (Prominent & Larger)
                Expanded(
                  child: CustomPaint(
                    painter: TornPaperInputPainter(),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: const Text(
                                '@',
                                style: TextStyle(
                                  color: Color(0xFFED8891),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            hintText: 'e.g. priya_123',
                            hintStyle: GoogleFonts.nunito(
                              color: const Color(0xFF94A3B8),
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sage-Green Search Action Button (Larger 56px)
                PaperPressable(
                  onTap: _isSearching ? null : _searchUser,
                  child: Container(
                    width: 62,
                    height: 56,
                    decoration: BoxDecoration(
                      color: sageGreen,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(2, 4)),
                        BoxShadow(color: Colors.white24, blurRadius: 1.5, offset: Offset(-1, -1)),
                      ],
                    ),
                    child: _isSearching
                        ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                        : const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),

            // Pinned Overlapping Tag ("Partner's Username" - Elevated Higher)
            Positioned(
              top: -25,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFE3D3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 5, offset: Offset(1.5, 2.5)),
                  ],
                ),
                child: Text(
                  "Partner's Username",
                  style: GoogleFonts.caveat(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C241B),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (_outgoingRequest != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? darkCard : const Color(0xFFFCFAF7),
              borderRadius: BorderRadius.circular(12),
              border: isDark ? null : Border.all(color: const Color(0xFFD5C9B8)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 3))],
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, color: sageGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request sent to', style: GoogleFonts.nunito(color: isDark ? Colors.white70 : const Color(0xFF6B635E), fontSize: 12)),
                      Text('@${_outgoingRequest!.toUsername}', style: GoogleFonts.caveat(color: coralPink, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sageGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Waiting', style: GoogleFonts.nunito(color: sageGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ).animate().fadeIn(),

        if (_foundUser != null)
          _FoundUserCard(
            user: _foundUser!,
            isSending: _isSending,
            onSend: _sendRequest,
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
      ],
    );
  }

  // ── REQUESTS TAB CONTENT ──
  Widget _buildRequestsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_incomingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_unread_outlined, color: coralPink, size: 44),
            const SizedBox(height: 8),
            Text('No Pending Requests', style: GoogleFonts.caveat(fontSize: 22, color: isDark ? creamPaper : const Color(0xFF3E3832))),
            const SizedBox(height: 4),
            Text('Share your ticket code with your partner!', style: GoogleFonts.nunito(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF6B635E))),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _incomingRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _RequestCard(
        request: _incomingRequests[i],
        onAccept: () => _accept(_incomingRequests[i]),
        onReject: () => _reject(_incomingRequests[i]),
      ).animate().fadeIn(delay: (i * 100).ms),
    );
  }
}

// ── WAVY PINK TICKET BORDER PAINTER ──
class WavyBorderPainter extends CustomPainter {
  final Color color;
  WavyBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    double waveWidth = 10.0;
    double waveHeight = 3.5;

    // Top edge
    path.moveTo(0, 0);
    for (double i = 0; i <= size.width; i += waveWidth) {
      path.quadraticBezierTo(i + (waveWidth / 2), -waveHeight, i + waveWidth, 0);
    }

    // Right edge
    for (double i = 0; i <= size.height; i += waveWidth) {
      path.quadraticBezierTo(size.width + waveHeight, i + (waveWidth / 2), size.width, i + waveWidth);
    }

    // Bottom edge
    for (double i = size.width; i >= 0; i -= waveWidth) {
      path.quadraticBezierTo(i - (waveWidth / 2), size.height + waveHeight, i - waveWidth, size.height);
    }

    // Left edge
    for (double i = size.height; i >= 0; i -= waveWidth) {
      path.quadraticBezierTo(-waveHeight, i - (waveWidth / 2), 0, i - waveWidth);
    }

    path.close();

    canvas.drawShadow(path, Colors.black87, 4.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── FLECKED CREAM TEXTURED PAPER PAINTER (Matching Zoomed Ticket Ref Image) ──
class FleckedCreamPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFAF6EE);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)), bgPaint);

    // Subtle natural paper fibers & speckles
    final fleckPaint = Paint()
      ..color = const Color(0xFF8C7A63).withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final rand = math.Random(42);
    for (int i = 0; i < 35; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final len = 2.0 + rand.nextDouble() * 3.0;
      final angle = rand.nextDouble() * math.pi;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        fleckPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FoundUserCard extends StatelessWidget {
  final UserModel user;
  final bool isSending;
  final VoidCallback onSend;

  const _FoundUserCard({
    required this.user,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF383B44) : const Color(0xFFFCFAF7),
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: const Color(0xFFD5C9B8)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFED8891),
            child: Text(user.displayName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: GoogleFonts.nunito(color: isDark ? Colors.white : const Color(0xFF2C2825), fontWeight: FontWeight.bold)),
                Text('@${user.username}', style: GoogleFonts.caveat(color: const Color(0xFFED8891), fontSize: 16)),
              ],
            ),
          ),
          PaperPressable(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFED8891),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Connect', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CoupleRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF383B44) : const Color(0xFFFCFAF7),
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: const Color(0xFFD5C9B8)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFED8891),
                child: Text(request.fromName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.fromName, style: GoogleFonts.nunito(color: isDark ? Colors.white : const Color(0xFF2C2825), fontWeight: FontWeight.bold)),
                    Text('@${request.fromUsername}', style: GoogleFonts.caveat(color: const Color(0xFFED8891), fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('wants to share scrapbook moments', style: GoogleFonts.caveat(color: isDark ? Colors.white70 : const Color(0xFF6B635E), fontSize: 17)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PaperPressable(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF454545) : const Color(0xFFE6D8C6), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('Decline', style: GoogleFonts.nunito(color: isDark ? Colors.white70 : const Color(0xFF3E3832), fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PaperPressable(
                  onTap: onAccept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(color: const Color(0xFFED8891), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('Accept', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



// ── TORN PAPER INPUT FIELD PAINTER (Ref Image 2 Match) ──
class TornPaperInputPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cream torn paper rough outline background
    final creamPath = Path();
    creamPath.moveTo(0, 2.5);
    for (double i = 0; i <= w; i += 5) {
      creamPath.lineTo(i, 2.5 + math.sin(i / 4) * 1.2 + math.cos(i / 2) * 0.8);
    }
    creamPath.lineTo(w, h - 2.5);
    for (double i = w; i >= 0; i -= 5) {
      creamPath.lineTo(i, h - 2.5 + math.cos(i / 4) * 1.2 + math.sin(i / 2) * 0.8);
    }
    creamPath.close();

    canvas.drawShadow(creamPath, Colors.black45, 5.0, true);
    canvas.drawPath(creamPath, Paint()..color = const Color(0xFFE6DBC6));

    // Dark charcoal input center fill
    final darkPath = Path();
    darkPath.moveTo(2.5, 5.0);
    for (double i = 2.5; i <= w - 2.5; i += 5) {
      darkPath.lineTo(i, 5.0 + math.sin(i / 5) * 0.8);
    }
    darkPath.lineTo(w - 2.5, h - 5.0);
    for (double i = w - 2.5; i >= 2.5; i -= 5) {
      darkPath.lineTo(i, h - 5.0 + math.cos(i / 5) * 0.8);
    }
    canvas.drawPath(darkPath, Paint()..color = const Color(0xFF272A32));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
