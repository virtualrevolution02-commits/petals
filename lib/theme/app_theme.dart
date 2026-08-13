import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Handcrafted Paper Cut-out Theme & Design System for Petals
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

class PaperColors {
  // Light Parchment Mode Palette
  static const Color backgroundParchment = Color(0xFFF6F3EE);
  static const Color cardPaper = Color(0xFFFCFAF7);
  static const Color kraftPaper = Color(0xFFE6D8C6);
  static const Color roseCutout = Color(0xFFE8647A);
  static const Color roseDark = Color(0xFFC94D62);
  static const Color sageCutout = Color(0xFF8B9D83);
  static const Color goldCutout = Color(0xFFE5B25D);
  static const Color skyCutout = Color(0xFF89B3C9);
  static const Color lavenderCutout = Color(0xFFB39DBE);

  // Accent Tapes & Pins
  static const Color tapeYellow = Color(0xCCE6DCA5);
  static const Color pinRed = Color(0xFFD84A57);
  static const Color stampBorder = Color(0xFFD4C7B5);

  // Ink Typography
  static const Color inkDark = Color(0xFF2C2825);
  static const Color inkMedium = Color(0xFF6B635E);
  static const Color inkLight = Color(0xFF9E958E);

  // Dark Charcoal Paper Palette
  static const Color darkBackground = Color(0xFF191716);
  static const Color darkCard = Color(0xFF262321);
  static const Color darkCardElevated = Color(0xFF332F2C);
  static const Color darkInkPrimary = Color(0xFFF4EFEA);
  static const Color darkInkSecondary = Color(0xFFAFA69E);

  // Paper Edge Colors (lighter face = cut stock visible on edges)
  static const Color lightEdge = Color(0xFFFFF8F0);
  static const Color darkEdge = Color(0xFF3D3833);
  static const Color kraftEdge = Color(0xFFF0E4D2);

  // Diorama background tones
  static const Color dioramaSkyLight = Color(0xFFE8E0D4);
  static const Color dioramaSkyDark = Color(0xFF1E1B19);
  static const Color dioramaHillLight = Color(0xFFD5C9B8);
  static const Color dioramaHillDark = Color(0xFF2A2623);
}

/// Dimensional depth system that simulates real paper stacking in a shadow box.
/// Each depth level adds progressively stronger warm-tinted shadows and visible
/// paper edge thickness, creating the illusion of looking into a paper diorama.
class PaperDepth {
  /// Warm shadow tint — not pure black, but the warm umber you see when
  /// light filters between stacked paper sheets.
  static const Color _shadowWarm = Color(0x26352E28);
  static const Color _shadowMedium = Color(0x33352E28);
  static const Color _shadowDeep = Color(0x40352E28);

  /// Returns layered box shadows that simulate real stacked paper.
  /// [depth] 0 = background (no shadow), 1 = midground, 2 = foreground, 3 = overlay.
  static List<BoxShadow> layerShadow(int depth) {
    if (depth <= 0) return [];
    switch (depth) {
      case 1:
        return [
          BoxShadow(
            color: _shadowWarm,
            offset: const Offset(1.5, 2.5),
            blurRadius: 3.0,
            spreadRadius: 0,
          ),
        ];
      case 2:
        return [
          // Primary cast shadow
          BoxShadow(
            color: _shadowMedium,
            offset: const Offset(2.5, 4.0),
            blurRadius: 6.0,
            spreadRadius: 0,
          ),
          // Ambient fill shadow (soft, wide)
          BoxShadow(
            color: _shadowWarm,
            offset: const Offset(1.0, 1.5),
            blurRadius: 2.0,
            spreadRadius: -1,
          ),
        ];
      case 3:
      default:
        return [
          // Deep cast shadow
          BoxShadow(
            color: _shadowDeep,
            offset: const Offset(3.5, 6.0),
            blurRadius: 10.0,
            spreadRadius: 0,
          ),
          // Mid ambient
          BoxShadow(
            color: _shadowMedium,
            offset: const Offset(1.5, 3.0),
            blurRadius: 4.0,
            spreadRadius: -1,
          ),
          // Contact shadow (tight, near base)
          BoxShadow(
            color: _shadowWarm,
            offset: const Offset(0.5, 1.0),
            blurRadius: 1.5,
            spreadRadius: -1,
          ),
        ];
    }
  }

  /// Visible paper edge strip width for each depth level.
  static double edgeThickness(int depth) {
    if (depth <= 0) return 0;
    return 1.0 + (depth * 0.5);
  }

