import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Authentic Stop-Motion Paper Diorama Animation Engine
/// All animations simulate physical paper pieces being placed by hand.
class PaperAnimations {
  static final _random = Random();

  /// Discrete frame step value generator for stop-motion (e.g. 10 fps stepping)
  static double quantize(double value, int steps) {
    if (steps <= 0) return value;
    return (value * steps).round() / steps;
  }

  /// Stop-motion unfold entrance wrapper with paper assembly stagger
  static Widget applyPaperUnfold(Widget child, {int index = 0, Duration delay = Duration.zero}) {
    final staggerDelay = delay + Duration(milliseconds: (index * 120).clamp(0, 600));
    return PaperLayerAssembly(
      delay: staggerDelay,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. STOP MOTION WRAPPER — Discrete frame micro-jitter (10-12 fps)
// ═══════════════════════════════════════════════════════════════════════════

class StopMotionWrapper extends StatefulWidget {
  final Widget child;
  final bool enableJitter;
  final double maxJitterAngle; // in radians (~0.015 rad = ~0.8 deg)
  final double maxJitterOffset; // in pixels (~1.5 px)
  final int fps; // 10 fps for classic stop-motion feel

  const StopMotionWrapper({
    super.key,
    required this.child,
    this.enableJitter = false,
    this.maxJitterAngle = 0.012,
    this.maxJitterOffset = 1.2,
    this.fps = 10,
  });

  @override
  State<StopMotionWrapper> createState() => _StopMotionWrapperState();
}

class _StopMotionWrapperState extends State<StopMotionWrapper> {
  Timer? _stepTimer;
  double _currentAngleJitter = 0.0;
  Offset _currentOffsetJitter = Offset.zero;

  @override
  void initState() {
    super.initState();
    if (widget.enableJitter) {
      _startStopMotionTimer();
    }
  }

  void _startStopMotionTimer() {
    final intervalMs = (1000 / widget.fps).round();
    _stepTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!mounted) return;
      final rng = Random();
      setState(() {
        _currentAngleJitter = (rng.nextDouble() * 2 - 1) * widget.maxJitterAngle;
        _currentOffsetJitter = Offset(
          (rng.nextDouble() * 2 - 1) * widget.maxJitterOffset,
          (rng.nextDouble() * 2 - 1) * widget.maxJitterOffset,
        );
      });
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableJitter) return widget.child;
    return Transform.translate(
      offset: _currentOffsetJitter,
      child: Transform.rotate(
        angle: _currentAngleJitter,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. PAPER LAYER ASSEMBLY — Stop-motion "placed by hand" entrance
//    Elements drop in from above with discrete steps, slight tilt,
//    growing shadow, and tiny settle bounce.
// ═══════════════════════════════════════════════════════════════════════════

class PaperLayerAssembly extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final int steps; // Number of discrete stop-motion frames
  final double dropDistance; // How far above the element starts

  const PaperLayerAssembly({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.steps = 5,
    this.dropDistance = 30.0,
  });

  @override
  State<PaperLayerAssembly> createState() => _PaperLayerAssemblyState();
}

class _PaperLayerAssemblyState extends State<PaperLayerAssembly> {
  int _currentStep = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
        if (!mounted) return;
        if (_currentStep >= widget.steps) {
          t.cancel();
        } else {
          setState(() => _currentStep++);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep / widget.steps).clamp(0.0, 1.0);

    if (progress == 0.0) {
      return const SizedBox.shrink();
    }

    // Stop-motion quantized values (discrete steps, not smooth)
    final quantizedProgress = PaperAnimations.quantize(progress, widget.steps);

    // Drop from above
    final yOffset = widget.dropDistance * (1.0 - quantizedProgress);

    // Slight tilt during placement (settles to 0)
    final tiltAngle = (1.0 - quantizedProgress) * 0.03;

    // Scale from 0.85 to 1.0 (paper being "placed down")
    final scale = 0.85 + (0.15 * quantizedProgress);

    // Opacity fades in quickly
    final opacity = quantizedProgress < 0.2 ? quantizedProgress * 5 : 1.0;

    // Shadow grows as element "lands" on the surface
    final shadowOpacity = quantizedProgress * 0.2;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, -yOffset),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(tiltAngle)
            ..scale(scale),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                if (shadowOpacity > 0)
                  BoxShadow(
                    color: Color.fromRGBO(53, 46, 40, shadowOpacity),
                    offset: Offset(1.5 * quantizedProgress, 3.0 * quantizedProgress),
                    blurRadius: 4.0 * quantizedProgress,
                  ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. PAPER PEEL REVEAL — Diagonal clip reveal like peeling a sticker
// ═══════════════════════════════════════════════════════════════════════════

class PaperPeelReveal extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const PaperPeelReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<PaperPeelReveal> createState() => _PaperPeelRevealState();
}

class _PaperPeelRevealState extends State<PaperPeelReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _revealAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        return ClipPath(
          clipper: _DiagonalPeelClipper(progress: _revealAnimation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _DiagonalPeelClipper extends CustomClipper<Path> {
  final double progress;
  _DiagonalPeelClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    // Diagonal reveal from top-left to bottom-right
    final diag = progress * (size.width + size.height);

    path.moveTo(0, 0);
    if (diag <= size.width) {
      path.lineTo(diag, 0);
      path.lineTo(0, diag);
    } else if (diag <= size.height) {
      path.lineTo(size.width, 0);
      path.lineTo(size.width, diag - size.width);
      path.lineTo(0, diag);
    } else {
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _DiagonalPeelClipper old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. STOP MOTION ENTRANCE — Enhanced with Y-axis tilt and shadow growth
// ═══════════════════════════════════════════════════════════════════════════

class StopMotionEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final int steps;

  const StopMotionEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.steps = 4,
  });

  @override
  State<StopMotionEntrance> createState() => _StopMotionEntranceState();
}

class _StopMotionEntranceState extends State<StopMotionEntrance> {
  int _currentStep = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(milliseconds: 70), (t) {
        if (!mounted) return;
        if (_currentStep >= widget.steps) {
          t.cancel();
        } else {
          setState(() => _currentStep++);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep / widget.steps).clamp(0.0, 1.0);
    final scale = 0.7 + (0.3 * progress);
    final opacity = progress == 0.0 ? 0.0 : progress;
    // Y-axis tilt during entrance — paper tilts as it's being "placed"
    final tiltY = (1.0 - progress) * 0.04;
    final shadowScale = progress;

    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(tiltY)
          ..scale(scale),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              if (shadowScale > 0.1)
                BoxShadow(
                  color: Color.fromRGBO(53, 46, 40, 0.15 * shadowScale),
                  offset: Offset(2.0 * shadowScale, 3.5 * shadowScale),
                  blurRadius: 5.0 * shadowScale,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. PAPER CORNER PEEL — Interactive corner peel-back
// ═══════════════════════════════════════════════════════════════════════════

class PaperCornerPeel extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PaperCornerPeel({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<PaperCornerPeel> createState() => _PaperCornerPeelState();
}

class _PaperCornerPeelState extends State<PaperCornerPeel> {
  bool _isPeeled = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPeeled = true),
      onTapUp: (_) {
        setState(() => _isPeeled = false);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPeeled = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_isPeeled ? -0.05 : 0)
              ..rotateY(_isPeeled ? 0.05 : 0),
            alignment: Alignment.center,
            child: widget.child,
          ),
          if (_isPeeled)
            Positioned(
              top: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(20, 20),
                painter: _PeelCornerPainter(),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeelCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, shadowPaint);

    final foldPaint = Paint()
      ..color = const Color(0xFFE8E2D9)
      ..style = PaintingStyle.fill;

    final foldPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width - 16, 0)
      ..lineTo(size.width, 16)
      ..close();

    canvas.drawPath(foldPath, foldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. PAPER FOLD FLIP — 3D fold transition
// ═══════════════════════════════════════════════════════════════════════════

class PaperFoldFlip extends StatelessWidget {
  final Widget child;
  final bool isFlipped;

  const PaperFoldFlip({
    super.key,
    required this.child,
    this.isFlipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween(begin: pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final isUnder = (ValueKey(isFlipped) != child?.key);
            var tilt = (animation.value - 0.5).abs() - 0.5;
            tilt *= isUnder ? -0.003 : 0.003;
            final value = isUnder ? min(rotate.value, pi / 2) : rotate.value;
            return Transform(
              transform: Matrix4.rotationY(value)..setEntry(3, 2, tilt),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. PAPER PARALLAX SCROLL — Depth-based scroll parallax
// ═══════════════════════════════════════════════════════════════════════════

class PaperParallaxScroll extends StatelessWidget {
  final Widget child;
  final int depth; // 0 = back (slow), 1 = mid, 2 = fore (normal)
  final double scrollOffset;

  const PaperParallaxScroll({
    super.key,
    required this.child,
    this.depth = 1,
    this.scrollOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Lower depth = slower movement = appears further away
    double factor;
    switch (depth) {
      case 0:
        factor = 0.3;
        break;
      case 1:
        factor = 0.65;
        break;
      case 2:
      default:
        factor = 1.0;
        break;
    }

    return Transform.translate(
      offset: Offset(0, -scrollOffset * (1.0 - factor)),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 8. PAPER PAGE ROUTE — Smooth 220ms paper fade & micro-scale tab transition
// ═══════════════════════════════════════════════════════════════════════════

class PaperPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  PaperPageRoute({required this.builder, super.settings})
      : super(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 180),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeIn = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            final slideIn = Tween<Offset>(
              begin: const Offset(0.03, 0.0),
              end: Offset.zero,
            ).animate(fadeIn);

            return FadeTransition(
              opacity: fadeIn,
              child: SlideTransition(
                position: slideIn,
                child: child,
              ),
            );
          },
        );
}

