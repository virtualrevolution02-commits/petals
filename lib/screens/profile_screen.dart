import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/couple_model.dart';
import '../models/user_model.dart';
import '../models/moment_model.dart';
import '../services/auth_service.dart';
import '../services/moment_service.dart';
import '../widgets/paper_widgets.dart';
import '../utils/paper_animations.dart';
import 'chat_screen.dart';
import 'moment_detail_screen.dart';
import 'settings_screen.dart';
import 'pairing_screen.dart';
import 'post_screen.dart';
import 'messages_screen.dart';

class ProfileScreen extends StatefulWidget {
  final CoupleModel couple;
  final String myUid;
  final bool hideBottomDock;

  const ProfileScreen({
    super.key,
    required this.couple,
    required this.myUid,
    this.hideBottomDock = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _momentService = MomentService();
  final _picker = ImagePicker();
  late TabController _tabController;

  UserModel? _userModel;
  List<MomentModel> _allMoments = [];
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getUserProfile(widget.myUid);
    if (!mounted) return;
    setState(() {
      _userModel = user;
      _isLoading = false;
    });
  }

  void _copyTicketCode() {
    if (_userModel == null) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _userModel!.username));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Ticket code @${_userModel!.username} copied!'),
          ],
        ),
        backgroundColor: PaperColors.roseCutout,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);
      final bytes = await picked.readAsBytes();
      final photoUrl = await _momentService.uploadImage(bytes, widget.couple.id);

      await _authService.updateUserPhotoUrl(photoUrl);

      if (!mounted) return;
      setState(() {
        if (_userModel != null) {
          _userModel = UserModel(
            uid: _userModel!.uid,
            email: _userModel!.email,
            displayName: _userModel!.displayName,
            username: _userModel!.username,
            photoUrl: photoUrl,
            coupleId: _userModel!.coupleId,
            bio: _userModel!.bio,
            ticketButtonLabel: _userModel!.ticketButtonLabel,
            createdAt: _userModel!.createdAt,
          );
        }
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile photo updated! 🌸'),
          backgroundColor: PaperColors.roseCutout,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: PaperColors.pinRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      setState(() => _isUploadingPhoto = true);
      await _authService.updateUserPhotoUrl('');

      if (!mounted) return;
      setState(() {
        if (_userModel != null) {
          _userModel = UserModel(
            uid: _userModel!.uid,
            email: _userModel!.email,
            displayName: _userModel!.displayName,
            username: _userModel!.username,
            photoUrl: '',
            coupleId: _userModel!.coupleId,
            bio: _userModel!.bio,
            ticketButtonLabel: _userModel!.ticketButtonLabel,
            createdAt: _userModel!.createdAt,
          );
        }
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile photo removed!'),
          backgroundColor: PaperColors.sageCutout,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showProfileImageSourceSheet() {
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
                  color: isDark
                      ? PaperColors.darkInkSecondary.withOpacity(0.3)
                      : PaperColors.inkMedium.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Profile Photo',
                style: GoogleFonts.caveat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: PaperButton(
                      label: 'Camera',
                      icon: Icons.camera_alt_rounded,
                      color: PaperColors.roseCutout,
                      onPressed: () {
                        Navigator.pop(context);
                        _pickProfileImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PaperButton(
                      label: 'Gallery',
                      icon: Icons.photo_library_rounded,
                      color: PaperColors.sageCutout,
                      onPressed: () {
                        Navigator.pop(context);
                        _pickProfileImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              if (_userModel?.photoUrl != null && _userModel!.photoUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: PaperColors.pinRed, size: 18),
                  label: Text(
                    'Remove Current Photo',
                    style: GoogleFonts.outfit(color: PaperColors.pinRed, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editBio() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: _userModel?.bio ?? '');
    showPaperDialog(
      context: context,
      title: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: PaperColors.roseCutout, size: 24),
          const SizedBox(width: 8),
          Text(
            'Edit Bio',
            style: GoogleFonts.caveat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
            ),
          ),
        ],
      ),
      content: PaperTextField(
        controller: ctrl,
        label: 'Custom Bio',
        hint: 'Write your story...',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(
              color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
            ),
          ),
        ),
        PaperButton(
          label: 'Save Bio',
          color: PaperColors.roseCutout,
          onPressed: () async {
            final newBio = ctrl.text.trim();
            await _authService.updateUserBio(newBio);
            if (!mounted) return;
            setState(() {
              _userModel = UserModel(
                uid: _userModel!.uid,
                email: _userModel!.email,
                displayName: _userModel!.displayName,
                username: _userModel!.username,
                photoUrl: _userModel!.photoUrl,
                coupleId: _userModel!.coupleId,
                bio: newBio,
                ticketButtonLabel: _userModel!.ticketButtonLabel,
                createdAt: _userModel!.createdAt,
              );
            });
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _editTicketButtonLabel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(
        text: _userModel?.ticketButtonLabel ?? 'Copy Ticket Code');
    showPaperDialog(
      context: context,
      title: Row(
        children: [
          const Icon(Icons.push_pin_rounded, color: PaperColors.goldCutout, size: 22),
          const SizedBox(width: 8),
          Text(
            'Customize Button Label',
            style: GoogleFonts.caveat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
            ),
          ),
        ],
      ),
      content: PaperTextField(
        controller: ctrl,
        label: 'Button Label Text',
        hint: 'e.g. Copy Ticket Code',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(
              color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
            ),
          ),
        ),
        PaperButton(
          label: 'Save Label',
          color: PaperColors.sageCutout,
          onPressed: () async {
            final newLabel = ctrl.text.trim();
            if (newLabel.isEmpty) return;
            await _authService.updateTicketButtonLabel(newLabel);
            if (!mounted) return;
            setState(() {
              _userModel = UserModel(
                uid: _userModel!.uid,
                email: _userModel!.email,
                displayName: _userModel!.displayName,
                username: _userModel!.username,
                photoUrl: _userModel!.photoUrl,
                coupleId: _userModel!.coupleId,
                bio: _userModel!.bio,
                ticketButtonLabel: newLabel,
                createdAt: _userModel!.createdAt,
              );
            });
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showEditUsernameDialog() {
    final nameCtrl = TextEditingController(text: _userModel?.displayName ?? '');
    final usernameCtrl = TextEditingController(text: _userModel?.username ?? '');
    String? dialogError;
    bool isSaving = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? PaperColors.darkCard : const Color(0xFFFCFAF7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isDark ? Colors.white24 : PaperColors.stampBorder, width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: PaperColors.roseCutout, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: GoogleFonts.caveat(
                    color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        dialogError!,
                        style: GoogleFonts.nunito(color: Colors.redAccent, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'Display Name',
                    style: GoogleFonts.nunito(
                      color: isDark ? Colors.white70 : PaperColors.inkMedium,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PaperTextField(
                    controller: nameCtrl,
                    label: 'Name',
                    hint: 'Your display name',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Username Handle (@)',
                    style: GoogleFonts.nunito(
                      color: isDark ? Colors.white70 : PaperColors.inkMedium,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PaperTextField(
                    controller: usernameCtrl,
                    label: 'Username',
                    hint: 'e.g. yohesh.7509',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.outfit(
                    color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
                  ),
                ),
              ),
              PaperButton(
                label: isSaving ? 'Saving...' : 'Save Profile',
                color: PaperColors.roseCutout,
                onPressed: isSaving
                    ? null
                    : () async {
                        final newName = nameCtrl.text.trim();
                        final newUsername = usernameCtrl.text.trim();
                        if (newName.isEmpty || newUsername.isEmpty) {
                          setDialogState(() => dialogError = 'Fields cannot be empty');
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        try {
                          await _authService.updateProfile(
                            displayName: newName,
                            username: newUsername,
                          );
                          if (!mounted) return;
                          await _loadProfileData();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully! 🌸'),
                              backgroundColor: PaperColors.sageCutout,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            dialogError = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF161925) : const Color(0xFFECE4D6);
    final textCol = isDark ? Colors.white : const Color(0xFF2C241B);

    final cardBg = isDark ? const Color(0xFF2F323D) : const Color(0xFFFAF6EE);
    final cardBorder = isDark ? const Color(0xFF424654) : const Color(0xFFE2D8C6);
    final slotBg = isDark ? const Color(0xFF1E2028) : const Color(0xFFF0E8DA);
    final slotBorder = isDark ? const Color(0xFF15171F) : const Color(0xFFDCD0BC);
    final nameColor = isDark ? const Color(0xFFFAF6EE) : PaperColors.inkDark;
    final handleColor = isDark ? const Color(0xFFB0B4C0) : PaperColors.inkMedium;
    final tuneBtnBg = isDark ? const Color(0xFF382430) : const Color(0xFFFCE8EB);
    final tabBg = isDark ? const Color(0xFF2F323D) : const Color(0xFFFAF6EE);
    final tabBorder = isDark ? const Color(0xFF424654) : const Color(0xFFE2D8C6);
    final tabUnselectedColor = isDark ? const Color(0xFFB0B4C0) : PaperColors.inkMedium;

    return PaperDioramaBackground(
      isDark: isDark,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textCol),
            onPressed: () => Navigator.pop(context),
          ),
        title: Text(
          _userModel?.displayName ?? 'yohesh',
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: textCol),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(couple: widget.couple),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<MomentModel>>(
        stream: _momentService.watchMoments(widget.couple.id),
        builder: (context, snapshot) {
          _allMoments = snapshot.data ?? [];
          final myMoments = _allMoments.where((m) => m.postedBy == widget.myUid).toList();
          final savedMemories = _allMoments.where((m) => m.likedBy.contains(widget.myUid)).toList();

          int totalPetals = 0;
          for (var m in myMoments) {
            totalPetals += m.likesCount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Profile Card (Hyper-Accurate Ref Image Match)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder, width: 1.5),
                          boxShadow: isDark
                              ? const [BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 8))]
                              : PaperDepth.layerShadow(2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            // Header Row: Avatar + Stats Pill Box
                             Row(
                              children: [
                                // 3D Circular Avatar with Camera Edit Badge & Photo Support
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: _showProfileImageSourceSheet,
                                      child: Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFE0636C),
                                          border: Border.all(color: const Color(0xFFE9E0CE), width: 3),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
                                          ],
                                        ),
                                        child: _isUploadingPhoto
                                            ? const Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                      color: Colors.white, strokeWidth: 2.5),
                                                ),
                                              )
                                            : ClipOval(
                                                child: (_userModel?.photoUrl != null &&
                                                        _userModel!.photoUrl!.isNotEmpty)
                                                    ? (_userModel!.photoUrl!.startsWith('data:image')
                                                        ? Image.memory(
                                                            base64Decode(
                                                                _userModel!.photoUrl!.split(',').last),
                                                            fit: BoxFit.cover,
                                                            width: 76,
                                                            height: 76,
                                                          )
                                                        : CachedNetworkImage(
                                                            imageUrl: _userModel!.photoUrl!,
                                                            fit: BoxFit.cover,
                                                            width: 76,
                                                            height: 76,
                                                            placeholder: (_, __) => Container(
                                                              color: const Color(0xFFE0636C),
                                                              child: const Center(
                                                                child: CircularProgressIndicator(
                                                                    color: Colors.white,
                                                                    strokeWidth: 2),
                                                              ),
                                                            ),
                                                            errorWidget: (_, __, ___) => Center(
                                                              child: Text(
                                                                _userModel?.displayName.isNotEmpty == true
                                                                    ? _userModel!.displayName[0]
                                                                        .toUpperCase()
                                                                    : 'Y',
                                                                style: GoogleFonts.outfit(
                                                                  color: const Color(0xFFFAF6EE),
                                                                  fontWeight: FontWeight.w900,
                                                                  fontSize: 30,
                                                                ),
                                                              ),
                                                            ),
                                                          ))
                                                    : Center(
                                                        child: Text(
                                                          _userModel?.displayName.isNotEmpty == true
                                                              ? _userModel!.displayName[0].toUpperCase()
                                                              : 'Y',
                                                          style: GoogleFonts.outfit(
                                                            color: const Color(0xFFFAF6EE),
                                                            fontWeight: FontWeight.w900,
                                                            fontSize: 30,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: GestureDetector(
                                        onTap: _showProfileImageSourceSheet,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: PaperColors.roseCutout,
                                            border: Border.all(color: Colors.white, width: 1.5),
                                            boxShadow: const [
                                              BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 3,
                                                  offset: Offset(0, 2)),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Sunken Dark/Light Stats Box with Bevel Effect
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: slotBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: slotBorder, width: 1.5),
                                      boxShadow: isDark
                                          ? const [BoxShadow(color: Colors.black87, blurRadius: 6, spreadRadius: -1, offset: Offset(0, 3))]
                                          : const [BoxShadow(color: Color(0x1A352E28), blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _StatItem(
                                          count: '$totalPetals',
                                          label: 'Petals',
                                          icon: Icons.local_florist_rounded,
                                        ),
                                        _StatItem(
                                          count: '${myMoments.length}',
                                          label: 'Moments',
                                          icon: Icons.grid_view_rounded,
                                        ),
                                        _StatItem(
                                          count: '${savedMemories.length}',
                                          label: 'Memories',
                                          icon: Icons.collections_bookmark_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // User Name & Handle (Tap to Edit Profile)
                            GestureDetector(
                              onTap: _showEditUsernameDialog,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _userModel?.displayName ?? 'yohesh',
                                            style: GoogleFonts.caveat(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: nameColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFED8891)),
                                        ],
                                      ),
                                      Text(
                                        '@${_userModel?.username ?? 'daisy.yohesh.7509'}',
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          color: handleColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bio Box (Editable Pill Bar)
                            GestureDetector(
                              onTap: _editBio,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: slotBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: slotBorder, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _userModel?.bio.isNotEmpty == true
                                            ? _userModel!.bio
                                            : 'Capturing sweet paper moments together 💕',
                                        style: GoogleFonts.caveat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: nameColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.edit_rounded, size: 18, color: Color(0xFFE0636C)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pinned Top-Left Kraft Tape Tag
                      Positioned(
                        top: -10,
                        left: 14,
                        child: Transform.rotate(
                          angle: -0.04,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6D8BA),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2)),
                              ],
                            ),
                            child: Text(
                              'SCRAPBOOK P...',
                              style: GoogleFonts.caveat(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5A4D3B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top Right 3D Paper Butterfly Accent
                      Positioned(
                        top: -12,
                        right: 8,
                        child: Transform.rotate(
                          angle: 0.15,
                          child: const Icon(
                            Icons.flutter_dash_rounded,
                            color: Color(0xFFED9BA6),
                            size: 26,
                          ),
                        ),
                      ),

                      // Right Side Paper Leaf Accent
                      Positioned(
                        top: 55,
                        right: -8,
                        child: Transform.rotate(
                          angle: -0.2,
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Color(0xFF86A07E),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Connect with Partner Strip (Wavy Pink Match)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PairingScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAD4D8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8949E), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE0636C),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 2)),
                              ],
                            ),
                            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connect with Partner',
                                  style: GoogleFonts.caveat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF8A2E3B),
                                  ),
                                ),
                                Text(
                                  'Tap to open the ticket pairing screen!',
                                  style: GoogleFonts.patrickHand(
                                    fontSize: 13,
                                    color: const Color(0xFF9E4250),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A2E3B), size: 24),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Moments vs Memories Dual-Tab Switcher
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: tabBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tabBorder, width: 1.5),
                      boxShadow: isDark
                          ? const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))]
                          : PaperDepth.layerShadow(1),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFE0636C),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                        ],
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: tabUnselectedColor,
                      labelStyle: GoogleFonts.caveat(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.grid_view_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Moments'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.collections_bookmark_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Memories'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Moments Grid
                        _buildMomentsGrid(myMoments),
                        // Tab 2: Memories Grid
                        _buildMemoriesGrid(savedMemories),
                      ],
                    ),
                  ),
                ],
              ),
            );
        },
      ),
      bottomNavigationBar: widget.hideBottomDock
          ? null
          : PaperBottomDock(
              currentIndex: 2,
              onHomeTap: () => Navigator.popUntil(context, (route) => route.isFirst),
              onChatTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(
                  context,
                  PaperPageRoute(
                    builder: (_) => MessagesScreen(couple: widget.couple, myUid: widget.myUid),
                  ),
                );
              },
              onProfileTap: () {},
              onSettingsTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(
                  context,
                  PaperPageRoute(
                    builder: (_) => SettingsScreen(couple: widget.couple),
                  ),
                );
              },
            ),
    ),
  );
}

  Widget _buildMomentsGrid(List<MomentModel> moments) {
    if (moments.isEmpty) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: const Color(0xFF21232B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF323542), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Red Paper Cut Emblem
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF282A32),
                    border: Border.all(color: const Color(0xFFE0636C), width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.grid_off_rounded, color: Color(0xFFE0636C), size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  'No Uploaded Moments',
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Capture your first memory to populate your profile grid!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          // Pinned Top-Left Tag
          Positioned(
            top: 0,
            left: 14,
            child: Transform.rotate(
              angle: -0.04,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEADBCA),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2)),
                  ],
                ),
                child: Text(
                  'SCRAPBOOK P...',
                  style: GoogleFonts.caveat(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E3427),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          // Top Right Red Pin Button
          Positioned(
            top: 2,
            right: 18,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFE0636C),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 2))],
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    const rotations = [-0.02, 0.015, -0.01, 0.02, -0.015];
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: moments.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final m = moments[index];
        final rot = rotations[index % rotations.length];
        return PaperPhotoTile(
          rotationAngle: rot,
          showTape: (index % 2 == 0),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MomentDetailScreen(
                moment: m,
                myUid: widget.myUid,
              ),
            ),
          ),
          child: m.imageUrl.startsWith('data:image')
              ? Image.memory(
                  base64Decode(m.imageUrl.split(',').last),
                  fit: BoxFit.cover,
                )
              : CachedNetworkImage(
                  imageUrl: m.imageUrl,
                  fit: BoxFit.cover,
                  memCacheHeight: 300,
                  placeholder: (_, __) => const PaperLoadingPlaceholder(borderRadius: 4),
                  errorWidget: (_, __, ___) => Container(
                    color: PaperColors.kraftPaper,
                    child: const Icon(Icons.broken_image_outlined, color: PaperColors.inkMedium),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildMemoriesGrid(List<MomentModel> memories) {
    if (memories.isEmpty) {
      return PaperEmptyState(
        title: 'No Saved Memories',
        subtitle: 'Heart couple moments on the main feed to pin them here!',
        icon: Icons.favorite_border_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final m = memories[index];
        return PaperPolaroid(
          rotationAngle: (index % 2 == 0) ? -0.015 : 0.015,
          caption: m.caption.isNotEmpty ? m.caption : 'Liked Memory',
          dateText: DateFormat('MMM d').format(m.createdAt),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MomentDetailScreen(
                moment: m,
                myUid: widget.myUid,
              ),
            ),
          ),
          child: m.imageUrl.startsWith('data:image')
              ? Image.memory(
                  base64Decode(m.imageUrl.split(',').last),
                  fit: BoxFit.cover,
                )
              : CachedNetworkImage(
                  imageUrl: m.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const PaperLoadingPlaceholder(borderRadius: 0),
                  errorWidget: (_, __, ___) => Container(
                    color: PaperColors.kraftPaper,
                    child: const Icon(Icons.broken_image_outlined, color: PaperColors.inkMedium),
                  ),
                ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.count,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countColor = isDark ? const Color(0xFFFAF6EE) : PaperColors.inkDark;
    final labelColor = isDark ? const Color(0xFFB0B4C0) : PaperColors.inkMedium;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: countColor,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFFE0636C)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.caveat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
