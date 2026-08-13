// Petals — Welcome (Sign In / Register) screen.
//
// A paper-craft / felt scrapbook page: hand-torn card edges, a stitched
// kraft tag, cascading paper hearts and leaves, a folded origami crane,
// and a felt-toned primary button — all built from CustomPainters, so no
// image assets are required to run this screen.

import 'package:flutter/material.dart';

import '../painters/paper_painters.dart';
import '../theme/petals_theme.dart';
import '../widgets/welcome_tag.dart';

class PetalsWelcomeScreen extends StatefulWidget {
  const PetalsWelcomeScreen({
    super.key,
    this.onGoogleSignIn,
    this.onSignIn,
    this.onRegister,
  });

  /// Called when "Continue with Google" is tapped.
  final VoidCallback? onGoogleSignIn;

  /// Called with (email, password) when the primary button is tapped
  /// while the "Sign In" tab is active.
  final void Function(String email, String password)? onSignIn;

  /// Called with (email, password) when the primary button is tapped
  /// while the "Register" tab is active.
  final void Function(String email, String password)? onRegister;

  @override
  State<PetalsWelcomeScreen> createState() => _PetalsWelcomeScreenState();
}

class _PetalsWelcomeScreenState extends State<PetalsWelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignIn = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handlePrimaryTap() {
    final email = _emailController.text;
    final password = _passwordController.text;
    if (_isSignIn) {
      widget.onSignIn?.call(email, password);
    } else {
      widget.onRegister?.call(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetalsColors.bgNavy,
      body: Stack(
        children: [
          _backgroundDecor(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 34),
                  _tornCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundDecor() {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: -10,
            child: SizedBox(
              width: 130,
              height: 70,
              child: CustomPaint(painter: PaperCloudPainter()),
            ),
          ),
          Positioned(
            top: 90,
            left: 100,
            child: SizedBox(
              width: 70,
              height: 40,
              child: CustomPaint(painter: PaperCloudPainter()),
            ),
          ),
          Positioned(
            top: 60,
            right: -10,
            child: SizedBox(
              width: 150,
              height: 80,
              child: CustomPaint(painter: PaperCloudPainter()),
            ),
          ),
          Positioned(
            top: 150,
            right: 60,
            child: SizedBox(
              width: 60,
              height: 34,
              child: CustomPaint(painter: PaperCloudPainter()),
            ),
          ),
          Positioned(
            top: 30,
            left: 150,
            child: SizedBox(
              width: 14,
              height: 14,
              child: CustomPaint(painter: SparkleStarPainter()),
            ),
          ),
          Positioned(
            top: 130,
            left: 210,
            child: SizedBox(
              width: 10,
              height: 10,
              child: CustomPaint(painter: SparkleStarPainter()),
            ),
          ),
          Positioned(
            top: 60,
            right: 140,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CustomPaint(painter: SparkleStarPainter()),
            ),
          ),
          Positioned(
            top: 20,
            right: 210,
            child: SizedBox(
              width: 12,
              height: 12,
              child: CustomPaint(painter: SparkleStarPainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF2D9CE),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEFC0C7),
            ),
            child: const CustomPaint(painter: FlowerLogoPainter()),
          ),
        ),
        const SizedBox(height: 18),
        Text('petals', style: PetalsText.wordmark),
        const SizedBox(height: 4),
        Text('handcrafted couple scrapbook', style: PetalsText.tagline),
      ],
    );
  }

  Widget _tornCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Kraft-paper backing, offset behind the cream page.
        Positioned(
          left: 6,
          top: 6,
          right: -6,
          bottom: -6,
          child: ClipPath(
            clipper: const TornPaperClipper(jag: 9),
            child: Container(color: PetalsColors.cardKraftEdge),
          ),
        ),
        // The cream scrapbook page itself — sizes the Stack.
        PhysicalShape(
          clipper: const TornPaperClipper(jag: 8),
          color: PetalsColors.cardCream,
          elevation: 14,
          shadowColor: Colors.black,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 42, 26, 34),
            child: _cardContent(),
          ),
        ),
        const Positioned(top: -14, left: 8, child: WelcomeTag()),
        Positioned(
          top: -86,
          right: 18,
          child: SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(painter: OrigamiCranePainter()),
          ),
        ),
        Positioned(top: -20, right: 46, child: _heart(24, -0.4)),
        Positioned(top: 20, right: 18, child: _heart(32, 0.3)),
        Positioned(top: 62, right: 50, child: _heart(28, -0.2)),
      ],
    );
  }

  Widget _heart(double size, double angle) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: PaperHeartPainter()),
      ),
    );
  }

  Widget _cardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _googleButton(),
        const SizedBox(height: 22),
        _orEmailDivider(),
        const SizedBox(height: 18),
        _tabSwitcher(),
        const SizedBox(height: 22),
        Text('Email Address', style: PetalsText.handwritten),
        const SizedBox(height: 8),
        _PaperInputField(
          controller: _emailController,
          hint: 'your.email@example.com',
          icon: Icons.mail_outline,
        ),
        const SizedBox(height: 20),
        Text('Password', style: PetalsText.handwritten),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _PaperInputField(
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              trailing: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: PetalsColors.textCream.withOpacity(0.7),
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            Positioned(
              top: -6,
              right: -10,
              child: Transform.rotate(
                angle: 0.3,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(painter: PaperLeafPainter()),
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              right: 30,
              child: Transform.rotate(
                angle: -0.5,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CustomPaint(painter: PaperLeafPainter()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        _signInButton(),
        const SizedBox(height: 18),
        _bottomStitching(),
      ],
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: widget.onGoogleSignIn,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7EC),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: PetalsColors.textInk.withOpacity(0.25),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: GoogleMarkPainter()),
            ),
            const SizedBox(width: 12),
            Text('Continue with Google', style: PetalsText.uiButton),
          ],
        ),
      ),
    );
  }

  Widget _orEmailDivider() {
    final line = Divider(color: PetalsColors.textInk.withOpacity(0.35));
    return Row(
      children: [
        Expanded(child: line),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or email', style: PetalsText.handwritten),
        ),
        Expanded(child: line),
      ],
    );
  }

  Widget _tabSwitcher() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PetalsColors.bgNavy,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: 'Sign In',
              active: _isSignIn,
              onTap: () => setState(() => _isSignIn = true),
            ),
          ),
          Expanded(
            child: _tabButton(
              label: 'Register',
              active: !_isSignIn,
              onTap: () => setState(() => _isSignIn = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? PetalsColors.accentCoral : Colors.transparent,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Text(
          label,
          style: active
              ? PetalsText.uiButtonLight
              : PetalsText.uiButtonLight.copyWith(
                  color: PetalsColors.textCream.withOpacity(0.6),
                ),
        ),
      ),
    );
  }

  Widget _signInButton() {
    return GestureDetector(
      onTap: _handlePrimaryTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [PetalsColors.accentCoral, PetalsColors.accentCoralDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: PetalsColors.accentCoralDeep, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, color: PetalsColors.textCream, size: 20),
            const SizedBox(width: 10),
            Text(
              _isSignIn ? 'Sign In' : 'Create Account',
              style: PetalsText.uiButtonLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomStitching() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(
          width: 80,
          height: 16,
          child: CustomPaint(painter: StitchPainter()),
        ),
        Transform.rotate(
          angle: 0.15,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CustomPaint(painter: PaperHeartPainter()),
          ),
        ),
      ],
    );
  }
}

/// A recessed, taupe scrapbook-window text field with a coral leading
/// icon and handwritten hint text.
class _PaperInputField extends StatelessWidget {
  const _PaperInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PetalsColors.fieldTaupe,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: PetalsText.handwritten.copyWith(color: PetalsColors.textCream),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          prefixIcon: Icon(icon, color: PetalsColors.accentCoral, size: 20),
          suffixIcon: trailing,
          hintText: hint,
          hintStyle: PetalsText.handwritten.copyWith(
            color: PetalsColors.textCream.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