  /// Parallax factor for scroll-based depth illusion.
  /// Lower depth = slower scroll = appears further back.
  static double parallaxFactor(int depth) {
    switch (depth) {
      case 0:
        return 0.3;
      case 1:
        return 0.65;
      case 2:
      default:
        return 1.0;
    }
  }
}

/// Provides paper grain texture and fiber overlays for the diorama surfaces.
class PaperTextures {
  /// A subtle noise-grain decoration to overlay on paper surfaces.
  /// Uses a very low-opacity radial gradient to simulate paper fiber texture.
  static BoxDecoration grainOverlay({Color baseColor = Colors.transparent}) {
    return BoxDecoration(
      color: baseColor,
      gradient: RadialGradient(
        colors: [
          Colors.white.withOpacity(0.015),
          Colors.black.withOpacity(0.02),
          Colors.white.withOpacity(0.01),
        ],
        stops: const [0.0, 0.5, 1.0],
        center: const Alignment(-0.3, -0.4),
        radius: 1.8,
      ),
    );
  }

  /// Paper edge color based on whether we're in dark mode.
  static Color edgeColor(bool isDark) {
    return isDark ? PaperColors.darkEdge : PaperColors.lightEdge;
  }

  /// The slightly lighter color visible when paper is cut,
  /// revealing the inner stock color.
  static Color cutEdge(Color faceColor) {
    // Lighten the face color by ~15% to simulate exposed inner paper stock
    final hsl = HSLColor.fromColor(faceColor);
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  }
}

class AppTheme {
  // Legacy Color aliases for backward compatibility
  static const Color primary = PaperColors.roseCutout;
  static const Color primaryDark = PaperColors.roseDark;
  static const Color secondary = PaperColors.goldCutout;
  static const Color accent = PaperColors.kraftPaper;
  static const Color background = PaperColors.darkBackground;
  static const Color surface = PaperColors.darkCard;
  static const Color surfaceLight = PaperColors.darkCardElevated;
  static const Color cardColor = PaperColors.darkCard;
  static const Color textPrimary = PaperColors.darkInkPrimary;
  static const Color textSecondary = PaperColors.darkInkSecondary;
  static const Color heartRed = PaperColors.roseCutout;
  static const Color gold = PaperColors.goldCutout;

  /// Custom Paper Box Shadows with stacked cut-out depth
  static List<BoxShadow> paperShadow({
    double depth = 4.0,
    Color shadowColor = const Color(0x1F1C1B1A),
  }) {
    return [
      BoxShadow(
        color: shadowColor,
        offset: Offset(depth * 0.5, depth),
        blurRadius: depth * 1.5,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: shadowColor.withOpacity(0.08),
        offset: Offset(depth * 0.2, depth * 0.4),
        blurRadius: depth * 0.5,
        spreadRadius: -1,
      ),
    ];
  }

  /// Light Parchment Paper Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PaperColors.backgroundParchment,
      colorScheme: const ColorScheme.light(
        primary: PaperColors.roseCutout,
        secondary: PaperColors.goldCutout,
        surface: PaperColors.cardPaper,
        onPrimary: Colors.white,
        onSecondary: PaperColors.inkDark,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: PaperColors.inkDark, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: PaperColors.inkDark, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(color: PaperColors.inkDark, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: PaperColors.inkDark, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: PaperColors.inkDark, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: PaperColors.inkDark, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: PaperColors.inkDark),
          bodyMedium: TextStyle(color: PaperColors.inkMedium),
          labelLarge: TextStyle(color: PaperColors.inkDark, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PaperColors.backgroundParchment,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: PaperColors.inkDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PaperColors.roseCutout,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  /// Dark Charcoal Paper Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PaperColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: PaperColors.roseCutout,
        secondary: PaperColors.goldCutout,
        surface: PaperColors.darkCard,
        onPrimary: Colors.white,
        onSecondary: PaperColors.inkDark,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: PaperColors.darkInkPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: PaperColors.darkInkPrimary, fontWeight: FontWeight.w600),
          headlineLarge: TextStyle(color: PaperColors.darkInkPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: PaperColors.darkInkPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: PaperColors.darkInkPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: PaperColors.darkInkPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: PaperColors.darkInkPrimary),
          bodyMedium: TextStyle(color: PaperColors.darkInkSecondary),
          labelLarge: TextStyle(color: PaperColors.darkInkPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PaperColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: PaperColors.darkInkPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PaperColors.roseCutout,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          elevation: 4,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
