// Petals design tokens — colors and type roles.
//
// Three type "layers" are used deliberately, matching the three material
// layers in the reference design:
//   1. wordmark    -> the printed/cut logo lettering
//   2. handwritten -> pen-on-paper labels, hints, tagline
//   3. uiButton     -> manufactured sticker / button chrome (never handwritten)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PetalsColors {
  PetalsColors._();

  static const bgNavy = Color(0xFF242938);
  static const bgNavyDeep = Color(0xFF1C202B);
  static const cardCream = Color(0xFFEEE6D3);
  static const cardKraftEdge = Color(0xFFC9A96A);
  static const accentCoral = Color(0xFFE68668);
  static const accentCoralDeep = Color(0xFFD9704F);
  static const fieldTaupe = Color(0xFF4C4136);
  static const textCream = Color(0xFFF4EEDD);
  static const textInk = Color(0xFF3A332A);
  static const leafOlive = Color(0xFF8B965C);
  static const heartBlush = Color(0xFFE8967D);
  static const tagKraft = Color(0xFFD8BE8E);
  static const cloudSlate = Color(0xFF7C879C);
  static const starCream = Color(0xFFF2ECDA);
}

class PetalsText {
  PetalsText._();

  static TextStyle wordmark = GoogleFonts.caveat(
    fontWeight: FontWeight.w700,
    fontSize: 58,
    color: PetalsColors.textCream,
    height: 1.0,
  );

  static TextStyle tagline = GoogleFonts.caveat(
    fontWeight: FontWeight.w500,
    fontSize: 20,
    color: PetalsColors.textCream.withOpacity(0.85),
    letterSpacing: 0.6,
  );

  static TextStyle handwritten = GoogleFonts.patrickHand(
    fontSize: 16,
    color: PetalsColors.textInk,
  );

  static TextStyle tagLabel = GoogleFonts.patrickHand(
    fontWeight: FontWeight.w700,
    fontSize: 14,
    color: PetalsColors.textInk,
    letterSpacing: 1.2,
  );

  static TextStyle uiButton = GoogleFonts.nunito(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: PetalsColors.textInk,
  );

  static TextStyle uiButtonLight = GoogleFonts.nunito(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: PetalsColors.textCream,
  );
}
