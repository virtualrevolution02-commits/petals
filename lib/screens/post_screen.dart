import 'dart:io' show File;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/couple_model.dart';
import '../services/auth_service.dart';
import '../services/moment_service.dart';
import '../widgets/paper_widgets.dart';

class PostScreen extends StatefulWidget {
  final CoupleModel couple;
  final String? cachedUid;
  const PostScreen({super.key, required this.couple, this.cachedUid});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _authService = AuthService();
  final _momentService = MomentService();
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  String _mediaType = 'image'; // 'image' or 'video'
  Uint8List? _selectedMediaBytes;
  bool _isPosting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _mediaType = 'image';
        _selectedMediaBytes = bytes;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 10),
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _mediaType = 'video';
          _selectedMediaBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Video pick error: $e');
    }
  }

  Future<void> _post() async {
    if (_selectedMediaBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a photo or video first')));
      return;
    }
    setState(() => _isPosting = true);
    try {
      User? firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        try {
          firebaseUser = await FirebaseAuth.instance
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 8));
        } catch (_) {}
      }

      final uid = firebaseUser?.uid ?? widget.cachedUid ?? '';
      if (uid.isEmpty) {
        throw Exception('Not logged in. Please log out and sign in again.');
      }

      final userName = await _authService.getUserName();
      await _momentService.postMoment(
        coupleId: widget.couple.id,
        postedBy: uid,
        postedByName: userName,
        imageFile: _selectedMediaBytes!,
        caption: _captionController.text.trim(),
        mediaType: _mediaType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mediaType == 'video'
              ? 'Petals 10s Video moment pinned! 🎥🌸'
              : 'Petals Paper moment pinned! 🌸'),
          backgroundColor: PaperColors.roseCutout,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $msg'),
          backgroundColor: PaperColors.pinRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pin New Moment',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
          ),
        ),
        actions: [
          if (_selectedMediaBytes != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PaperButton(
                label: 'Pin',
                icon: Icons.push_pin_rounded,
                color: PaperColors.roseCutout,
                isLoading: _isPosting,
                onPressed: _isPosting ? null : _post,
              ),
            ),
        ],
      ),
      body: PaperDioramaBackground(
        isDark: isDark,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Media Type Picker (Photo 📸 vs 10s Video 🎥)
              Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262934) : const Color(0xFFE6D8C6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mediaType = 'image'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _mediaType == 'image' ? PaperColors.roseCutout : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_camera_rounded, size: 15, color: _mediaType == 'image' ? Colors.white : (isDark ? Colors.white60 : PaperColors.inkMedium)),
                                const SizedBox(width: 4),
                                Text('Photo', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: _mediaType == 'image' ? Colors.white : (isDark ? Colors.white60 : PaperColors.inkMedium))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mediaType = 'video'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _mediaType == 'video' ? PaperColors.roseCutout : Colors.transparent,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_rounded, size: 15, color: _mediaType == 'video' ? Colors.white : (isDark ? Colors.white60 : PaperColors.inkMedium)),
                                const SizedBox(width: 4),
                                Text('10s Video', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: _mediaType == 'video' ? Colors.white : (isDark ? Colors.white60 : PaperColors.inkMedium))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Media Frame (Photo or Video preview)
              GestureDetector(
                onTap: _showMediaSourceSheet,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PaperPhotoFrame(imageBytes: _selectedMediaBytes),
                    if (_mediaType == 'video' && _selectedMediaBytes != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                      ),
                  ],
                ),
              ),

              if (_selectedMediaBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PaperChip(
                        label: _mediaType == 'video' ? 'Record 10s Video' : 'Take Photo',
                        icon: _mediaType == 'video' ? Icons.videocam_rounded : Icons.camera_alt_rounded,
                        backgroundColor: PaperColors.sageCutout,
                        textColor: Colors.white,
                        onTap: () => _mediaType == 'video' ? _pickVideo(ImageSource.camera) : _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 10),
                      PaperChip(
                        label: 'Choose Gallery',
                        icon: Icons.photo_library_rounded,
                        backgroundColor: PaperColors.darkCardElevated,
                        textColor: PaperColors.darkInkPrimary,
                        onTap: () => _mediaType == 'video' ? _pickVideo(ImageSource.gallery) : _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              const SizedBox(height: 16),

              // Handwritten Caption Label & Input
              Text(
                'Handwritten Caption',
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                ),
              ),
              const SizedBox(height: 6),
              PaperTextFieldCustom(controller: _captionController),
              const SizedBox(height: 14),

              // Paper Cutout Live Widget Section
              const PaperCutoutWidget(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? PaperColors.darkCard : const Color(0xFFFCFAF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _mediaType == 'video' ? 'Select 10s Video Source' : 'Select Photo Source',
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceButton(
                    icon: _mediaType == 'video' ? Icons.videocam_rounded : Icons.camera_alt_rounded,
                    label: _mediaType == 'video' ? 'Record 10s' : 'Camera',
                    color: PaperColors.roseCutout,
                    onTap: () {
                      Navigator.pop(context);
                      if (_mediaType == 'video') {
                        _pickVideo(ImageSource.camera);
                      } else {
                        _pickImage(ImageSource.camera);
                      }
                    },
                  ),
                  _SourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: PaperColors.skyCutout,
                    onTap: () {
                      Navigator.pop(context);
                      if (_mediaType == 'video') {
                        _pickVideo(ImageSource.gallery);
                      } else {
                        _pickImage(ImageSource.gallery);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 28)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.caveat(fontSize: 16)),
        ],
      ),
    );
  }
}

