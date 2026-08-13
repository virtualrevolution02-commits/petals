import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/paper_widgets.dart';
import 'pairing_screen.dart';
import 'home_screen.dart';
import 'setup_profile_screen.dart';
import '../services/couple_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _coupleService = CoupleService();
  late TabController _tabController;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterAuth(String uid) async {
    final userProfile = await _authService.getUserProfile(uid);
    if (!mounted) return;

    void continueNavigation() async {
      final coupleId = await _coupleService.getCoupleIdForUser(uid);
      if (!mounted) return;
      if (coupleId != null) {
        final couple = await _coupleService.getCoupleById(coupleId);
        if (!mounted) return;
        if (couple != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(couple: couple, cachedUid: uid)),
          );
          return;
        }
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PairingScreen()),
      );
    }

    if (userProfile != null && !userProfile.isProfileSetup) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SetupProfileScreen(
            user: userProfile,
            onComplete: continueNavigation,
          ),
        ),
      );
    } else {
      continueNavigation();
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        setState(() => _error = 'Google sign-in cancelled.');
        return;
      }
      await _navigateAfterAuth(user.uid);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await _authService.signInWithEmail(
          _emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted || user == null) return;
      await _navigateAfterAuth(user.uid);
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithEmail() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.length < 6) {
      setState(() => _error = 'Enter email and a password (min 6 chars).');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await _authService.registerWithEmail(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _nameCtrl.text.trim(),
      );
      if (!mounted || user == null) return;
      await _navigateAfterAuth(user.uid);
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String e) {
    if (e.contains('user-not-found')) return 'No account found with this email.';
    if (e.contains('wrong-password')) return 'Incorrect password.';
    if (e.contains('email-already-in-use')) return 'Email registered. Try signing in.';
    if (e.contains('weak-password')) return 'Use at least 6 characters.';
    if (e.contains('invalid-email')) return 'Invalid email address.';
    return e.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242938), // bg.navy
      body: Stack(
        children: [
          // ── 1. Backdrop Vignette Gradient ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF242938), // bg.navy
                    Color(0xFF1C202B), // bg.navyDeep
                  ],
                ),
              ),
            ),
          ),

          // ── 1.5 Falling Paper Petals Rain Animation Overlay ──
          const Positioned.fill(
            child: PaperPetalsRainOverlay(),
          ),

          // ── 2. Felt Clouds (Drifting Floating Animation) ──
          // Left Edge Cloud
          const Positioned(
            top: 85,
            left: -25,
            child: DriftingCloudWrapper(
              driftDistance: 10,
              duration: Duration(seconds: 8),
              child: SingleFeltCloudWidget(width: 95, height: 48, color: Color(0xFF536074)),
            ),
          ),
          // Top-Left Cloud
          const Positioned(
            top: 25,
            left: 70,
            child: DriftingCloudWrapper(
              driftDistance: 14,
              duration: Duration(seconds: 7),
              child: SingleFeltCloudWidget(width: 125, height: 58, color: Color(0xFF536074)),
            ),
          ),
          // Right Dual-Layer Cloud
          const Positioned(
            top: 55,
            right: -15,
            child: DriftingCloudWrapper(
              driftDistance: -12,
              duration: Duration(seconds: 9),
              child: DualLayerFeltCloudWidget(width: 155, height: 75),
            ),
          ),

          // ── 3. 5-Pointed Twinkling Paper Cut Stars (Blinking Sky Stars - Spec Request) ──
          // Star below top-left cloud (Red Circle 1)
          const Positioned(
            top: 112,
            left: 108,
            child: TwinklingPaperCutStar(
              size: 13,
              color: Color(0xFFFAF6EE),
              rotation: -0.1,
              duration: Duration(milliseconds: 1600),
            ),
          ),
          // Star right of top-left cloud (Red Circle 1)
          const Positioned(
            top: 65,
            left: 205,
            child: TwinklingPaperCutStar(
              size: 12,
              color: Color(0xFFFAF6EE),
              rotation: 0.2,
              duration: Duration(milliseconds: 2100),
              delay: Duration(milliseconds: 400),
            ),
          ),
          // Star left of right dual cloud (Red Circle 2)
          const Positioned(
            top: 55,
            right: 145,
            child: TwinklingPaperCutStar(
              size: 14,
              color: Color(0xFFFAF6EE),
              rotation: 0.15,
              duration: Duration(milliseconds: 1800),
              delay: Duration(milliseconds: 700),
            ),
          ),
          // Star top right near center (Red Circle 2)
          const Positioned(
            top: 18,
            right: 78,
            child: TwinklingPaperCutStar(
              size: 13,
              color: Color(0xFFFAF6EE),
              rotation: -0.1,
              duration: Duration(milliseconds: 2300),
              delay: Duration(milliseconds: 200),
            ),
          ),

          // ── 6. Origami Crane (Upper Right) ──
          Positioned(
            top: 135,
            right: 28,
            child: const FloatingOrigamiBird(size: 56)
                .animate()
                .slide(begin: const Offset(0.4, -0.4), end: Offset.zero, duration: 1200.ms, curve: Curves.easeOutQuad),
          ),

          // ── 7. Cascading Hearts (Trailing down to Card Tab Row) ──
          Positioned(
            top: 180,
            right: 65,
            child: const PaperFoldedHeart(size: 18, color: Color(0xFFE8967D), rotation: -0.2)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.08, 1.08), duration: 1200.ms),
          ),
          Positioned(
            top: 208,
            right: 92,
            child: const PaperFoldedHeart(size: 22, color: Color(0xFFE68668), rotation: 0.15)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.08, 1.08), delay: 200.ms, duration: 1200.ms),
          ),
          Positioned(
            top: 236,
            right: 118,
            child: const PaperFoldedHeart(size: 26, color: Color(0xFFE8967D), rotation: -0.1)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.08, 1.08), delay: 400.ms, duration: 1200.ms),
          ),

          // ── 14. Olive Leaf Sprigs (Near Password Field Right Edge) ──
          Positioned(
            top: 480,
            right: 25,
            child: PaperCutoutDecoration(
              shape: CutoutShape.leaf,
              color: const Color(0xFF8B965C), // leaf.olive
              size: 24,
              rotation: 0.8,
              depth: 1,
            ).animate().fadeIn(delay: 900.ms),
          ),
          Positioned(
            top: 512,
            right: 48,
            child: PaperCutoutDecoration(
              shape: CutoutShape.leaf,
              color: const Color(0xFF8B965C),
              size: 20,
              rotation: -0.5,
              depth: 1,
            ).animate().fadeIn(delay: 1000.ms),
          ),
          Positioned(
            top: 540,
            right: 20,
            child: PaperCutoutDecoration(
              shape: CutoutShape.leaf,
              color: const Color(0xFF8B965C),
              size: 22,
              rotation: 0.3,
              depth: 1,
            ).animate().fadeIn(delay: 1100.ms),
          ),

          // ── Main Content Layer ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── 4. Logo Mark ──
                    const PaperFlowerLogo(size: 64)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.04, 1.04), duration: 2500.ms, curve: Curves.easeInOut),

                    const SizedBox(height: 6),

                    // ── 5. Wordmark ("petals") & Tagline ──
                    Text(
                      'petals',
                      style: GoogleFonts.caveat(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF4EEDD),
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    Text(
                      'handcrafted couple scrapbook',
                      style: GoogleFonts.caveat(
                        fontSize: 15,
                        color: const Color(0xFFF4EEDD).withValues(alpha: 0.85),
                        letterSpacing: 1.1,
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 22),

                    // ── Main Scrapbook Page Card ──
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          painter: TornPaperCardPainter(
                            fillColor: const Color(0xFFEEE6D3), // card.cream
                            kraftColor: const Color(0xFFC9A96A), // card.kraftEdge
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),

                                // ── 9. Google Button Sticker (Matching Reference Image) ──
                                GoogleStickerButton(
                                  onTap: _isLoading ? null : _signInWithGoogle,
                                  isLoading: _isLoading,
                                ).animate().fadeIn(delay: 450.ms),

                                const SizedBox(height: 14),

                                // ── 10. Divider ("or email") ──
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Color(0xFFC9BEAA), thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'or email',
                                        style: GoogleFonts.patrickHand(
                                          fontSize: 15,
                                          color: const Color(0xFF3A332A).withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Color(0xFFC9BEAA), thickness: 1)),
                                  ],
                                ).animate().fadeIn(delay: 500.ms),

                                const SizedBox(height: 14),

                                // ── 11. Tab Switcher (Full 50/50 Segmented Pill) ──
                                Container(
                                  height: 44,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF242938), // bg.navy inactive tab
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2)),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            _tabController.animateTo(0);
                                            setState(() {});
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            decoration: BoxDecoration(
                                              color: _tabController.index == 0 ? const Color(0xFFE68668) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(19),
                                              boxShadow: _tabController.index == 0
                                                  ? const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2))]
                                                  : [],
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Sign In',
                                                style: GoogleFonts.nunito(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.5,
                                                  color: _tabController.index == 0 ? const Color(0xFFF4EEDD) : const Color(0xFF8A93A4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            _tabController.animateTo(1);
                                            setState(() {});
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            decoration: BoxDecoration(
                                              color: _tabController.index == 1 ? const Color(0xFFE68668) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(19),
                                              boxShadow: _tabController.index == 1
                                                  ? const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2))]
                                                  : [],
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Register',
                                                style: GoogleFonts.nunito(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.5,
                                                  color: _tabController.index == 1 ? const Color(0xFFF4EEDD) : const Color(0xFF8A93A4),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 550.ms),

                                const SizedBox(height: 16),

                                // ── Form Area ──
                                AnimatedBuilder(
                                  animation: _tabController,
                                  builder: (context, child) {
                                    return _tabController.index == 0
                                        ? _buildSignInForm()
                                        : _buildRegisterForm();
                                  },
                                ).animate().fadeIn(delay: 600.ms),
                              ],
                            ),
                          ),
                        ),

                        // ── 8. "WELCOME" Luggage Tag (Swaying Pendulum Dangling Animation) ──
                        Positioned(
                          top: -14,
                          left: 10,
                          child: const SwayingKraftLuggageTag(text: 'WELCOME')
                              .animate().fadeIn(delay: 400.ms).slideY(begin: -0.3, end: 0),
                        ),
                      ],
                    ),

                    // ── Error Message Banner ──
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE68668).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE68668).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFE68668), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.nunito(
                                  color: const Color(0xFF3A332A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().shake(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 12. Handwriting Field Label ──
        Text(
          'Email Address',
          style: GoogleFonts.patrickHand(fontSize: 16, color: const Color(0xFF3A332A), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        // ── 13. Input Field (field.taupe #4C4136) ──
        _buildPaperTextField(_emailCtrl, 'your.email@example.com', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 12),

        Text(
          'Password',
          style: GoogleFonts.patrickHand(fontSize: 16, color: const Color(0xFF3A332A), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _buildPaperTextField(_passwordCtrl, '••••••••', Icons.lock_outline, TextInputType.visiblePassword, isPassword: true),
        const SizedBox(height: 18),

        // ── 15. Primary CTA ("Sign In") Felt Button (Matching Felt Texture Spec) ──
        FeltCtaButton(
          label: 'Sign In',
          onTap: _isLoading ? null : _signInWithEmail,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Name',
          style: GoogleFonts.patrickHand(fontSize: 16, color: const Color(0xFF3A332A), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _buildPaperTextField(_nameCtrl, 'e.g. Alex', Icons.person_outline, TextInputType.name),
        const SizedBox(height: 10),

        Text(
          'Email Address',
          style: GoogleFonts.patrickHand(fontSize: 16, color: const Color(0xFF3A332A), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _buildPaperTextField(_emailCtrl, 'your.email@example.com', Icons.email_outlined, TextInputType.emailAddress),
        const SizedBox(height: 10),

        Text(
          'Password',
          style: GoogleFonts.patrickHand(fontSize: 16, color: const Color(0xFF3A332A), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _buildPaperTextField(_passwordCtrl, 'Min 6 characters', Icons.lock_outline, TextInputType.visiblePassword, isPassword: true),
        const SizedBox(height: 16),

        // Register CTA
        PaperPressable(
          onTap: _isLoading ? null : _registerWithEmail,
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8B965C), // leaf.olive
                  Color(0xFF7A844E),
                ],
              ),
              borderRadius: BorderRadius.circular(23),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(2, 4)),
                BoxShadow(color: Colors.white24, blurRadius: 1, offset: Offset(-1, -1)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                  )
                else ...[
                  const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFF4EEDD), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Create Account',
                    style: GoogleFonts.nunito(
                      color: const Color(0xFFF4EEDD),
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 13. Input Field helper (field.taupe #4C4136 fill, recessed look) ──
  Widget _buildPaperTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    TextInputType keyboardType, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4C4136), // field.taupe
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(1, 2)),
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(-1, -1)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: GoogleFonts.patrickHand(color: const Color(0xFFF4EEDD), fontSize: 17),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.patrickHand(
            color: const Color(0xFFF4EEDD).withValues(alpha: 0.5),
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 4, right: 8),
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: const Color(0xFFE68668), size: 19), // accent.coral icon
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFFF4EEDD).withValues(alpha: 0.6),
                    size: 19,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        ),
      ),
    );
  }

}

