import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/couple_model.dart';
import '../services/couple_service.dart';
import '../widgets/paper_widgets.dart';
import 'auth_screen.dart';
import 'pairing_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final User? initialUser;
  final CoupleModel? cachedCouple;
  final String? cachedUid;

  const SplashScreen({
    super.key,
    this.initialUser,
    this.cachedCouple,
    this.cachedUid,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final _coupleService = CoupleService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;

    final user = widget.initialUser;

    if (user != null) {
      final coupleId = await _coupleService.getCoupleIdForUser(user.uid);
      if (!mounted) return;

      if (coupleId != null) {
        final couple = await _coupleService.getCoupleById(coupleId);
        if (!mounted) return;
        if (couple != null) {
          _goHome(couple, user.uid);
          return;
        }
      }
      _goPairing();
      return;
    }

    if (widget.cachedCouple != null && widget.cachedUid != null) {
      _goHome(widget.cachedCouple!, widget.cachedUid!);
      return;
    }

    _goAuth();
  }

  void _goHome(CoupleModel couple, String uid) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: HomeScreen(couple: couple, cachedUid: uid),
        ),
      ),
    );
  }

  void _goPairing() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: const PairingScreen(),
        ),
      ),
    );
  }

  void _goAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: const AuthScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2E36), // Deep Charcoal Blue
      body: Stack(
        children: [
          // ── 1. Global Background (Textured Dark Paper) ──
          Positioned.fill(
            child: Container(color: const Color(0xFF2B2E36)),
          ),

          // Drifting Paper Petals Rain Particles
          const Positioned.fill(
            child: PaperPetalsRainOverlay(),
          ),

          // ── 2. Decoration Layer — Watercolor Clouds ──
          const Positioned(
            top: 60,
            left: 20,
            child: DriftingCloudWrapper(
              driftDistance: 12,
              duration: Duration(seconds: 7),
              child: SingleFeltCloudWidget(width: 110, height: 55, color: Color(0xFF4A5568)),
            ),
          ),
          const Positioned(
            top: 35,
            right: -15,
            child: DriftingCloudWrapper(
              driftDistance: -10,
              duration: Duration(seconds: 8),
              child: DualLayerFeltCloudWidget(width: 150, height: 75),
            ),
          ),

          // ── Scattered Gold & Silver Die-cut Stars ──
          const Positioned(
            top: 120,
            left: 100,
            child: TwinklingPaperCutStar(size: 8, color: Color(0xFFD4A843), rotation: 0.15),
          ),
          const Positioned(
            top: 165,
            right: 80,
            child: TwinklingPaperCutStar(size: 10, color: Color(0xFFFAF6EE), rotation: -0.2),
          ),
          const Positioned(
            top: 100,
            left: 220,
            child: TwinklingPaperCutStar(size: 6, color: Color(0xFFD4A843), rotation: 0.4),
          ),
          Positioned(
            bottom: 160,
            right: 40,
            child: Transform.rotate(
              angle: 0.3,
              child: const TwinklingPaperCutStar(size: 7, color: Color(0xFFFAF6EE), rotation: 0.6),
            ),
          ),

          // ── Floating Preserved Paper Leaves & Petals (from reference image) ──
          _buildFloatingLeaf(top: 220, left: 30, angle: 1.2, color: const Color(0xFFEBC1C2), size: 14),
          _buildFloatingLeaf(top: 280, right: 40, angle: -0.6, color: const Color(0xFF8B965C), size: 12),
          _buildFloatingLeaf(top: 340, left: 80, angle: 0.9, color: const Color(0xFFD4956E), size: 10),
          _buildFloatingLeaf(top: 400, right: 100, angle: -1.1, color: const Color(0xFF8B965C), size: 13),
          _buildFloatingLeaf(top: 500, left: 50, angle: 0.5, color: const Color(0xFFEBC1C2), size: 11),
          _buildFloatingLeaf(top: 450, right: 30, angle: -0.3, color: const Color(0xFFEBC1C2), size: 15),
          _buildFloatingLeaf(top: 550, right: 80, angle: 0.7, color: const Color(0xFFD4956E), size: 9),

          // ── 3. Ground Plane (Undulating Sandy Beach Diorama) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 160,
              child: CustomPaint(
                painter: WavyPaperPainter(),
              ),
            ),
          ),

          // ── 4. Main Content (Logo Group & Text Group) ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── LOGO GROUP — Concentric Rings + Scattered Petal Ring + Paper Flower ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing Activity Rings (Brand Accent coral)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final val = _pulseController.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 140 + (val * 40),
                              height: 140 + (val * 40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFEBC1C2).withValues(alpha: (1.0 - val) * 0.3),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // Scattered Petal Ring (floating pink petals orbiting the emblem)
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _ScatteredPetalRingPainter(
                              rotation: _pulseController.value * 2 * math.pi * 0.05,
                            ),
                          );
                        },
                      ),
                    ),

                    // Concentric Thin Dark Rings
                    Container(
                      width: 115,
                      height: 115,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 102,
                      height: 102,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                    ),

                    // Layered 3D Paper Hummingbird Logo
                    const PaperFlowerLogo(size: 86),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 24),

                // ── TEXT GROUP — "petals" Gold Foil Script ──
                Text(
                  'petals',
                  style: GoogleFonts.caveat(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEBDDC2),
                    letterSpacing: 1.5,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(1, 3)),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 10),

                // ── Subtitle Tag — "your scrapbook moments" cream paper tag ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBDDC2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2)),
                    ],
                  ),
                  child: Text(
                    'your scrapbook moments',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A332A),
                      letterSpacing: 0.4,
                    ),
                  ),
                ).animate().fadeIn(delay: 550.ms).scale(begin: const Offset(0.85, 0.85), end: const Offset(1.0, 1.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Floating preserved paper leaf ──
  Widget _buildFloatingLeaf({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double angle,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size * 1.6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.8),
              topRight: Radius.circular(size * 0.2),
              bottomLeft: Radius.circular(size * 0.2),
              bottomRight: Radius.circular(size * 0.8),
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 2))],
          ),
        ),
      ),
    );
  }
}