// 1. Multi-layered Paper Photo Frame
class PaperPhotoFrame extends StatelessWidget {
  final Uint8List? imageBytes;
  final File? selectedImage;
  const PaperPhotoFrame({super.key, this.imageBytes, this.selectedImage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom Paper Layer (Rotation Effect)
          Transform.rotate(
            angle: -0.03,
            child: Container(
              width: double.infinity,
              height: 295,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E3D5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
            ),
          ),
          // Top Main Paper Layer
          Container(
            width: double.infinity,
            height: 295,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EB), // Cream Paper Color
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                )
              ],
            ),
            child: (imageBytes != null || selectedImage != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.file(
                            selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular Paper Button
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8B2B5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Mount Photo onto Paper Frame',
                        style: GoogleFonts.caveat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A4A4A),
                        ),
                      ),
                      Text(
                        'Camera or Gallery',
                        style: GoogleFonts.caveat(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tap to mount photo',
                            style: GoogleFonts.caveat(
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'TODAY',
                            style: GoogleFonts.caveat(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
          ),
          // Top Left MEMO Tape/Sticker
          Positioned(
            top: -10,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD4C59E),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                  )
                ],
              ),
              child: Text(
                'MEMO',
                style: GoogleFonts.caveat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xB3000000),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// 2. Paper Texture Styled Input Field
class PaperTextFieldCustom extends StatelessWidget {
  final TextEditingController controller;
  const PaperTextFieldCustom({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFAF6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFD8CEBE)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.caveat(fontSize: 18, color: isDark ? Colors.white : const Color(0xFF2C241B)),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.edit_note, color: Colors.pinkAccent),
          hintText: 'Captured a sweet moment today... 🌸',
          hintStyle: GoogleFonts.caveat(color: isDark ? Colors.white38 : const Color(0xFF8C7D6B), fontSize: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// 3. Live Widget Paper Banner Section
class PaperCutoutWidget extends StatelessWidget {
  const PaperCutoutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D3227) : const Color(0xFFE5ECCB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFC0CD9F)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC7B88B),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'LIVE WIDGET',
                  style: GoogleFonts.caveat(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.widgets_outlined, color: Colors.amber),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "This paper moment will instantly update your partner's home screen widget!",
                      style: GoogleFonts.caveat(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : const Color(0xFF3B4434),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
