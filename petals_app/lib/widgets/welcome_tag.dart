// The "WELCOME" kraft-paper luggage tag pinned to the card's top-left
// corner.

import 'package:flutter/material.dart';
import '../theme/petals_theme.dart';

class WelcomeTag extends StatelessWidget {
  const WelcomeTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.07,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 8, 14, 8),
        decoration: BoxDecoration(
          color: PetalsColors.tagKraft,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: PetalsColors.bgNavy.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
            Text('WELCOME', style: PetalsText.tagLabel),
          ],
        ),
      ),
    );
  }
}