// ── SCATTERED PETAL RING PAINTER (orbiting pink petals around the emblem) ──
class _ScatteredPetalRingPainter extends CustomPainter {
  final double rotation;
  _ScatteredPetalRingPainter({this.rotation = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rng = math.Random(42); // Fixed seed for consistent placement

    const petalCount = 18;
    const orbitRadius = 90.0;

    for (int i = 0; i < petalCount; i++) {
      final baseAngle = (i / petalCount) * 2 * math.pi + rotation;
      // Add randomness to the radius and angle for scattered look
      final r = orbitRadius + rng.nextDouble() * 18 - 9;
      final a = baseAngle + (rng.nextDouble() - 0.5) * 0.35;

      final px = cx + r * math.cos(a);
      final py = cy + r * math.sin(a);

      // Petal size varies
      final petalW = 6.0 + rng.nextDouble() * 6;
      final petalH = petalW * (1.4 + rng.nextDouble() * 0.6);

      // Save and rotate canvas for each petal
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(a + math.pi / 4);

      // Draw petal shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(1, 2), width: petalW, height: petalH),
        shadowPaint,
      );

      // Draw petal body (alternating shades of pink)
      final petalColor = i.isEven
          ? const Color(0xFFEBC1C2) // Light blush pink
          : const Color(0xFFD4956E); // Warm salmon
      final paint = Paint()..color = petalColor.withValues(alpha: 0.85);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: petalW, height: petalH),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ScatteredPetalRingPainter old) => old.rotation != rotation;
}

// ── WAVY TORN PAPER GROUND PLANE PAINTER (Sandy Beach Diorama) ──
class WavyPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Dark torn paper backing (deep charcoal edge)
    final darkPath = Path()..moveTo(0, h * 0.30);
    for (double i = 0; i <= w; i += 8) {
      darkPath.lineTo(
        i,
        h * 0.30 + math.sin(i / 30) * 12 + math.cos(i / 18) * 6,
      );
    }
    darkPath.lineTo(w, h);
    darkPath.lineTo(0, h);
    darkPath.close();
    canvas.drawShadow(darkPath, Colors.black, 14.0, true);
    canvas.drawPath(darkPath, Paint()..color = const Color(0xFF1E2028));

    // Layer 2: Sand/Cork undulating wave (cream-tan)
    final sandPath = Path()..moveTo(0, h * 0.55);
    for (double i = 0; i <= w; i += 6) {
      sandPath.lineTo(
        i,
        h * 0.55 + math.sin(i / 40) * 10 + math.cos(i / 22) * 5,
      );
    }
    sandPath.lineTo(w, h);
    sandPath.lineTo(0, h);
    sandPath.close();
    canvas.drawShadow(sandPath, Colors.black87, 10.0, true);
    canvas.drawPath(sandPath, Paint()..color = const Color(0xFFE5D7BF)); // Sand tan
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
