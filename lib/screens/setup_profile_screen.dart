import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_widgets.dart';

class SetupProfileScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onComplete;

  const SetupProfileScreen({
    super.key,
    required this.user,
    required this.onComplete,
  });

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _authService = AuthService();
  final _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;

  bool _isPrivate = false;
  String? _photoUrl;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _isPrivate = widget.user.isPrivate;
    _photoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  Future<void> _saveAndContinue() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await _authService
          .updateProfileSetup(
            uid: widget.user.uid,
            displayName: _nameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            isPrivate: _isPrivate,
            photoUrl: _photoUrl,
          )
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _skipSetup() async {
    try {
      await _authService.updateProfileSetup(
        uid: widget.user.uid,
        displayName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : widget.user.displayName,
        username: _usernameCtrl.text.trim().isNotEmpty ? _usernameCtrl.text.trim() : widget.user.username,
        bio: widget.user.bio,
        isPrivate: _isPrivate,
        photoUrl: _photoUrl,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile Setup',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
          ),
        ),
        actions: [
          // Skip for Now Button ⏩
          TextButton.icon(
            onPressed: _skipSetup,
            icon: Icon(
              Icons.fast_forward_rounded,
              size: 16,
              color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
            ),
            label: Text(
              'Skip for Now',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PaperDioramaBackground(
        isDark: isDark,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Intro Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? PaperColors.darkCard : const Color(0xFFFCFAF7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFD5C9B8),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(2, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: PaperColors.roseCutout,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Petals! 🌸',
                            style: GoogleFonts.caveat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                            ),
                          ),
                          Text(
                            'Set up your profile, privacy, and avatar. You can change these anytime!',
                            style: GoogleFonts.nunito(
                              fontSize: 12.5,
                              color: isDark ? Colors.white60 : PaperColors.inkMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.nunito(color: Colors.redAccent, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── 1. AVATAR PICKER ──
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PaperColors.roseCutout,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: ClipOval(
                          child: (_photoUrl != null && _photoUrl!.isNotEmpty)
                              ? Image.memory(
                                  base64Decode(_photoUrl!.split(',').last),
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                )
                              : Center(
                                  child: Text(
                                    _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'P',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 36,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: PaperColors.sageCutout,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 2. DISPLAY NAME ──
              Text(
                'Display Name',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : PaperColors.inkMedium,
                ),
              ),
              const SizedBox(height: 6),
              PaperTextField(
                controller: _nameCtrl,
                label: 'Display Name',
                hint: 'Your display name',
              ),

              const SizedBox(height: 16),

              // ── 3. USERNAME HANDLE ──
              Text(
                'Username Handle (@)',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : PaperColors.inkMedium,
                ),
              ),
              const SizedBox(height: 6),
              PaperTextField(
                controller: _usernameCtrl,
                label: 'Username',
                hint: 'e.g. yohesh.7509',
              ),

              const SizedBox(height: 16),

              // ── 4. ACCOUNT PRIVACY (Public vs Private) ──
              Text(
                'Account Privacy 🔒',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : PaperColors.inkMedium,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPrivate = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !_isPrivate
                              ? PaperColors.roseCutout
                              : (isDark ? const Color(0xFF272A32) : const Color(0xFFFCFAF7)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: !_isPrivate
                                ? PaperColors.roseCutout
                                : (isDark ? Colors.white12 : const Color(0xFFD5C9B8)),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              color: !_isPrivate ? Colors.white : (isDark ? Colors.white70 : PaperColors.inkDark),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Public Account 🌐',
                              style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: !_isPrivate ? Colors.white : (isDark ? Colors.white70 : PaperColors.inkDark),
                              ),
                            ),
                            Text(
                              'Appears in Suggested Friends',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: !_isPrivate ? Colors.white70 : (isDark ? Colors.white38 : PaperColors.inkLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPrivate = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isPrivate
                              ? PaperColors.roseCutout
                              : (isDark ? const Color(0xFF272A32) : const Color(0xFFFCFAF7)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isPrivate
                                ? PaperColors.roseCutout
                                : (isDark ? Colors.white12 : const Color(0xFFD5C9B8)),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: _isPrivate ? Colors.white : (isDark ? Colors.white70 : PaperColors.inkDark),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Private Account 🔒',
                              style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: _isPrivate ? Colors.white : (isDark ? Colors.white70 : PaperColors.inkDark),
                              ),
                            ),
                            Text(
                              'Hidden from public search',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                fontSize: 10,
                                color: _isPrivate ? Colors.white70 : (isDark ? Colors.white38 : PaperColors.inkLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── 5. BIO ──
              Text(
                'Personal Bio ✏️',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : PaperColors.inkMedium,
                ),
              ),
              const SizedBox(height: 6),
              PaperTextField(
                controller: _bioCtrl,
                label: 'Bio',
                hint: 'Write a sweet bio...',
              ),

              const SizedBox(height: 24),

              // ── 6. SAVE BUTTON ──
              SizedBox(
                width: double.infinity,
                child: PaperButton(
                  label: _isSaving ? 'Saving...' : 'Save & Continue 🌸',
                  color: PaperColors.roseCutout,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _saveAndContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
