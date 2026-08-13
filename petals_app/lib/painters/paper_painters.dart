// All hand-crafted paper/felt shapes as CustomPainters + one CustomClipper.
// No image or SVG assets are required — the whole scene renders as vector
// paths, so it looks identical on every device and pixel density.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/petals_theme.dart';

/// Clips a rectangle into a hand-torn scrapbook page: jagged top and
/// bottom edges, straight left/right edges. Pair with [PhysicalShape] to
/// get an elevation shadow that follows the torn outline.
class TornPaperClipper extends CustomClipper<Path> {
  const TornPaperClipper({this.jag = 8, this.teeth = 34});

  final double jag;
  final int teeth;

  @override
  Path getClip(Size size) {
    final path = Path();
    final toothWidth = size.width / teeth;

    path.moveTo(0, jag);
    for (int i = 0; i <= teeth; i++) {
      final x = (i * toothWidth).clamp(0.0, size.width);
      final y = i.isEven ? 0.0 : jag * 1.6;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height - jag);

    for (int i = teeth; i >= 0; i--) {
      final x = (i * toothWidth).clamp(0.0, size.width);
      final y = size.height - (i.isEven ? 0.0 : jag * 1.6);
      path.lineTo(x, y);
    }

    path.lineTo(0, jag);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant TornPaperClipper oldClipper) =>
      jag != oldClipper.jag || teeth != oldClipper.teeth;
}

/// A soft, layered felt cloud cut-out with a faint drop shadow.
class PaperCloudPainter extends CustomPainter {
  const PaperCloudPainter({this.color = PetalsColors.cloudSlate});

  final Color color;

  Path _cloudPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..addOval(Rect.fromLTWH(0, h * 0.35, w * 0.42, h * 0.55))
      ..addOval(Rect.fromLTWH(w * 0.28, h * 0.05, w * 0.5, h * 0.75))
      ..addOval(Rect.fromLTWH(w * 0.6, h * 0.3, w * 0.4, h * 0.6));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cloudPath(size);
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.18);
    final fillPaint = Paint()..color = color;

    canvas.save();
    canvas.translate(3, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant PaperCloudPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A small 4-point "sparkle" star.
class SparkleStarPainter extends CustomPainter {
  const SparkleStarPainter({this.color = PetalsColors.starCream});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w * 0.56, h * 0.44, w, h * 0.5)
      ..quadraticBezierTo(w * 0.56, h * 0.56, w * 0.5, h)
      ..quadraticBezierTo(w * 0.44, h * 0.56, 0, h * 0.5)
      ..quadraticBezierTo(w * 0.44, h * 0.44, w * 0.5, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparkleStarPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A puffy folded-paper heart with a faint center crease.
class PaperHeartPainter extends CustomPainter {
  const PaperHeartPainter({this.color = PetalsColors.heartBlush});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.95)
      ..cubicTo(-w * 0.05, h * 0.6, w * 0.05, h * 0.05, w * 0.5, h * 0.32)
      ..cubicTo(w * 0.95, h * 0.05, w * 1.05, h * 0.6, w * 0.5, h * 0.95)
      ..close();
    canvas.drawPath(path, fillPaint);

    final creasePaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.34),
      Offset(w * 0.5, h * 0.82),
      creasePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PaperHeartPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A small paper leaf with a center vein.
class PaperLeafPainter extends CustomPainter {
  const PaperLeafPainter({this.color = PetalsColors.leafOlive});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w, h * 0.35, w * 0.5, h)
      ..quadraticBezierTo(0, h * 0.35, w * 0.5, 0)
      ..close();
    canvas.drawPath(path, fillPaint);

    final veinPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.08),
      Offset(w * 0.5, h * 0.9),
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PaperLeafPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The circular "petals" flower mark: 5 rotated petals + a pale center.
class FlowerLogoPainter extends CustomPainter {
  const FlowerLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const petalLight = Color(0xFFF2C4CE);
    const petalDeep = Color(0xFFE79AAA);
    final creaseColor = Colors.black.withOpacity(0.1);
    final petalLength = size.width * 0.34;
    final petalWidth = size.width * 0.24;

