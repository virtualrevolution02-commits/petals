import 'dart:math';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../utils/paper_animations.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. TORN PAPER BORDER — Authentic jagged/deckled edges with fiber layers
// ═══════════════════════════════════════════════════════════════════════════

class TornPaperBorderPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double shadowDepth;

  TornPaperBorderPainter({
    required this.fillColor,
    required this.borderColor,
    this.shadowDepth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Layer 1: Shadow path offset
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.32)
      ..style = PaintingStyle.fill;

    final shadowPath = _generateTornPath(size, offset: Offset(3, shadowDepth + 2));
    canvas.drawPath(shadowPath, shadowPaint);

    // Layer 2: Rough White Torn Fiber Layer (Exposed Inner White Paper Stock)
    final whiteFiberPaint = Paint()
      ..color = const Color(0xFFFAF7F2)
      ..style = PaintingStyle.fill;

    final whiteFiberPath = _generateTornPath(size, offset: const Offset(-1.5, -1.5), scaleMultiplier: 1.02);
    canvas.drawPath(whiteFiberPath, whiteFiberPaint);

    // Layer 3: Main Craft Paper Surface Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final mainPath = _generateTornPath(size, offset: Offset.zero);
    canvas.drawPath(mainPath, fillPaint);

    // Layer 4: Handcut Border Stroke Outline
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(mainPath, borderPaint);
  }

  Path _generateTornPath(Size size, {required Offset offset, double scaleMultiplier = 1.0}) {
    final path = Path();
    final width = size.width * scaleMultiplier;
    final height = size.height * scaleMultiplier;
    final dx = offset.dx;
    final dy = offset.dy;

    path.moveTo(dx + 6, dy + 6);

    // Top torn edge
    const topSegments = 16;
    final topStep = width / topSegments;
    for (int i = 1; i <= topSegments; i++) {
      final x = dx + (i * topStep);
      final yJitter = (i % 2 == 0 ? 2.0 : -1.5);
      path.lineTo(x, dy + 6 + yJitter);
    }

    // Right torn edge
    const rightSegments = 14;
    final rightStep = height / rightSegments;
    for (int i = 1; i <= rightSegments; i++) {
      final y = dy + (i * rightStep);
      final xJitter = (i % 2 == 0 ? -2.0 : 1.5);
      path.lineTo(dx + width - 6 + xJitter, y);
    }

    // Bottom torn edge
    for (int i = topSegments - 1; i >= 0; i--) {
      final x = dx + (i * topStep);
      final yJitter = (i % 2 == 0 ? -2.5 : 1.8);
      path.lineTo(x, dy + height - 6 + yJitter);
    }

    // Left torn edge
    for (int i = rightSegments - 1; i >= 0; i--) {
      final y = dy + (i * rightStep);
      final xJitter = (i % 2 == 0 ? 2.0 : -1.5);
      path.lineTo(dx + 6 + xJitter, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant TornPaperBorderPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor || oldDelegate.borderColor != borderColor;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. PAPER MASKING TAPE — Semi-transparent tape with torn ends
// ═══════════════════════════════════════════════════════════════════════════

class PaperMaskingTape extends StatelessWidget {
  final String label;
  final double width;
  final double rotationAngle;

  const PaperMaskingTape({
    super.key,
    required this.label,
    this.width = 110,
    this.rotationAngle = -0.04,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationAngle,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: PaperColors.tapeYellow,
          borderRadius: BorderRadius.circular(1),
          boxShadow: PaperDepth.layerShadow(2),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.caveat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PaperColors.inkDark,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. PAPER PUSH PIN — 3D pin accent with layered shadow
// ═══════════════════════════════════════════════════════════════════════════

class PaperPushPin extends StatelessWidget {
  final Color color;
  const PaperPushPin({super.key, this.color = PaperColors.pinRed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: PaperDepth.layerShadow(3),
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. PAPER CARD — Dimensional stop-motion card with stacked paper layers
// ═══════════════════════════════════════════════════════════════════════════

class PaperCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double rotationAngle;
  final Color backgroundColor;
  final Color borderColor;
  final bool showTapeHeader;
  final String? tapeText;
  final bool showPin;
  final VoidCallback? onTap;
  final int elevation; // 1=flat, 2=raised, 3=floating

  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    this.rotationAngle = 0.0,
    this.backgroundColor = PaperColors.darkCard,
    this.borderColor = const Color(0xFF403C38),
    this.showTapeHeader = false,
    this.tapeText,
    this.showPin = false,
    this.onTap,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = (backgroundColor == PaperColors.darkCard)
        ? (isDark ? PaperColors.darkCard : const Color(0xFFFAF6EE))
        : backgroundColor;
    final effectiveBorder = (borderColor == const Color(0xFF403C38))
        ? (isDark ? const Color(0xFF403C38) : const Color(0xFFE2D8C6))
        : borderColor;

    final edgeThick = PaperDepth.edgeThickness(elevation);
    final edgeCol = PaperTextures.cutEdge(effectiveBg);

    return RepaintBoundary(
      child: StopMotionWrapper(
        child: Container(
          margin: margin,
          child: Transform.rotate(
            angle: rotationAngle,
            child: GestureDetector(
              onTap: () {
                if (onTap != null) {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Stacked paper backing layers (visible as edges)
                  if (elevation >= 2)
                    Positioned(
                      left: 2,
                      top: 3,
                      right: -2,
                      bottom: -3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: edgeCol.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  if (elevation >= 3)
                    Positioned(
                      left: 4,
                      top: 5,
                      right: -4,
                      bottom: -5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: edgeCol.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  // Main card face with smooth rounded paper cutout & depth shadow
                  Container(
                    padding: padding,
                    decoration: BoxDecoration(
                      color: effectiveBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: effectiveBorder, width: 1.5),
                      boxShadow: PaperDepth.layerShadow(elevation),
                    ),
                    child: child,
                  ),
                  if (showTapeHeader)
                    Positioned(
                      top: -8,
                      left: 20,
                      child: PaperMaskingTape(
                        label: tapeText ?? 'PETALS',
                      ),
                    ),
                  if (showPin)
                    const Positioned(
                      top: -6,
                      right: 18,
                      child: PaperPushPin(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. PAPER BUTTON — Dimensional cut-out button with paper thickness
// ═══════════════════════════════════════════════════════════════════════════

class PaperButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool isLoading;

  const PaperButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = PaperColors.roseCutout,
    this.textColor = Colors.white,
    this.isLoading = false,
  });

  @override
  State<PaperButton> createState() => _PaperButtonState();
}

class _PaperButtonState extends State<PaperButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed!();
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final edgeCol = PaperTextures.cutEdge(widget.color);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _isPressed ? 3 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
          boxShadow: _isPressed ? [] : PaperDepth.layerShadow(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else ...[
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. PAPER TEXT FIELD — Recessed cut-out input with dimensional edges
// ═══════════════════════════════════════════════════════════════════════════

class PaperTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const PaperTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? PaperColors.darkInkSecondary : PaperColors.inkDark;
    final fieldBg = isDark ? PaperColors.darkCardElevated : const Color(0xFFF3ECE0);
    final borderColor = isDark ? const Color(0xFF423E3A) : const Color(0xFFD6CABA);
    final textColor = isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark;
    final hintColor = isDark
        ? PaperColors.darkInkSecondary.withOpacity(0.6)
        : PaperColors.inkMedium.withOpacity(0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: GoogleFonts.caveat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              // Inset-like shadow (recessed cut-out illusion)
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.25)
                    : const Color(0x1A352E28),
                offset: const Offset(1, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                color: hintColor,
                fontSize: 14,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: PaperColors.roseCutout, size: 18)
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 6B. PAPER DIALOG — Scrapbook style cut-out modal dialog
// ═══════════════════════════════════════════════════════════════════════════

class PaperDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final bool showTape;
  final bool showPin;
  final Color? backgroundColor;

  const PaperDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.showTape = true,
    this.showPin = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = backgroundColor ??
        (isDark ? PaperColors.darkCard : const Color(0xFFFCFAF7));
    final effectiveBorder =
        isDark ? const Color(0xFF403C38) : const Color(0xFFE2D8C6);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: effectiveBorder, width: 1.5),
              boxShadow: PaperDepth.layerShadow(3),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTape || showPin) const SizedBox(height: 8),
                if (title != null) ...[
                  DefaultTextStyle(
                    style: GoogleFonts.caveat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                    ),
                    child: title!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (content != null) ...[
                  DefaultTextStyle(
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: isDark
                          ? PaperColors.darkInkSecondary
                          : PaperColors.inkMedium,
                    ),
                    child: content!,
                  ),
                  const SizedBox(height: 20),
                ],
                if (actions != null && actions!.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
              ],
            ),
          ),
          if (showTape)
            Positioned(
              top: -10,
              child: Container(
                width: 70,
                height: 20,
                decoration: BoxDecoration(
                  color: PaperColors.tapeYellow,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          if (showPin)
            const Positioned(
              top: -14,
              child: PaperPushPin(),
            ),
        ],
      ),
    );
  }
}

Future<T?> showPaperDialog<T>({
  required BuildContext context,
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  bool showTape = true,
  bool showPin = false,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => PaperDialog(
      title: title,
      content: content,
      actions: actions,
      showTape: showTape,
      showPin: showPin,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. PAPER CHIP — Dimensional stitched paper tag
// ═══════════════════════════════════════════════════════════════════════════

class PaperChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const PaperChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = PaperColors.darkCardElevated,
    this.textColor = PaperColors.darkInkPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: PaperDepth.layerShadow(1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.caveat(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 8. PAPER POLAROID — Dimensional photo mount with layered construction
// ═══════════════════════════════════════════════════════════════════════════

class PaperPolaroid extends StatelessWidget {
  final Widget child;
  final String? caption;
  final String? dateText;
  final double rotationAngle;
  final VoidCallback? onTap;
  final double imageHeight;

  const PaperPolaroid({
    super.key,
    required this.child,
    this.caption,
    this.dateText,
    this.rotationAngle = -0.005,
    this.onTap,
    this.imageHeight = 210.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF262321) : const Color(0xFFFAF6EE);

    return RepaintBoundary(
      child: Transform.rotate(
        angle: rotationAngle,
        child: GestureDetector(
          onTap: () {
            if (onTap != null) {
              HapticFeedback.lightImpact();
              onTap!();
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bottom Backing Paper Sheet 1 (Kraft Paper Sheet, rotated right)
              Positioned(
                left: 4,
                top: 8,
                right: 4,
                bottom: 2,
                child: Transform.rotate(
                  angle: 0.02,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F1C1A) : const Color(0xFFE2D5C1),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 6)),
                      ],
                    ),
                  ),
                ),
              ),

              // Middle Paper Sheet 2 (Ivory Paper Sheet, rotated left)
              Positioned(
                left: 2,
                top: 4,
                right: 6,
                bottom: 4,
                child: Transform.rotate(
                  angle: -0.012,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF221F1D) : const Color(0xFFEFE6D5),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(1, 4)),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Main Flecked Cream Paper Sheet
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    const BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(2, 5)),
                    if (!isDark)
                      const BoxShadow(color: Colors.white60, blurRadius: 1, offset: Offset(-1, -1)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main Photo/Placeholder Frame Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: double.infinity,
                        height: imageHeight,
                        color: isDark ? const Color(0xFF1A1817) : const Color(0xFFF3EDDF),
                        child: child,
                      ),
                    ),
                    if (caption != null || dateText != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (caption != null)
                            Expanded(
                              child: Text(
                                caption!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.caveat(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? PaperColors.darkInkPrimary : const Color(0xFF3E3427),
                                ),
                              ),
                            ),
                          if (dateText != null)
                            Text(
                              dateText!,
                              style: GoogleFonts.patrickHand(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? PaperColors.darkInkSecondary : const Color(0xFF7A6C5B),
                                letterSpacing: 0.5,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Pinned Top-Left "MEMO" Kraft Tag Badge
              Positioned(
                top: -6,
                left: 20,
                child: Transform.rotate(
                  angle: -0.04,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEADBCA),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1.5, 2.5)),
                      ],
                    ),
                    child: Text(
                      'MEMO',
                      style: GoogleFonts.caveat(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A3E2A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 8B. PAPER PHOTO TILE — Mini paper polaroid mount for grid view
// ═══════════════════════════════════════════════════════════════════════════

class PaperPhotoTile extends StatelessWidget {
  final Widget child;
  final double rotationAngle;
  final VoidCallback? onTap;
  final bool showTape;

  const PaperPhotoTile({
    super.key,
    required this.child,
    this.rotationAngle = 0.0,
    this.onTap,
    this.showTape = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PaperColors.darkCard : const Color(0xFFFCFAF7);
    final cardBorder = isDark ? const Color(0xFF403C38) : const Color(0xFFE2D8C6);

    return StopMotionWrapper(
      child: Transform.rotate(
        angle: rotationAngle,
        child: GestureDetector(
          onTap: () {
            if (onTap != null) {
              HapticFeedback.lightImpact();
              onTap!();
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardBorder, width: 1.2),
                  boxShadow: isDark
                      ? const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ]
                      : PaperDepth.layerShadow(1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: child,
                  ),
                ),
              ),
              if (showTape)
                Positioned(
                  top: -5,
                  left: 10,
                  child: Transform.rotate(
                    angle: -0.05,
                    child: Container(
                      width: 24,
                      height: 10,
                      decoration: BoxDecoration(
                        color: PaperColors.tapeYellow,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 9. PAPER LOADING PLACEHOLDER — Craft paper shimmer with grain
// ═══════════════════════════════════════════════════════════════════════════

class PaperLoadingPlaceholder extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const PaperLoadingPlaceholder({
    super.key,
    this.height = 180,
    this.width = double.infinity,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: PaperColors.darkCard,
      highlightColor: PaperColors.darkCardElevated,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: PaperColors.darkCard,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white10),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 10. PAPER EMPTY STATE — Scrapbook empty page with layered construction
// ═══════════════════════════════════════════════════════════════════════════

class PaperEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const PaperEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.collections_bookmark_rounded,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: PaperCard(
          rotationAngle: 0.015,
          showTapeHeader: true,
          tapeText: 'SCRAPBOOK PAGE',
          showPin: true,
          elevation: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: PaperColors.roseCutout.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: PaperColors.roseCutout, width: 1.5),
                  boxShadow: PaperDepth.layerShadow(1),
                ),
                child: Icon(icon, size: 34, color: PaperColors.roseCutout),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.caveat(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: PaperColors.darkInkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: PaperColors.darkInkSecondary,
                ),
              ),
              if (onActionPressed != null && actionLabel != null) ...[
                const SizedBox(height: 18),
                PaperButton(
                  label: actionLabel!,
                  icon: Icons.add_photo_alternate_rounded,
                  onPressed: onActionPressed,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 11. PAPER CUTOUT DECORATION — Dimensional decorative paper shapes
//     Renders leaves, clouds, petals, hearts as layered cut-out pieces
// ═══════════════════════════════════════════════════════════════════════════

enum CutoutShape { leaf, cloud, petal, heart, wave }

class PaperCutoutDecoration extends StatelessWidget {
  final CutoutShape shape;
  final Color color;
  final double size;
  final double rotation;
  final int depth; // 0, 1, or 2

  const PaperCutoutDecoration({
    super.key,
    required this.shape,
    this.color = PaperColors.sageCutout,
    this.size = 40,
    this.rotation = 0,
    this.depth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CutoutShapePainter(
            shape: shape,
            faceColor: color,
            edgeColor: PaperTextures.cutEdge(color),
            depth: depth,
          ),
        ),
      ),
    );
  }
}

class _CutoutShapePainter extends CustomPainter {
  final CutoutShape shape;
  final Color faceColor;
  final Color edgeColor;
  final int depth;

  _CutoutShapePainter({
    required this.shape,
    required this.faceColor,
    required this.edgeColor,
    required this.depth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shapePath(size);

    // Shadow layer
    if (depth > 0) {
      final shadowOffset = Offset(depth * 1.2, depth * 2.0);
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.15 + depth * 0.05)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 1.5);
      canvas.save();
      canvas.translate(shadowOffset.dx, shadowOffset.dy);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }

    // Paper edge strip (slightly larger, lighter color)
    if (depth > 0) {
      final edgePaint = Paint()
        ..color = edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = PaperDepth.edgeThickness(depth) + 1;
      canvas.drawPath(path, edgePaint);
    }

    // Face color fill
    final facePaint = Paint()
      ..color = faceColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, facePaint);

    // Subtle highlight on top-left edge (light source simulation)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, highlightPaint);
  }

  Path _shapePath(Size s) {
    switch (shape) {
      case CutoutShape.leaf:
        return _leafPath(s);
      case CutoutShape.cloud:
        return _cloudPath(s);
      case CutoutShape.petal:
        return _petalPath(s);
      case CutoutShape.heart:
        return _heartPath(s);
      case CutoutShape.wave:
        return _wavePath(s);
    }
  }

  Path _leafPath(Size s) {
    final path = Path();
    final w = s.width;
    final h = s.height;
    path.moveTo(w * 0.5, h * 0.05);
    path.quadraticBezierTo(w * 0.9, h * 0.2, w * 0.85, h * 0.55);
    path.quadraticBezierTo(w * 0.75, h * 0.85, w * 0.5, h * 0.95);
    path.quadraticBezierTo(w * 0.25, h * 0.85, w * 0.15, h * 0.55);
    path.quadraticBezierTo(w * 0.1, h * 0.2, w * 0.5, h * 0.05);
    path.close();
    return path;
  }

  Path _cloudPath(Size s) {
    final path = Path();
    final w = s.width;
    final h = s.height;
    path.moveTo(w * 0.25, h * 0.65);
    path.quadraticBezierTo(w * 0.05, h * 0.6, w * 0.1, h * 0.45);
    path.quadraticBezierTo(w * 0.1, h * 0.25, w * 0.3, h * 0.3);
    path.quadraticBezierTo(w * 0.35, h * 0.1, w * 0.55, h * 0.2);
    path.quadraticBezierTo(w * 0.7, h * 0.1, w * 0.8, h * 0.3);
    path.quadraticBezierTo(w * 0.95, h * 0.3, w * 0.9, h * 0.5);
    path.quadraticBezierTo(w * 0.95, h * 0.65, w * 0.75, h * 0.65);
    path.close();
    return path;
  }

  Path _petalPath(Size s) {
    final path = Path();
    final w = s.width;
    final h = s.height;
    path.moveTo(w * 0.5, h * 0.0);
    path.cubicTo(w * 0.8, h * 0.1, w * 1.0, h * 0.4, w * 0.5, h * 1.0);
    path.cubicTo(w * 0.0, h * 0.4, w * 0.2, h * 0.1, w * 0.5, h * 0.0);
    path.close();
    return path;
  }

  Path _heartPath(Size s) {
    final path = Path();
    final w = s.width;
    final h = s.height;
    path.moveTo(w * 0.5, h * 0.3);
    path.cubicTo(w * 0.5, h * 0.15, w * 0.3, h * 0.0, w * 0.15, h * 0.15);
    path.cubicTo(w * 0.0, h * 0.3, w * 0.05, h * 0.55, w * 0.5, h * 0.9);
    path.cubicTo(w * 0.95, h * 0.55, w * 1.0, h * 0.3, w * 0.85, h * 0.15);
    path.cubicTo(w * 0.7, h * 0.0, w * 0.5, h * 0.15, w * 0.5, h * 0.3);
    path.close();
    return path;
  }

  Path _wavePath(Size s) {
    final path = Path();
    final w = s.width;
    final h = s.height;
    path.moveTo(0, h * 0.5);
    path.quadraticBezierTo(w * 0.25, h * 0.2, w * 0.5, h * 0.5);
    path.quadraticBezierTo(w * 0.75, h * 0.8, w, h * 0.5);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CutoutShapePainter old) {
    return old.shape != shape || old.faceColor != faceColor || old.depth != depth;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 12. PAPER DIORAMA BACKGROUND — 3-plane parallax layered background
// ═══════════════════════════════════════════════════════════════════════════

class PaperDioramaBackground extends StatelessWidget {
  final Widget child;
  final ScrollController? scrollController;
  final bool isDark;
  final bool showLandscape;

  const PaperDioramaBackground({
    super.key,
    required this.child,
    this.scrollController,
    this.isDark = true,
    this.showLandscape = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF161925) : const Color(0xFFECE4D6);
    final skyColor = isDark ? const Color(0xFF1C2237) : const Color(0xFFF7F2E8);

    return Stack(
      children: [
        // Back plane: Gradient sky
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [skyColor, bgColor],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
        ),

        // Day vs Night Sky Features (Sun vs Crescent Moon & Stars)
        if (!isDark) ...[
          // Day Theme 3D Sun
          Positioned(
            top: 25,
            right: 35,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF2C94C),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF2C94C).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // Night Theme 3D Crescent Moon
          Positioned(
            top: 25,
            right: 35,
            child: Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF7DC),
                    boxShadow: [
                      BoxShadow(color: Color(0x77FFF7DC), blurRadius: 12, spreadRadius: 3),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 6,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: skyColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Mid plane: Decorative cut-out shapes
        Positioned(
          top: 60,
          right: -10,
          child: PaperCutoutDecoration(
            shape: CutoutShape.cloud,
            color: (isDark ? Colors.white : const Color(0xFFC4B8A5)).withOpacity(0.12),
            size: 80,
            depth: 0,
          ),
        ),
        Positioned(
          top: 120,
          left: -5,
          child: PaperCutoutDecoration(
            shape: CutoutShape.leaf,
            color: PaperColors.sageCutout.withOpacity(0.15),
            size: 35,
            rotation: -0.4,
            depth: 0,
          ),
        ),
        Positioned(
          top: 200,
          right: 20,
          child: PaperCutoutDecoration(
            shape: CutoutShape.petal,
            color: PaperColors.roseCutout.withOpacity(0.12),
            size: 25,
            rotation: 0.6,
            depth: 0,
          ),
        ),

        // Bottom Animated Sage Paper Hill Landscape (Mountains, Pines, Deer, Bunny, Birds)
        if (showLandscape)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 210,
              child: AnimatedSagePaperLandscape(),
            ),
          ),

        // Foreground: Content
        Positioned.fill(child: child),
      ],
    );
  }
}

// ── ANIMATED SAGE PAPER LANDSCAPE WIDGET ──
class AnimatedSagePaperLandscape extends StatefulWidget {
  const AnimatedSagePaperLandscape({super.key});

  @override
  State<AnimatedSagePaperLandscape> createState() => _AnimatedSagePaperLandscapeState();
}

class _AnimatedSagePaperLandscapeState extends State<AnimatedSagePaperLandscape>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _lastPaintedValue = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      // Slowed from 10s to 30s — gentler, less computation
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          // Throttle to ~8fps: only repaint when progress changes by ≥ 0.004
          final snapped = (_animController.value * 250).roundToDouble() / 250;
          if ((snapped - _lastPaintedValue).abs() < 0.003) {
            return CustomPaint(
              painter: SagePaperHillPainter(progress: _lastPaintedValue),
            );
          }
          _lastPaintedValue = snapped;
          return CustomPaint(
            painter: SagePaperHillPainter(progress: snapped),
          );
        },
      ),
    );
  }
}

// ── SAGE GREEN MULTI-LAYERED ANIMATED PAPER MOUNTAIN, FOREST & ANIMAL DIORAMA PAINTER ──
class SagePaperHillPainter extends CustomPainter {
  final double progress;
  SagePaperHillPainter({this.progress = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final birdShiftX = math.sin(progress * 2 * math.pi) * 35.0;
    final birdFlapY = math.cos(progress * 4 * math.pi) * 4.5;
    final swayAngle = math.sin(progress * 2 * math.pi * 1.5);
    final deerNod = math.sin(progress * 2 * math.pi * 2) * 1.8;
    final bunnyHop = (math.sin(progress * 2 * math.pi * 3.5).abs()) * 2.2;

    // ── Layer 1: Distant Paper Cut Mountain Peaks ──
    final mtnPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.40)
      ..lineTo(w * 0.18, h * 0.12)
      ..lineTo(w * 0.35, h * 0.38)
      ..lineTo(w * 0.52, h * 0.08)
      ..lineTo(w * 0.70, h * 0.42)
      ..lineTo(w * 0.86, h * 0.18)
      ..lineTo(w, h * 0.35)
      ..lineTo(w, h)
      ..close();

    canvas.drawShadow(mtnPath, Colors.black, 12.0, true);
    canvas.drawPath(mtnPath, Paint()..color = const Color(0xFF2E3542));

    // Mountain Snowcaps
    final snow1 = Path()
      ..moveTo(w * 0.18, h * 0.12)
      ..lineTo(w * 0.13, h * 0.20)
      ..lineTo(w * 0.18, h * 0.22)
      ..lineTo(w * 0.23, h * 0.20)
      ..close();
    canvas.drawPath(snow1, Paint()..color = const Color(0xFFE8DFC8));

    final snow2 = Path()
      ..moveTo(w * 0.52, h * 0.08)
      ..lineTo(w * 0.46, h * 0.17)
      ..lineTo(w * 0.52, h * 0.20)
      ..lineTo(w * 0.58, h * 0.18)
      ..close();
    canvas.drawPath(snow2, Paint()..color = const Color(0xFFFAF6EE));

    final snow3 = Path()
      ..moveTo(w * 0.86, h * 0.18)
      ..lineTo(w * 0.81, h * 0.25)
      ..lineTo(w * 0.86, h * 0.27)
      ..lineTo(w * 0.91, h * 0.24)
      ..close();
    canvas.drawPath(snow3, Paint()..color = const Color(0xFFE8DFC8));

    // Animated Flying Birds
    _drawFlyingBird(canvas, Offset(w * 0.22 + birdShiftX, h * 0.15 + birdFlapY), 9);
    _drawFlyingBird(canvas, Offset(w * 0.40 - birdShiftX * 1.2, h * 0.10 - birdFlapY * 1.1), 12);
    _drawFlyingBird(canvas, Offset(w * 0.70 + birdShiftX * 0.8, h * 0.14 + birdFlapY * 0.9), 8);

    // ── Layer 2: Mid-ground Deep Forest Green Paper Hill ──
    final forestHillPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.38)
      ..cubicTo(w * 0.25, h * 0.20, w * 0.55, h * 0.45, w, h * 0.28)
      ..lineTo(w, h)
      ..close();

    canvas.drawShadow(forestHillPath, Colors.black87, 8.0, true);
    canvas.drawPath(forestHillPath, Paint()..color = const Color(0xFF4A5C4C));

    // Swaying Pine Trees on Mid-ground Hill
    _drawPineTree(canvas, Offset(w * 0.12, h * 0.35), 24, 45, const Color(0xFF2C3E30), swayAngle * 0.02);
    _drawPineTree(canvas, Offset(w * 0.22, h * 0.30), 28, 52, const Color(0xFF3B5240), -swayAngle * 0.025);
    _drawPineTree(canvas, Offset(w * 0.32, h * 0.36), 20, 38, const Color(0xFF2C3E30), swayAngle * 0.015);
    _drawPineTree(canvas, Offset(w * 0.78, h * 0.35), 26, 48, const Color(0xFF3B5240), swayAngle * 0.022);
    _drawPineTree(canvas, Offset(w * 0.88, h * 0.32), 22, 42, const Color(0xFF2C3E30), -swayAngle * 0.018);

    // ── Layer 3: Foreground Sage Green Paper Hill ──
    final hillPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.52)
      ..cubicTo(
        w * 0.20, h * 0.35,
        w * 0.48, h * 0.38,
        w * 0.78, h * 0.65,
      )
      ..lineTo(w, h * 0.72)
      ..lineTo(w, h)
      ..close();

    canvas.drawShadow(hillPath, Colors.black87, 6.0, true);
    canvas.drawPath(
      hillPath,
      Paint()..color = const Color(0xFF8BA083),
    );

    // Foreground Swaying Pine Trees
    _drawPineTree(canvas, Offset(w * 0.45, h * 0.44), 30, 56, const Color(0xFF537059), swayAngle * 0.028);
    _drawPineTree(canvas, Offset(w * 0.55, h * 0.50), 24, 44, const Color(0xFF3B5240), -swayAngle * 0.02);

    // Animated Paper Cut Deer (Gentle Breathing & Head Movement)
    _drawDeer(canvas, Offset(w * 0.76, h * 0.64 + deerNod * 0.5), 54, deerNod);

    // Animated Paper Cut Bunny (Hopping & Ear Wiggle)
    _drawBunny(canvas, Offset(w * 0.16, h * 0.78 - bunnyHop), 26, bunnyHop);

    // ── Layer 4: Sandy Tan Paper Wave Shore (Bottom Edge) ──
    final sandPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.78);
    for (double i = 0; i <= w; i += 6) {
      sandPath.lineTo(i, h * 0.78 + math.sin(i / 35 + progress * 2 * math.pi) * 3 + math.cos(i / 20) * 3);
    }
    sandPath.lineTo(w, h);
    sandPath.close();
    canvas.drawShadow(sandPath, Colors.black54, 4.0, true);
    canvas.drawPath(sandPath, Paint()..color = const Color(0xFFE5D7BF));
  }

  // ── Helper: Draw Tiered Paper Cut Pine Tree ──
  void _drawPineTree(Canvas canvas, Offset bottomCenter, double width, double height, Color color, double sway) {
    final x = bottomCenter.dx;
    final y = bottomCenter.dy;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(sway);
    canvas.translate(-x, -y);

    // Trunk
    final trunkPaint = Paint()..color = const Color(0xFF38291F);
    canvas.drawRect(
      Rect.fromLTWH(x - width * 0.1, y - height * 0.15, width * 0.2, height * 0.15),
      trunkPaint,
    );

    final treePath = Path();
    // Bottom Tier
    treePath.moveTo(x - width * 0.5, y - height * 0.15);
    treePath.lineTo(x, y - height * 0.52);
    treePath.lineTo(x + width * 0.5, y - height * 0.15);
    treePath.close();

    // Middle Tier
    treePath.moveTo(x - width * 0.4, y - height * 0.42);
    treePath.lineTo(x, y - height * 0.76);
    treePath.lineTo(x + width * 0.4, y - height * 0.42);
    treePath.close();

    // Top Tier
    treePath.moveTo(x - width * 0.3, y - height * 0.66);
    treePath.lineTo(x, y - height);
    treePath.lineTo(x + width * 0.3, y - height * 0.66);
    treePath.close();

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(treePath.shift(const Offset(1.5, 2.5)), shadowPaint);
    canvas.drawPath(treePath, Paint()..color = color);

    canvas.restore();
  }

  // ── Helper: Draw Paper Cut Deer Silhouette ──
  void _drawDeer(Canvas canvas, Offset basePos, double size, double nod) {
    final x = basePos.dx;
    final y = basePos.dy;
    final scale = size / 60.0;

    final deerPath = Path();
    deerPath.moveTo(x - 8 * scale, y);
    deerPath.lineTo(x - 7 * scale, y - 18 * scale);
    deerPath.cubicTo(
      x - 12 * scale, y - 28 * scale,
      x + 6 * scale, y - 32 * scale,
      x + 12 * scale, y - 26 * scale,
    );
    deerPath.cubicTo(
      x + 16 * scale, y - 36 * scale + nod,
      x + 14 * scale, y - 48 * scale + nod,
      x + 20 * scale, y - 50 * scale + nod,
    );
    deerPath.lineTo(x + 25 * scale, y - 46 * scale + nod);
    deerPath.cubicTo(
      x + 20 * scale, y - 42 * scale,
      x + 16 * scale, y - 32 * scale,
      x + 10 * scale, y - 24 * scale,
    );
    deerPath.lineTo(x + 10 * scale, y);
    deerPath.lineTo(x + 6 * scale, y);
    deerPath.lineTo(x + 6 * scale, y - 18 * scale);
    deerPath.lineTo(x - 2 * scale, y - 18 * scale);
    deerPath.lineTo(x - 2 * scale, y);
    deerPath.close();

    // Antlers
    final antlerPath = Path();
    antlerPath.moveTo(x + 17 * scale, y - 49 * scale + nod);
    antlerPath.lineTo(x + 22 * scale, y - 62 * scale + nod);
    antlerPath.lineTo(x + 26 * scale, y - 66 * scale + nod);
    antlerPath.moveTo(x + 20 * scale, y - 56 * scale + nod);
    antlerPath.lineTo(x + 25 * scale, y - 58 * scale + nod);
    antlerPath.moveTo(x + 17 * scale, y - 49 * scale + nod);
    antlerPath.lineTo(x + 13 * scale, y - 60 * scale + nod);

    final shadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final deerPaint = Paint()..color = const Color(0xFF38261C);
    final antlerPaint = Paint()
      ..color = const Color(0xFF38261C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(deerPath.shift(const Offset(1.5, 2)), shadowPaint);
    canvas.drawPath(deerPath, deerPaint);
    canvas.drawPath(antlerPath.shift(const Offset(1.5, 2)), shadowPaint);
    canvas.drawPath(antlerPath, antlerPaint);
  }

  // ── Helper: Draw Paper Cut Bunny Silhouette ──
  void _drawBunny(Canvas canvas, Offset basePos, double size, double hop) {
    final x = basePos.dx;
    final y = basePos.dy;
    final scale = size / 30.0;

    final bunnyPath = Path();
    bunnyPath.addOval(Rect.fromLTWH(x - 12 * scale, y - 16 * scale, 20 * scale, 16 * scale));
    bunnyPath.addOval(Rect.fromLTWH(x + 2 * scale, y - 24 * scale, 12 * scale, 12 * scale));
    bunnyPath.addOval(Rect.fromLTWH(x + 3 * scale + hop * 0.5, y - 36 * scale, 4 * scale, 14 * scale));
    bunnyPath.addOval(Rect.fromLTWH(x + 8 * scale - hop * 0.5, y - 35 * scale, 4 * scale, 13 * scale));
    bunnyPath.addOval(Rect.fromLTWH(x - 15 * scale, y - 10 * scale, 6 * scale, 6 * scale));

    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(bunnyPath.shift(const Offset(1, 1.5)), shadowPaint);
    canvas.drawPath(bunnyPath, Paint()..color = const Color(0xFFFAF6EE));
  }

  // ── Helper: Draw Flying Paper Cut Bird ──
  void _drawFlyingBird(Canvas canvas, Offset pos, double size) {
    final x = pos.dx;
    final y = pos.dy;
    final path = Path();
    path.moveTo(x - size, y);
    path.quadraticBezierTo(x - size * 0.5, y - size * 0.8, x, y);
    path.quadraticBezierTo(x + size * 0.5, y - size * 0.8, x + size, y);
    path.quadraticBezierTo(x + size * 0.5, y - size * 0.3, x, y - size * 0.1);
    path.quadraticBezierTo(x - size * 0.5, y - size * 0.3, x - size, y);

    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final birdPaint = Paint()..color = const Color(0xFF383D4A);

    canvas.drawPath(path.shift(const Offset(1, 1)), shadowPaint);
    canvas.drawPath(path, birdPaint);
  }

  @override
  bool shouldRepaint(covariant SagePaperHillPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── TORN PAPER INPUT FIELD PAINTER (Ref Image Match) ──
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
    darkPath.close();

    canvas.drawPath(darkPath, Paint()..color = const Color(0xFF272A32));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DioramaHillPainter extends CustomPainter {
  final Color color;
  _DioramaHillPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.3, size.height * 0.2,
        size.width * 0.55, size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.8, size.height * 0.8,
        size.width, size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DioramaHillPainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════
// 13. PAPER DIORAMA LAYER — Individual depth-plane container
// ═══════════════════════════════════════════════════════════════════════════

class PaperDioramaLayer extends StatelessWidget {
  final Widget child;
  final int depth; // 0 = back, 1 = mid, 2 = foreground
  final EdgeInsetsGeometry? padding;

  const PaperDioramaLayer({
    super.key,
    required this.child,
    this.depth = 1,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          boxShadow: PaperDepth.layerShadow(depth),
        ),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 14. HANDCRAFTED PAPER CRAFT DECORATIVE ELEMENTS
// ═══════════════════════════════════════════════════════════════════════════

class PaperOrigamiBird extends StatelessWidget {
  final double size;
  const PaperOrigamiBird({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PaperOrigamiBirdPainter(),
      ),
    );
  }
}

class PaperOrigamiBirdPainter extends CustomPainter {
  final Color paperColor;
  final Color shadowColor;

  PaperOrigamiBirdPainter({
    this.paperColor = const Color(0xFFF5F2EA),
    this.shadowColor = const Color(0x33000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop shadow
    final shadowPath = Path()
      ..moveTo(w * 0.2, h * 0.4)
      ..lineTo(w * 0.9, h * 0.1)
      ..lineTo(w * 0.7, h * 0.9)
      ..lineTo(w * 0.1, h * 0.7)
      ..close();
    canvas.drawPath(
      shadowPath.shift(const Offset(4, 6)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Origami Facets
    final paintBase = Paint()..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFD0CBBF)
      ..strokeWidth = 0.8;

    // Left Wing
    final leftWing = Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.05, h * 0.1)
      ..lineTo(w * 0.35, h * 0.55)
      ..close();
    canvas.drawPath(leftWing, paintBase..color = paperColor);
    canvas.drawPath(leftWing, paintStroke);

    // Right Wing (Upper, raised facet)
    final rightWing = Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.75, h * 0.02)
      ..lineTo(w * 0.65, h * 0.48)
      ..close();
    canvas.drawPath(rightWing, paintBase..color = const Color(0xFFFFFFFF));
    canvas.drawPath(rightWing, paintStroke);

    // Main Body Triangle
    final body = Path()
      ..moveTo(w * 0.35, h * 0.55)
      ..lineTo(w * 0.5, h * 0.45)
      ..lineTo(w * 0.65, h * 0.48)
      ..lineTo(w * 0.45, h * 0.8)
      ..close();
    canvas.drawPath(body, paintBase..color = const Color(0xFFECE7DA));
    canvas.drawPath(body, paintStroke);

    // Head / Beak fold
    final head = Path()
      ..moveTo(w * 0.35, h * 0.55)
      ..lineTo(w * 0.2, h * 0.65)
      ..lineTo(w * 0.15, h * 0.62)
      ..lineTo(w * 0.3, h * 0.52)
      ..close();
    canvas.drawPath(head, paintBase..color = const Color(0xFFE2DDD0));
    canvas.drawPath(head, paintStroke);

    // Tail fold
    final tail = Path()
      ..moveTo(w * 0.65, h * 0.48)
      ..lineTo(w * 0.9, h * 0.42)
      ..lineTo(w * 0.7, h * 0.6)
      ..close();
    canvas.drawPath(tail, paintBase..color = const Color(0xFFE7E2D5));
    canvas.drawPath(tail, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaperFoldedHeart extends StatelessWidget {
  final double size;
  final Color color;
  final double rotation;

  const PaperFoldedHeart({
    super.key,
    this.size = 24,
    this.color = const Color(0xFFE57373),
    this.rotation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FoldedHeartPainter(color: color),
        ),
      ),
    );
  }
}

class _FoldedHeartPainter extends CustomPainter {
  final Color color;
  _FoldedHeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Drop Shadow for 3D pop
    final shadowPath = Path()
      ..moveTo(w * 0.5, h * 0.25)
      ..cubicTo(w * 0.5, h * 0.1, w * 0.25, 0, w * 0.05, h * 0.2)
      ..cubicTo(0, h * 0.45, w * 0.3, h * 0.75, w * 0.5, h * 0.95)
      ..cubicTo(w * 0.7, h * 0.75, w, h * 0.45, w * 0.95, h * 0.2)
      ..cubicTo(w * 0.75, 0, w * 0.5, h * 0.1, w * 0.5, h * 0.25)
      ..close();

    canvas.drawPath(
      shadowPath.shift(const Offset(2, 3)),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Left half (light face)
    final leftHalf = Path()
      ..moveTo(w * 0.5, h * 0.25)
      ..cubicTo(w * 0.5, h * 0.1, w * 0.25, 0, w * 0.05, h * 0.2)
      ..cubicTo(0, h * 0.45, w * 0.3, h * 0.75, w * 0.5, h * 0.95)
      ..close();
    canvas.drawPath(leftHalf, Paint()..color = color);

    // Right half (shaded face for 3D fold effect)
    final rightHalf = Path()
      ..moveTo(w * 0.5, h * 0.25)
      ..cubicTo(w * 0.5, h * 0.1, w * 0.75, 0, w * 0.95, h * 0.2)
      ..cubicTo(w, h * 0.45, w * 0.7, h * 0.75, w * 0.5, h * 0.95)
      ..close();
    final shadedColor = Color.alphaBlend(Colors.black.withOpacity(0.18), color);
    canvas.drawPath(rightHalf, Paint()..color = shadedColor);

    // Center fold crease line
    canvas.drawLine(
      Offset(w * 0.5, h * 0.25),
      Offset(w * 0.5, h * 0.95),
      Paint()
        ..color = Colors.black26
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FlowerLogo extends StatelessWidget {
  final double size;
  final bool showBadge;

  const FlowerLogo({
    super.key,
    this.size = 180,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: FlowerLogoPainter(showBadge: showBadge),
      ),
    );
  }
}

class FlowerLogoPainter extends CustomPainter {
  final Color lineColor;
  final Color backgroundColor;
  final bool showBadge;

  FlowerLogoPainter({
    this.lineColor = const Color(0xFF2D3139),
    this.backgroundColor = const Color(0xFFFAF7F2),
    this.showBadge = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // ── 1. Base Drop Shadow ──
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawCircle(center.translate(1, 3.5), w * 0.48, shadowPaint);

    // ── 2. Layer 1: Sage Green Outer Paper Disc ──
    final sagePaperPaint = Paint()
      ..color = const Color(0xFF839879) // Muted sage green paper disc
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.48, sagePaperPaint);

    // ── 3. Layer 2: Cream Paper Ring ──
    canvas.drawCircle(
      center.translate(0.8, 1.5),
      w * 0.41,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final creamPaperPaint = Paint()
      ..color = const Color(0xFFEFE6D5) // Cream ivory paper ring
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.41, creamPaperPaint);

    // ── 4. Layer 3: Coral Pink Inner Paper Disc ──
    canvas.drawCircle(
      center.translate(0.8, 1.5),
      w * 0.32,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final pinkPaperPaint = Paint()
      ..color = const Color(0xFFED8891) // Soft Coral Pink paper disc
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.32, pinkPaperPaint);

    // ── 5. Layer 4: 3D Paper Cut White Heart Symbol ──
    final heartPath = Path();
    final hw = w * 0.28;
    final hh = h * 0.26;
    final hx = center.dx;
    final hy = center.dy + h * 0.02;

    heartPath.moveTo(hx, hy + hh * 0.45);
    heartPath.cubicTo(
      hx - hw * 0.55, hy + hh * 0.1,
      hx - hw * 0.65, hy - hh * 0.35,
      hx - hw * 0.25, hy - hh * 0.45,
    );
    heartPath.cubicTo(
      hx - hw * 0.05, hy - hh * 0.5,
      hx, hy - hh * 0.25,
      hx, hy - hh * 0.25,
    );
    heartPath.cubicTo(
      hx, hy - hh * 0.25,
      hx + hw * 0.05, hy - hh * 0.5,
      hx + hw * 0.25, hy - hh * 0.45,
    );
    heartPath.cubicTo(
      hx + hw * 0.65, hy - hh * 0.35,
      hx + hw * 0.55, hy + hh * 0.1,
      hx, hy + hh * 0.45,
    );
    heartPath.close();

    // Heart Shadow
    final heartShadowPaint = Paint()
      ..color = Colors.black38
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(heartPath.shift(const Offset(1.5, 2.5)), heartShadowPaint);

    // White Crisp Heart Fill
    final heartPaint = Paint()
      ..color = const Color(0xFFFAF6EE) // Crisp white paper heart
      ..style = PaintingStyle.fill;
    canvas.drawPath(heartPath, heartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

typedef PaperCutLogo = FlowerLogo;
typedef PaperFlowerLogo = FlowerLogo;

class _FlowerPetalsPainter extends CustomPainter {
  final Color color;
  final int petalCount;
  final double rotationOffset;

  _FlowerPetalsPainter({
    required this.color,
    this.petalCount = 4,
    this.rotationOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final angleStep = (2 * pi) / petalCount;
    for (int i = 0; i < petalCount; i++) {
      final angle = rotationOffset + (i * angleStep);
      final petalCenter = Offset(
        center.dx + (radius * 0.45 * cos(angle)),
        center.dy + (radius * 0.45 * sin(angle)),
      );

      final path = Path()
        ..addOval(Rect.fromCircle(center: petalCenter, radius: radius * 0.42));
      canvas.drawPath(path.shift(const Offset(1, 2)), shadowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaperCraftTag extends StatelessWidget {
  final String text;
  const PaperCraftTag({super.key, this.text = 'WELCOME'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE2D0), // Kraft paper color
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Punch hole
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF2C303A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5A4A3A),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 15. HIGH-FIDELITY HANDCRAFTED RECREATION WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class PaperCraftCloudGroup extends StatelessWidget {
  final double width;
  final double height;
  final bool isReversed;

  const PaperCraftCloudGroup({
    super.key,
    this.width = 110,
    this.height = 60,
    this.isReversed = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Back cloud layer (darker slate blue paper)
          Positioned(
            left: isReversed ? 15 : 0,
            top: 5,
            child: SizedBox(
              width: width * 0.8,
              height: height * 0.75,
              child: CustomPaint(
                painter: _PaperCloudPainter(
                  fillColor: const Color(0xFF545F70),
                  shadowColor: Colors.black45,
                ),
              ),
            ),
          ),

          // Front cloud layer (light slate paper with white edge stroke)
          Positioned(
            left: isReversed ? 0 : 20,
            top: 0,
            child: SizedBox(
              width: width * 0.85,
              height: height * 0.8,
              child: CustomPaint(
                painter: _PaperCloudPainter(
                  fillColor: const Color(0xFF8B97A6),
                  edgeColor: const Color(0xFFC7D0DC),
                  shadowColor: Colors.black38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperCloudPainter extends CustomPainter {
  final Color fillColor;
  final Color? edgeColor;
  final Color shadowColor;

  _PaperCloudPainter({
    required this.fillColor,
    this.edgeColor,
    this.shadowColor = Colors.black26,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.2, h * 0.7);
    path.cubicTo(w * 0.02, h * 0.7, 0, h * 0.45, w * 0.18, h * 0.35);
    path.cubicTo(w * 0.15, h * 0.15, w * 0.35, 0, w * 0.55, h * 0.12);
    path.cubicTo(w * 0.7, h * 0.05, w * 0.88, h * 0.2, w * 0.88, h * 0.38);
    path.cubicTo(w * 1.02, h * 0.48, w * 0.98, h * 0.7, w * 0.82, h * 0.7);
    path.close();

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(3, 4)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Edge
    if (edgeColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = edgeColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Fill
    canvas.drawPath(path, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KraftLuggageTag extends StatelessWidget {
  final String text;
  final double rotation;

  const KraftLuggageTag({
    super.key,
    this.text = 'WELCOME',
    this.rotation = -0.10,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // String loop attached to hole
          Positioned(
            left: -16,
            top: 7,
            child: SizedBox(
              width: 22,
              height: 12,
              child: CustomPaint(
                painter: _TagStringPainter(),
              ),
            ),
          ),
          // Kraft paper body tag
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 14, 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDFCE9F), // Kraft paper color
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(3, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hole punch with metal grommet look
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C303A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB8A77B), width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A3E2A),
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagStringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEBE0C5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final path = Path();
    path.moveTo(size.width, size.height / 2);
    path.quadraticBezierTo(0, 0, 0, size.height / 2);
    path.quadraticBezierTo(0, size.height, size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TornPaperCardPainter extends CustomPainter {
  final Color fillColor;
  final Color kraftColor;

  TornPaperCardPainter({
    this.fillColor = const Color(0xFFEEE6D3), // card.cream
    this.kraftColor = const Color(0xFFC9A96A), // card.kraftEdge
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Cast shadow of the entire paper assembly onto backdrop
    final shadowPath = _generateTornPath(size, offset: const Offset(5, 9), scale: 1.02);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 2. Torn Kraft Paper Backing Sheet (visible as 6-10px border on right/bottom)
    final kraftPath = _generateTornPath(size, offset: const Offset(4, 5), scale: 1.015);
    canvas.drawPath(
      kraftPath,
      Paint()..color = kraftColor,
    );

    // 3. Exposed Torn White Fiber Stock Edge
    final fiberPath = _generateTornPath(size, offset: const Offset(-1, -1));
    canvas.drawPath(
      fiberPath,
      Paint()..color = const Color(0xFFFAF8F5),
    );

    // 4. Main Scrapbook Page (card.cream #EEE6D3)
    final mainPath = _generateTornPath(size, offset: Offset.zero);
    canvas.drawPath(
      mainPath,
      Paint()..color = fillColor,
    );

    // 5. Item 1: Bottom-Left Curved Paper Slits (Matching Circle 1)
    _drawPaperSlitsGroup(
      canvas,
      centerX: w * 0.14,
      centerY: h - 38,
      width: w * 0.12,
      count: 3,
    );
    // Torn edge slit at bottom left
    _drawPaperSlitsGroup(
      canvas,
      centerX: w * 0.14,
      centerY: h - 12,
      width: w * 0.10,
      count: 1,
    );

    // 6. Item 2: Bottom-Center Curved Paper Slits (Under "Sign In" Felt Button - Matching Circle 2)
    _drawPaperSlitsGroup(
      canvas,
      centerX: w * 0.50,
      centerY: h - 42,
      width: w * 0.28,
      count: 3,
    );

    // 7. Item 3: Bottom Scattered Olive Paper Leaves (Matching Circle 3)
    _drawOliveLeaf(canvas, Offset(w * 0.67, h - 35), size: 18, rotation: 0.6);
    _drawOliveLeaf(canvas, Offset(w * 0.72, h - 48), size: 16, rotation: -0.4);
    _drawOliveLeaf(canvas, Offset(w * 0.76, h - 16), size: 20, rotation: 0.8);

    // 8. Item 4: Bottom-Right Stitched Kraft Heart Button (Matching Circle 4)
    _drawBottomKraftHeart(canvas, Offset(w - 38, h - 32));

    // 9. Top-Right Ephemera: Kraft Paper Heart Button with White String Loop (Spec Image 1 & 2)
    final heartCenter = Offset(w - 38, 28);
    const sizeH = 26.0;

    // A. White Cotton String Tails (Behind heart, extending left across cream & right onto kraft)
    final stringPaint = Paint()
      ..color = const Color(0xFFFAF8F5) // White cotton thread
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Top-left string tail curving upward left
    final stringTailLeft = Path()
      ..moveTo(heartCenter.dx - 3, heartCenter.dy)
      ..cubicTo(
        heartCenter.dx - 14, heartCenter.dy - 12,
        heartCenter.dx - 24, heartCenter.dy - 4,
        heartCenter.dx - 32, heartCenter.dy - 18,
      );
    canvas.drawPath(stringTailLeft, stringPaint);

    // Bottom-right string tail curving down-right across cream edge onto kraft sheet
    final stringTailRight = Path()
      ..moveTo(heartCenter.dx + 3, heartCenter.dy)
      ..cubicTo(
        heartCenter.dx + 14, heartCenter.dy + 10,
        heartCenter.dx + 28, heartCenter.dy + 14,
        heartCenter.dx + 42, heartCenter.dy + 18,
      );
    canvas.drawPath(stringTailRight, stringPaint);

    // B. Heart Button Cast Shadow
    canvas.save();
    canvas.translate(heartCenter.dx + 2, heartCenter.dy + 3);
    canvas.rotate(-0.15);
    final heartShadowPath = Path();
    heartShadowPath.moveTo(0, sizeH * 0.35);
    heartShadowPath.cubicTo(
      -sizeH * 0.52, -sizeH * 0.3,
      -sizeH * 0.52, -sizeH * 0.72,
      0, -sizeH * 0.35,
    );
    heartShadowPath.cubicTo(
      sizeH * 0.52, -sizeH * 0.72,
      sizeH * 0.52, -sizeH * 0.3,
      0, sizeH * 0.35,
    );
    canvas.drawPath(
      heartShadowPath,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();

    // C. Kraft Heart Button Body
    canvas.save();
    canvas.translate(heartCenter.dx, heartCenter.dy);
    canvas.rotate(-0.15); // Slight tilt ~-8.5 degrees

    final heartPath = Path();
    heartPath.moveTo(0, sizeH * 0.35);
    heartPath.cubicTo(
      -sizeH * 0.52, -sizeH * 0.3,
      -sizeH * 0.52, -sizeH * 0.72,
      0, -sizeH * 0.35,
    );
    heartPath.cubicTo(
      sizeH * 0.52, -sizeH * 0.72,
      sizeH * 0.52, -sizeH * 0.3,
      0, sizeH * 0.35,
    );
    canvas.drawPath(heartPath, Paint()..color = const Color(0xFFC5A67C)); // Kraft paper tone

    // Outer edge outline for tactile depth
    canvas.drawPath(
      heartPath,
      Paint()
        ..color = const Color(0xFFA6875C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2 Button Holes (dark recessed cutouts)
    final holePaint = Paint()..color = const Color(0xFF4A3824);
    canvas.drawCircle(const Offset(-4, -1), 1.8, holePaint);
    canvas.drawCircle(const Offset(4, -1), 1.8, holePaint);

    // Stitch thread loop between the 2 holes
    canvas.drawLine(
      const Offset(-4, -1),
      const Offset(4, -1),
      Paint()
        ..color = const Color(0xFFFAF8F5)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  void _drawPaperSlitsGroup(
    Canvas canvas, {
    required double centerX,
    required double centerY,
    required double width,
    required int count,
  }) {
    for (int i = 0; i < count; i++) {
      final yOffset = centerY - (i * 8.5);
      final wScale = width * (1.0 - i * 0.18);

      final shadowPath = Path()
        ..moveTo(centerX - wScale / 2, yOffset)
        ..quadraticBezierTo(centerX, yOffset - (11.0 - i * 2.0), centerX + wScale / 2, yOffset);

      // Recessed dark shadow slot inside paper cut
      canvas.drawPath(
        shadowPath.shift(const Offset(0, 1.2)),
        Paint()
          ..color = const Color(0xFF4A3E31).withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );

      // Raised paper cut lip
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = const Color(0xFFFAF6EE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawOliveLeaf(Canvas canvas, Offset center, {required double size, required double rotation}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final leafPath = Path()
      ..moveTo(0, -size / 2)
      ..quadraticBezierTo(size * 0.5, 0, 0, size / 2)
      ..quadraticBezierTo(-size * 0.5, 0, 0, -size / 2);

    canvas.drawPath(
      leafPath.shift(const Offset(1.5, 2.5)),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    canvas.drawPath(leafPath, Paint()..color = const Color(0xFF8B965C)); // leaf.olive

    canvas.drawLine(
      Offset(0, -size * 0.45),
      Offset(0, size * 0.45),
      Paint()
        ..color = const Color(0xFF6B7544)
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }

  void _drawBottomKraftHeart(Canvas canvas, Offset center) {
    const sizeH = 24.0;

    // Pink / White thread extending left & right
    final threadPaint = Paint()
      ..color = const Color(0xFFE8967D) // Pink thread
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final threadLeft = Path()
      ..moveTo(center.dx - 2, center.dy)
      ..cubicTo(center.dx - 12, center.dy - 6, center.dx - 20, center.dy + 4, center.dx - 28, center.dy - 5);
    canvas.drawPath(threadLeft, threadPaint);

    final threadRight = Path()
      ..moveTo(center.dx + 2, center.dy)
      ..cubicTo(center.dx + 10, center.dy + 6, center.dx + 18, center.dy - 4, center.dx + 25, center.dy + 3);
    canvas.drawPath(threadRight, threadPaint);

    // Heart Shadow
    canvas.save();
    canvas.translate(center.dx + 2, center.dy + 3);
    canvas.rotate(0.12);
    final heartPath = Path();
    heartPath.moveTo(0, sizeH * 0.35);
    heartPath.cubicTo(
      -sizeH * 0.50, -sizeH * 0.3,
      -sizeH * 0.50, -sizeH * 0.7,
      0, -sizeH * 0.35,
    );
    heartPath.cubicTo(
      sizeH * 0.50, -sizeH * 0.7,
      sizeH * 0.50, -sizeH * 0.3,
      0, sizeH * 0.35,
    );
    canvas.drawPath(
      heartPath,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();

    // Heart Body (Kraft paper #C5A67C)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.12);

    canvas.drawPath(heartPath, Paint()..color = const Color(0xFFC5A67C));
    canvas.drawPath(
      heartPath,
      Paint()
        ..color = const Color(0xFFA6875C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 2 Holes
    final holePaint = Paint()..color = const Color(0xFF3A332A);
    canvas.drawCircle(const Offset(-3.5, -1), 1.6, holePaint);
    canvas.drawCircle(const Offset(3.5, -1), 1.6, holePaint);

    // White stitch thread
    canvas.drawLine(
      const Offset(-3.5, -1),
      const Offset(3.5, -1),
      Paint()
        ..color = const Color(0xFFFAF8F5)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }



  Path _generateTornPath(Size size, {required Offset offset, double scale = 1.0}) {
    final path = Path();
    final w = size.width * scale;
    final h = size.height * scale;
    final dx = offset.dx;
    final dy = offset.dy;

    path.moveTo(dx + 14, dy);

    // Top hand-torn edge (irregular zig-zag)
    const topSegs = 14;
    final tStep = (w - 28) / topSegs;
    for (int i = 1; i <= topSegs; i++) {
      final x = dx + 14 + (i * tStep);
      final jitter = (i % 2 == 0 ? 2.5 : -2.0);
      path.lineTo(x, dy + jitter);
    }
    path.quadraticBezierTo(dx + w, dy, dx + w, dy + 14);

    // Right torn edge
    const rightSegs = 10;
    final rStep = (h - 28) / rightSegs;
    for (int i = 1; i <= rightSegs; i++) {
      final y = dy + 14 + (i * rStep);
      final jitter = (i % 2 == 0 ? 2.2 : -1.8);
      path.lineTo(dx + w + jitter, y);
    }
    path.quadraticBezierTo(dx + w, dy + h, dx + w - 14, dy + h);

    // Bottom hand-torn edge (irregular zig-zag)
    const botSegs = 14;
    final bStep = (w - 28) / botSegs;
    for (int i = botSegs - 1; i >= 0; i--) {
      final x = dx + 14 + (i * bStep);
      final jitter = (i % 2 == 0 ? -2.5 : 2.0);
      path.lineTo(x, dy + h + jitter);
    }
    path.quadraticBezierTo(dx, dy + h, dx, dy + h - 14);

    // Left torn edge
    for (int i = rightSegs - 1; i >= 0; i--) {
      final y = dy + 14 + (i * rStep);
      final jitter = (i % 2 == 0 ? -2.0 : 1.6);
      path.lineTo(dx + jitter, y);
    }
    path.quadraticBezierTo(dx, dy, dx + 14, dy);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ═══════════════════════════════════════════════════════════════════════════
// 16. FELT CLOUDS AND STARS (User's Exact Custom Painter Specs)
// ═══════════════════════════════════════════════════════════════════════════

class FeltCloud extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const FeltCloud({
    super.key,
    required this.width,
    required this.height,
    this.color = const Color(0xFF7E8A9A),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: CloudPainter(color: color),
    );
  }
}

class CloudPainter extends CustomPainter {
  final Color color;

  CloudPainter({this.color = const Color(0xFF7E8A9A)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color // Grey-blue felt color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Drawing a flat bottom cloud with bubbly top (Bezier Curves)
    path.moveTo(size.width * 0.1, size.height * 0.85);
    path.lineTo(size.width * 0.9, size.height * 0.85); // Flat bottom

    // Right side bump
    path.quadraticBezierTo(
        size.width * 1.05, size.height * 0.85, size.width * 0.95, size.height * 0.5);
    // Top right bump
    path.quadraticBezierTo(
        size.width * 0.85, size.height * 0.1, size.width * 0.65, size.height * 0.25);
    // Top middle bump
    path.quadraticBezierTo(
        size.width * 0.45, size.height * -0.05, size.width * 0.3, size.height * 0.3);
    // Left bump
    path.quadraticBezierTo(
        size.width * 0.05, size.height * 0.25, size.width * 0.05, size.height * 0.6);
    // Bottom left corner
    path.quadraticBezierTo(
        size.width * -0.05, size.height * 0.85, size.width * 0.1, size.height * 0.85);

    path.close();

    // Draw the realistic drop shadow FIRST (so it sits behind the cloud)
    // Elevation is set to 8.0 to give that thick paper/felt depth
    canvas.drawShadow(path, Colors.black87, 8.0, false);

    // Draw the actual cloud path over the shadow
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FeltStar extends StatelessWidget {
  final double size;
  final Color color;

  const FeltStar({
    super.key,
    required this.size,
    this.color = const Color(0xFFF2ECDA), // star.cream
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '★',
      style: TextStyle(
        fontSize: size,
        color: color,
        shadows: const [
          Shadow(
            color: Colors.black54,
            blurRadius: 5.0,
            offset: Offset(3.0, 3.0), // Casts shadow to the bottom right
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// 17. MICRO-ANIMATED PAPER & FELT INTERACTION WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class PaperPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PaperPressable({super.key, required this.child, this.onTap});

  @override
  State<PaperPressable> createState() => _PaperPressableState();
}

class _PaperPressableState extends State<PaperPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutQuad,
        child: widget.child,
      ),
    );
  }
}

class FloatingOrigamiBird extends StatefulWidget {
  final double size;
  const FloatingOrigamiBird({super.key, this.size = 56});

  @override
  State<FloatingOrigamiBird> createState() => _FloatingOrigamiBirdState();
}

class _FloatingOrigamiBirdState extends State<FloatingOrigamiBird>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = sin(_controller.value * pi * 2) * 6.0;
        final rot = sin(_controller.value * pi * 2) * 0.05;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: rot,
            child: PaperOrigamiBird(size: widget.size),
          ),
        );
      },
    );
  }
}

class DriftingFeltCloud extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final double driftDistance;

  const DriftingFeltCloud({
    super.key,
    required this.width,
    required this.height,
    this.color = const Color(0xFF7E8A9A),
    this.driftDistance = 14.0,
  });

  @override
  State<DriftingFeltCloud> createState() => _DriftingFeltCloudState();
}

class _DriftingFeltCloudState extends State<DriftingFeltCloud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = sin(_controller.value * pi * 2) * widget.driftDistance;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: FeltCloud(
            width: widget.width,
            height: widget.height,
            color: widget.color,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GOOGLE G LOGO PAINTER — Official 4-color Google G icon
// ═══════════════════════════════════════════════════════════════════════════

class GoogleGLogoPainter extends CustomPainter {
  const GoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48.0;

    // 1. Red Path (Top)
    final redPath = Path()
      ..moveTo(24 * s, 9.5 * s)
      ..cubicTo(27.54 * s, 9.5 * s, 30.71 * s, 10.72 * s, 33.21 * s, 13.1 * s)
      ..lineTo(40.06 * s, 6.25 * s)
      ..cubicTo(35.9 * s, 2.38 * s, 30.47 * s, 0, 24 * s, 0)
      ..cubicTo(14.62 * s, 0, 6.51 * s, 5.38 * s, 2.56 * s, 13.22 * s)
      ..lineTo(10.54 * s, 19.41 * s)
      ..cubicTo(12.43 * s, 13.72 * s, 17.74 * s, 9.5 * s, 24 * s, 9.5 * s)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill);

    // 2. Blue Path (Right & Horizontal Bar)
    final bluePath = Path()
      ..moveTo(46.98 * s, 24.55 * s)
      ..cubicTo(46.98 * s, 22.98 * s, 46.83 * s, 21.46 * s, 46.60 * s, 20 * s)
      ..lineTo(24 * s, 20 * s)
      ..lineTo(24 * s, 29.02 * s)
      ..lineTo(36.94 * s, 29.02 * s)
      ..cubicTo(36.36 * s, 31.98 * s, 34.68 * s, 34.50 * s, 32.16 * s, 36.20 * s)
      ..lineTo(39.89 * s, 42.20 * s)
      ..cubicTo(44.40 * s, 38.02 * s, 46.98 * s, 31.84 * s, 46.98 * s, 24.55 * s)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill);

    // 3. Yellow Path (Left)
    final yellowPath = Path()
      ..moveTo(10.53 * s, 28.59 * s)
      ..cubicTo(10.05 * s, 27.14 * s, 9.77 * s, 25.60 * s, 9.77 * s, 24 * s)
      ..cubicTo(9.77 * s, 22.40 * s, 10.05 * s, 20.86 * s, 10.53 * s, 19.41 * s)
      ..lineTo(2.56 * s, 13.22 * s)
      ..cubicTo(0.92 * s, 16.46 * s, 0, 20.12 * s, 0, 24 * s)
      ..cubicTo(0, 27.88 * s, 0.92 * s, 31.54 * s, 2.56 * s, 34.78 * s)
      ..lineTo(10.53 * s, 28.59 * s)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill);

    // 4. Green Path (Bottom)
    final greenPath = Path()
      ..moveTo(24 * s, 48 * s)
      ..cubicTo(30.48 * s, 48 * s, 35.93 * s, 45.87 * s, 39.89 * s, 42.19 * s)
      ..lineTo(32.16 * s, 36.19 * s)
      ..cubicTo(30.01 * s, 37.64 * s, 27.24 * s, 38.5 * s, 24 * s, 38.5 * s)
      ..cubicTo(17.74 * s, 38.5 * s, 12.43 * s, 34.28 * s, 10.53 * s, 28.59 * s)
      ..lineTo(2.56 * s, 34.78 * s)
      ..cubicTo(6.51 * s, 42.62 * s, 14.62 * s, 48 * s, 24 * s, 48 * s)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// GOOGLE STICKER BUTTON — Dual-layer paper craft Google Button
// ═══════════════════════════════════════════════════════════════════════════

class GoogleStickerButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const GoogleStickerButton({
    super.key,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PaperPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(2.5), // Outer dark paper border thickness
        decoration: BoxDecoration(
          color: const Color(0xFF65594E), // Dark taupe outer paper edge frame
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(2, 4),
            ),
            BoxShadow(
              color: Colors.white30,
              blurRadius: 1,
              offset: Offset(-1, -1),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6EE), // Cream paper sticker surface
            borderRadius: BorderRadius.circular(10.5),
            border: Border.all(color: const Color(0xFFDFD6C4), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF4285F4),
                  ),
                )
              else ...[
                // Authentic 4-Color Google G Logo
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(painter: GoogleGLogoPainter()),
                ),
                const SizedBox(width: 10),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.nunito(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3E3832),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DOOR & ARROW ICON PAINTER — Matching "→]" Login Spec Icon
// ═══════════════════════════════════════════════════════════════════════════

class DoorArrowIconPainter extends CustomPainter {
  final Color color;
  const DoorArrowIconPainter({this.color = const Color(0xFFF4EEDD)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Bracket Door ']' on the right
    final doorPath = Path()
      ..moveTo(w * 0.70, h * 0.18)
      ..lineTo(w * 0.88, h * 0.18)
      ..lineTo(w * 0.88, h * 0.82)
      ..lineTo(w * 0.70, h * 0.82);
    canvas.drawPath(doorPath, paint);

    // Arrow '→' on the left
    canvas.drawLine(Offset(w * 0.12, h * 0.5), Offset(w * 0.68, h * 0.5), paint);

    // Arrowhead '>'
    final arrowHead = Path()
      ..moveTo(w * 0.50, h * 0.32)
      ..lineTo(w * 0.68, h * 0.50)
      ..lineTo(w * 0.50, h * 0.68);
    canvas.drawPath(arrowHead, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// FELT CTA BUTTON — Fibrous felt textured primary action button (Matching Spec)
// ═══════════════════════════════════════════════════════════════════════════

class FeltCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const FeltCtaButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PaperPressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(2, 5),
            ),
            BoxShadow(
              color: const Color(0xFFE68668).withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            children: [
              // Felt Base Fill & Micro Fibers
              Positioned.fill(
                child: CustomPaint(
                  painter: FeltTexturePainter(color: const Color(0xFFE26D5C)),
                ),
              ),
              // Inner Top Highlight Rim
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1.5,
                child: Container(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              // Button Content
              Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Color(0xFFF4EEDD),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CustomPaint(
                              painter: DoorArrowIconPainter(color: Color(0xFFF4EEDD)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: GoogleFonts.nunito(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF4EEDD),
                              letterSpacing: 0.3,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeltTexturePainter extends CustomPainter {
  final Color color;

  FeltTexturePainter({this.color = const Color(0xFFE26D5C)});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Base Felt Color
    canvas.drawRRect(rrect, Paint()..color = color);

    // Mottled felt gradient overlay
    final feltGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        color,
        Color.lerp(color, const Color(0xFFD45B4A), 0.4)!,
      ],
    );
    canvas.drawRRect(rrect, Paint()..shader = feltGradient.createShader(rect));

    // Micro Fibrous Texture Lines
    final random = Random(101);
    final fiberLight = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final fiberDark = Paint()
      ..color = const Color(0xFFB8483A).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 90; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final len = 4.0 + random.nextDouble() * 7.0;
      final angle = random.nextDouble() * pi;

      final path = Path()
        ..moveTo(x, y)
        ..lineTo(x + cos(angle) * len, y + sin(angle) * len);

      canvas.drawPath(path, (i.isEven) ? fiberLight : fiberDark);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// 5-POINTED PAPER CUT STAR (Matching Spec Image)
// ═══════════════════════════════════════════════════════════════════════════

class PaperCutStar extends StatelessWidget {
  final double size;
  final Color color;
  final double rotation;

  const PaperCutStar({
    super.key,
    this.size = 20,
    this.color = const Color(0xFFFAF6EE),
    this.rotation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: PaperCutStarPainter(color: color),
        ),
      ),
    );
  }
}

class PaperCutStarPainter extends CustomPainter {
  final Color color;
  PaperCutStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.42;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * 36 - 90) * pi / 180;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Drop shadow
    final shadowPath = path.shift(const Offset(1.5, 2.5));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Star body
    canvas.drawPath(path, Paint()..color = color);

    // Subtle 3D center crease line
    final creasePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(cx, cy - outerR), Offset(cx, cy), creasePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// TWINKLING PAPER CUT STAR — Smooth pulsing & blinking star animation
// ═══════════════════════════════════════════════════════════════════════════

class TwinklingPaperCutStar extends StatefulWidget {
  final double size;
  final Color color;
  final double rotation;
  final Duration duration;
  final Duration delay;

  const TwinklingPaperCutStar({
    super.key,
    this.size = 14,
    this.color = const Color(0xFFFAF6EE),
    this.rotation = 0.0,
    this.duration = const Duration(milliseconds: 1800),
    this.delay = Duration.zero,
  });

  @override
  State<TwinklingPaperCutStar> createState() => _TwinklingPaperCutStarState();
}

class _TwinklingPaperCutStarState extends State<TwinklingPaperCutStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnim = Tween<double>(begin: 0.75, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnim = Tween<double>(begin: 0.30, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.delay == Duration.zero) {
      _controller.repeat(reverse: true);
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: PaperCutStar(
              size: widget.size,
              color: widget.color,
              rotation: widget.rotation,
            ),
          ),
        );
      },
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// DUAL LAYER FELT CLOUD WIDGET (Matching Spec Image)
// ═══════════════════════════════════════════════════════════════════════════

class DualLayerFeltCloudWidget extends StatelessWidget {
  final double width;
  final double height;

  const DualLayerFeltCloudWidget({
    super.key,
    this.width = 150,
    this.height = 75,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Lower Darker Slate Felt Cloud (#536074)
          Positioned(
            left: 0,
            bottom: 0,
            width: width * 0.88,
            height: height * 0.72,
            child: CustomPaint(
              painter: ScallopedFeltCloudPainter(
                color: const Color(0xFF536074),
                isLight: false,
              ),
            ),
          ),
          // 2. Upper Overlapping Light Slate Felt Cloud (#BAC3D0)
          Positioned(
            right: 0,
            top: 0,
            width: width * 0.58,
            height: height * 0.56,
            child: CustomPaint(
              painter: ScallopedFeltCloudPainter(
                color: const Color(0xFFBAC3D0),
                isLight: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScallopedFeltCloudPainter extends CustomPainter {
  final Color color;
  final bool isLight;

  ScallopedFeltCloudPainter({
    required this.color,
    this.isLight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scalloped cloud path with 4 rounded humps
    final path = Path();
    path.moveTo(w * 0.08, h * 0.90);

    // Leftmost hump
    path.cubicTo(-w * 0.05, h * 0.65, -w * 0.02, h * 0.35, w * 0.18, h * 0.35);

    // Middle-left hump
    path.cubicTo(w * 0.15, h * 0.05, w * 0.40, h * 0.02, w * 0.48, h * 0.22);

    // Middle-right hump
    path.cubicTo(w * 0.55, h * 0.04, w * 0.82, h * 0.10, w * 0.84, h * 0.38);

    // Rightmost hump
    path.cubicTo(w * 1.05, h * 0.45, w * 1.02, h * 0.80, w * 0.88, h * 0.90);

    // Bottom edge
    path.lineTo(w * 0.08, h * 0.90);
    path.close();

    // 1. Drop shadow
    final shadowPath = path.shift(const Offset(2, 4));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 2. Base Fill
    canvas.drawPath(path, Paint()..color = color);

    // 3. Felt Texture Lines
    final random = Random(isLight ? 77 : 44);
    final fiberLight = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final fiberDark = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final bounds = path.getBounds();
    for (int i = 0; i < 50; i++) {
      final x = bounds.left + random.nextDouble() * bounds.width;
      final y = bounds.top + random.nextDouble() * bounds.height;
      if (path.contains(Offset(x, y))) {
        final len = 3.0 + random.nextDouble() * 5.0;
        final angle = random.nextDouble() * pi;
        canvas.drawLine(
          Offset(x, y),
          Offset(x + cos(angle) * len, y + sin(angle) * len),
          (i.isEven) ? fiberLight : fiberDark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// SINGLE FELT CLOUD WIDGET (Matching Spec Image)
// ═══════════════════════════════════════════════════════════════════════════

class SingleFeltCloudWidget extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const SingleFeltCloudWidget({
    super.key,
    this.width = 110,
    this.height = 55,
    this.color = const Color(0xFF536074),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: ScallopedFeltCloudPainter(color: color),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DRIFTING CLOUD WRAPPER — Smooth horizontal floating cloud movement
// ═══════════════════════════════════════════════════════════════════════════

class DriftingCloudWrapper extends StatefulWidget {
  final Widget child;
  final double driftDistance;
  final Duration duration;

  const DriftingCloudWrapper({
    super.key,
    required this.child,
    this.driftDistance = 10.0,
    this.duration = const Duration(seconds: 7),
  });

  @override
  State<DriftingCloudWrapper> createState() => _DriftingCloudWrapperState();
}

class _DriftingCloudWrapperState extends State<DriftingCloudWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = sin(_controller.value * pi * 2) * widget.driftDistance;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: widget.child,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FALLING PAPER PETALS RAIN OVERLAY — Organic floating petal particle effect
// ═══════════════════════════════════════════════════════════════════════════

class FallingPaperPetal {
  double x;
  double y;
  double speed;
  double size;
  double rotation;
  double rotationSpeed;
  Color color;
  double wobble;

  FallingPaperPetal({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.wobble,
  });
}

class PaperPetalsRainOverlay extends StatefulWidget {
  const PaperPetalsRainOverlay({super.key});

  @override
  State<PaperPetalsRainOverlay> createState() => _PaperPetalsRainOverlayState();
}

class _PaperPetalsRainOverlayState extends State<PaperPetalsRainOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FallingPaperPetal> _petals = [];
  final Random _random = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final colors = [
      const Color(0xFFE8967D),
      const Color(0xFFE68668),
      const Color(0xFF8B965C),
      const Color(0xFFA5B27D),
      const Color(0xFFF2D9CE),
    ];

    for (int i = 0; i < 14; i++) {
      _petals.add(
        FallingPaperPetal(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speed: 0.08 + _random.nextDouble() * 0.12,
          size: 10 + _random.nextDouble() * 10,
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 1.5,
          color: colors[_random.nextInt(colors.length)],
          wobble: _random.nextDouble() * pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _PaperPetalsRainPainter(
                petals: _petals,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaperPetalsRainPainter extends CustomPainter {
  final List<FallingPaperPetal> petals;
  final double progress;

  _PaperPetalsRainPainter({required this.petals, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final screenWidth = size.width;
    final screenHeight = size.height;

    for (final petal in petals) {
      final yPos = ((petal.y + progress * petal.speed) % 1.0) * (screenHeight + 60) - 30;
      final xPos = (petal.x + sin(progress * pi * 2 + petal.wobble) * 0.06) * screenWidth;
      final rot = petal.rotation + progress * petal.rotationSpeed * pi * 2;

      canvas.save();
      canvas.translate(xPos, yPos);
      canvas.rotate(rot);

      final width = petal.size;
      final height = petal.size * 0.6;
      final rect = Rect.fromLTWH(0, 0, width, height);

      // Shadow
      final shadowPaint = Paint()
        ..color = Colors.black12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect.shift(const Offset(1, 2)),
          topLeft: Radius.circular(petal.size * 0.8),
          bottomRight: Radius.circular(petal.size * 0.8),
        ),
        shadowPaint,
      );

      // Body
      final paint = Paint()..color = petal.color;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: Radius.circular(petal.size * 0.8),
          bottomRight: Radius.circular(petal.size * 0.8),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPetalsRainPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// SWAYING KRAFT LUGGAGE TAG WIDGET (Dangling Pendulum Animation)
// ═══════════════════════════════════════════════════════════════════════════

class SwayingKraftLuggageTag extends StatefulWidget {
  final String text;
  final double baseRotation;

  const SwayingKraftLuggageTag({
    super.key,
    this.text = 'WELCOME',
    this.baseRotation = -0.10, // ~-6 degrees default tilt
  });

  @override
  State<SwayingKraftLuggageTag> createState() => _SwayingKraftLuggageTagState();
}

class _SwayingKraftLuggageTagState extends State<SwayingKraftLuggageTag>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _swingAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _swingAnim = Tween<double>(
      begin: widget.baseRotation - 0.04,
      end: widget.baseRotation + 0.04,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _swingAnim.value,
          alignment: Alignment.topLeft, // Dangling pivot point at punched hole!
          child: KraftLuggageTag(
            text: widget.text,
            rotation: 0,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED TOP KRAFT HEART BUTTON WIDGET (Pulsing & Wiggling Animation)
// ═══════════════════════════════════════════════════════════════════════════

class AnimatedTopKraftHeart extends StatefulWidget {
  const AnimatedTopKraftHeart({super.key});

  @override
  State<AnimatedTopKraftHeart> createState() => _AnimatedTopKraftHeartState();
}

class _AnimatedTopKraftHeartState extends State<AnimatedTopKraftHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnim = Tween<double>(begin: -0.18, end: -0.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: const SizedBox(
              width: 55,
              height: 44,
              child: CustomPaint(
                painter: TopKraftHeartWidgetPainter(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TopKraftHeartWidgetPainter extends CustomPainter {
  const TopKraftHeartWidgetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final heartCenter = Offset(size.width / 2, size.height / 2);
    const sizeH = 24.0;

    // White Cotton String Tails
    final stringPaint = Paint()
      ..color = const Color(0xFFFAF8F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final stringTailLeft = Path()
      ..moveTo(heartCenter.dx - 3, heartCenter.dy)
      ..cubicTo(
        heartCenter.dx - 12, heartCenter.dy - 10,
        heartCenter.dx - 20, heartCenter.dy - 4,
        heartCenter.dx - 26, heartCenter.dy - 14,
      );
    canvas.drawPath(stringTailLeft, stringPaint);

    final stringTailRight = Path()
      ..moveTo(heartCenter.dx + 3, heartCenter.dy)
      ..cubicTo(
        heartCenter.dx + 12, heartCenter.dy + 8,
        heartCenter.dx + 22, heartCenter.dy + 10,
        heartCenter.dx + 28, heartCenter.dy + 14,
      );
    canvas.drawPath(stringTailRight, stringPaint);

    // Heart Shadow
    final heartPath = Path();
    heartPath.moveTo(0, sizeH * 0.35);
    heartPath.cubicTo(
      -sizeH * 0.52, -sizeH * 0.3,
      -sizeH * 0.52, -sizeH * 0.72,
      0, -sizeH * 0.35,
    );
    heartPath.cubicTo(
      sizeH * 0.52, -sizeH * 0.72,
      sizeH * 0.52, -sizeH * 0.3,
      0, sizeH * 0.35,
    );

    canvas.save();
    canvas.translate(heartCenter.dx + 2, heartCenter.dy + 3);
    canvas.drawPath(
      heartPath,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.restore();

    // Heart Body
    canvas.save();
    canvas.translate(heartCenter.dx, heartCenter.dy);
    canvas.drawPath(heartPath, Paint()..color = const Color(0xFFC5A67C));
    canvas.drawPath(
      heartPath,
      Paint()
        ..color = const Color(0xFFA6875C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Holes
    final holePaint = Paint()..color = const Color(0xFF4A3824);
    canvas.drawCircle(const Offset(-3.5, -1), 1.6, holePaint);
    canvas.drawCircle(const Offset(3.5, -1), 1.6, holePaint);

    // White Thread
    canvas.drawLine(
      const Offset(-3.5, -1),
      const Offset(3.5, -1),
      Paint()
        ..color = const Color(0xFFFAF8F5)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// 14. PAPER BOTTOM DOCK — Persistent paper floating bottom navigation bar
// ═══════════════════════════════════════════════════════════════════════════

class PaperBottomDock extends StatelessWidget {
  final int currentIndex;
  final bool isScrolled;
  final bool hasUnreadMessages;
  final VoidCallback? onHomeTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;

  const PaperBottomDock({
    super.key,
    this.currentIndex = 0,
    this.isScrolled = false,
    this.hasUnreadMessages = false,
    this.onHomeTap,
    this.onChatTap,
    this.onProfileTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockBg = isDark
        ? const Color(0xFF262321).withValues(alpha: 0.88)
        : const Color(0xFFFCFAF7).withValues(alpha: 0.88);
    final dockBorder = isDark ? const Color(0xFF403C38) : const Color(0xFFE2D8C6);

    final double marginHorizontal = isScrolled ? 65.0 : 36.0;
    final double dockHeight = isScrolled ? 46.0 : 54.0;
    final double iconSize = isScrolled ? 20.0 : 23.0;

    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        margin: EdgeInsets.fromLTRB(marginHorizontal, 0, marginHorizontal, isScrolled ? 6 : 12),
        height: dockHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dockHeight / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: dockBg,
                borderRadius: BorderRadius.circular(dockHeight / 2),
                border: Border.all(color: dockBorder, width: 1.5),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: isScrolled ? 6 : 12,
                          offset: Offset(0, isScrolled ? 3 : 6),
                        ),
                      ]
                    : PaperDepth.layerShadow(isScrolled ? 1 : 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 🏠 Home Icon Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Home',
                    icon: Icon(
                      Icons.home_rounded,
                      color: currentIndex == 0
                          ? PaperColors.roseCutout
                          : (isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark),
                      size: iconSize,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (onHomeTap != null) onHomeTap!();
                    },
                  ),

                  // 💬 Chat / Love Notes Icon Button (with Red Dot Badge 🔴)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Chat',
                        icon: Icon(
                          Icons.chat_bubble_rounded,
                          color: currentIndex == 1
                              ? PaperColors.roseCutout
                              : (isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark),
                          size: iconSize,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (onChatTap != null) onChatTap!();
                        },
                      ),
                      if (hasUnreadMessages)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF262321) : const Color(0xFFFCFAF7),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  // 👤 Profile Icon Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Profile',
                    icon: Icon(
                      Icons.person_rounded,
                      color: currentIndex == 2
                          ? PaperColors.roseCutout
                          : (isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark),
                      size: iconSize,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (onProfileTap != null) onProfileTap!();
                    },
                  ),

                  // ⚙️ Settings Icon Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Settings',
                    icon: Icon(
                      Icons.settings_rounded,
                      color: currentIndex == 3
                          ? PaperColors.roseCutout
                          : (isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark),
                      size: iconSize,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (onSettingsTap != null) onSettingsTap!();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaperNotificationPopup {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String? avatarLetter,
    VoidCallback? onTap,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                entry.remove();
                _currentEntry = null;
                if (onTap != null) onTap();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2F3A) : const Color(0xFFFCFAF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4A4E5C) : const Color(0xFFE2D8C6),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(2, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: PaperColors.roseCutout,
                      ),
                      child: Center(
                        child: Text(
                          avatarLetter ?? '💬',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: PaperColors.sageCutout,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'NEW',
                                  style: GoogleFonts.nunito(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : PaperColors.inkMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: PaperColors.roseCutout),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.4, end: 0, curve: Curves.easeOutBack),
            ),
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 4), () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}