    for (int i = 0; i < 5; i++) {
      final angle = i * 72 * math.pi / 180;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final petalPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(petalWidth / 2, -petalLength * 0.55, 0, -petalLength)
        ..quadraticBezierTo(-petalWidth / 2, -petalLength * 0.55, 0, 0)
        ..close();
      canvas.drawPath(
        petalPath,
        Paint()..color = i.isEven ? petalLight : petalDeep,
      );

      final creasePaint = Paint()
        ..color = creaseColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset.zero,
        Offset(0, -petalLength * 0.85),
        creasePaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      size.width * 0.11,
      Paint()..color = const Color(0xFFFBF3E7),
    );
  }

  @override
  bool shouldRepaint(covariant FlowerLogoPainter oldDelegate) => false;
}

/// A simplified faceted origami crane silhouette.
class OrigamiCranePainter extends CustomPainter {
  const OrigamiCranePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = const Color(0xFFF7F1E3);
    final shade = Paint()..color = const Color(0xFFE3DAC4);
    final fold = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final bodyPath = Path()
      ..moveTo(w * 0.35, h * 0.55)
      ..lineTo(w * 0.62, h * 0.30)
      ..lineTo(w * 0.85, h * 0.62)
      ..lineTo(w * 0.55, h * 0.95)
      ..close();
    canvas.drawPath(bodyPath, body);

    final wingPath = Path()
      ..moveTo(w * 0.62, h * 0.30)
      ..lineTo(w * 0.85, h * 0.62)
      ..lineTo(w * 0.55, h * 0.95)
      ..close();
    canvas.drawPath(wingPath, shade);

    final neckPath = Path()
      ..moveTo(w * 0.35, h * 0.55)
      ..lineTo(w * 0.06, h * 0.18)
      ..lineTo(w * 0.14, h * 0.14)
      ..lineTo(w * 0.42, h * 0.5)
      ..close();
    canvas.drawPath(neckPath, body);

    final tailPath = Path()
      ..moveTo(w * 0.55, h * 0.95)
      ..lineTo(w * 0.95, h * 0.78)
      ..lineTo(w * 0.85, h * 0.62)
      ..close();
    canvas.drawPath(tailPath, body);

    canvas.drawLine(
      Offset(w * 0.35, h * 0.55),
      Offset(w * 0.62, h * 0.30),
      fold,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.30),
      Offset(w * 0.55, h * 0.95),
      fold,
    );
  }

  @override
  bool shouldRepaint(covariant OrigamiCranePainter oldDelegate) => false;
}

/// A simplified, stylised approximation of a multicolor "G" mark.
/// Swap for the official Google branding asset before shipping — this
/// hand-drawn version is for mockup / demo purposes only.
class GoogleMarkPainter extends CustomPainter {
  const GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.22;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startDeg * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
        paint,
      );
    }

    arc(-45, -100, const Color(0xFFEA4335));
    arc(-145, -90, const Color(0xFF4285F4));
    arc(125, -90, const Color(0xFFFBBC05));
    arc(-45, 100, const Color(0xFF34A853));

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.42,
        size.width * 0.46,
        size.height * 0.16,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant GoogleMarkPainter oldDelegate) => false;
}

/// Two faint hand-stitched wavy thread lines.
class StitchPainter extends CustomPainter {
  const StitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PetalsColors.textInk.withOpacity(0.3)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (int row = 0; row < 2; row++) {
      final y = size.height * (row == 0 ? 0.3 : 0.75);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x < size.width; x += 10) {
        path.quadraticBezierTo(x + 5, y - 4, x + 10, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StitchPainter oldDelegate) => false;
}
