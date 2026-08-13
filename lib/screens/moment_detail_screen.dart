import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/moment_model.dart';
import '../services/moment_service.dart';
import '../widgets/paper_widgets.dart';
import '../utils/paper_animations.dart';

class MomentDetailScreen extends StatefulWidget {
  final MomentModel moment;
  final String myUid;

  const MomentDetailScreen({
    super.key,
    required this.moment,
    required this.myUid,
  });

  @override
  State<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends State<MomentDetailScreen>
    with SingleTickerProviderStateMixin {
  final _momentService = MomentService();
  late bool _isLiked;
  late int _likesCount;
  late AnimationController _heartCtrl;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.moment.likedBy.contains(widget.myUid);
    _likesCount = widget.moment.likesCount;
    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount--;
      } else {
        _isLiked = true;
        _likesCount++;
        _heartCtrl.forward().then((_) => _heartCtrl.reverse());
      }
    });
    await _momentService.toggleLike(widget.moment.id, widget.myUid);
  }

  @override
  Widget build(BuildContext context) {
    final isMyPost = widget.moment.postedBy == widget.myUid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryInk = isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark;
    final secondaryInk = isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium;
    final elevatedCardBg = isDark ? PaperColors.darkCardElevated : const Color(0xFFEFE8DA);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? PaperColors.darkCard : const Color(0xFFFAF6EE)).withOpacity(0.9),
              border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFD4C4AE), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : PaperColors.inkDark, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: PaperMaskingTape(
          label: 'PAPER POLAROID',
          width: 140,
          rotationAngle: -0.02,
        ),
        centerTitle: true,
        actions: [
          if (isMyPost)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? PaperColors.darkCard : const Color(0xFFFAF6EE)).withOpacity(0.9),
                  border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFD4C4AE), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                  ],
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: PaperColors.pinRed, size: 18),
              ),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: PaperDioramaBackground(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              // ── 1. Paper Polaroid Framed Photo ──
              Expanded(
                child: PaperAnimations.applyPaperUnfold(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF23201D) : const Color(0xFFFAF6EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF403C38) : const Color(0xFFE2D8C6),
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(3, 8)),
                          BoxShadow(color: Colors.white10, blurRadius: 1, offset: Offset(-1, -1)),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Inner Photo Viewer with rounded photo cutout
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PhotoView(
                              imageProvider: widget.moment.imageUrl.startsWith('data:image')
                                  ? MemoryImage(base64Decode(widget.moment.imageUrl.split(',').last)) as ImageProvider
                                  : CachedNetworkImageProvider(widget.moment.imageUrl),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 3,
                              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                            ),
                          ),

                          // Decorative Masking Tape (Top Left Corner)
                          Positioned(
                            top: -10,
                            left: 16,
                            child: PaperMaskingTape(
                              label: 'MEMORIES',
                              width: 95,
                              rotationAngle: -0.06,
                            ),
                          ),

                          // Decorative Push Pin (Top Right Corner)
                          const Positioned(
                            top: -8,
                            right: 18,
                            child: PaperPushPin(color: PaperColors.pinRed),
                          ),
                        ],
                      ),
                    ),
                  ),
                  index: 0,
                ),
              ),

              // ── 2. Paper Note Bottom Container with Entrance Animation ──
              PaperAnimations.applyPaperUnfold(
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PaperCard(
                    margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                    rotationAngle: -0.008,
                    showTapeHeader: true,
                    tapeText: 'SCRAPBOOK NOTE',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // User Avatar badge with cut-out shadow
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                                boxShadow: PaperDepth.layerShadow(1),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: isMyPost ? PaperColors.roseCutout : PaperColors.sageCutout,
                                child: Text(
                                  widget.moment.postedByName.isNotEmpty
                                      ? widget.moment.postedByName[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMyPost ? 'You' : widget.moment.postedByName,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: primaryInk,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy · h:mm a').format(widget.moment.createdAt),
                                    style: GoogleFonts.patrickHand(
                                      fontSize: 13.5,
                                      color: secondaryInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Paper Heart Like Tag
                            GestureDetector(
                              onTap: _toggleLike,
                              child: AnimatedBuilder(
                                animation: _heartCtrl,
                                builder: (_, __) => Transform.scale(
                                  scale: 1.0 + _heartCtrl.value * 0.35,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: elevatedCardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? Colors.white12 : const Color(0xFFD4C4AE),
                                        width: 1.2,
                                      ),
                                      boxShadow: PaperDepth.layerShadow(1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: _isLiked ? PaperColors.roseCutout : secondaryInk,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$_likesCount',
                                          style: GoogleFonts.outfit(
                                            color: primaryInk,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.moment.caption.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1B19) : const Color(0xFFF6F0E6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE6D8C6),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.moment.caption,
                              style: GoogleFonts.caveat(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: primaryInk,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],


                      ],
                    ),
                  ),
                ),
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showPaperDialog(
      context: context,
      title: Text(
        'Delete Paper Moment?',
        style: GoogleFonts.caveat(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
        ),
      ),
      content: Text(
        'This will permanently unpin this moment from your scrapbook.',
        style: GoogleFonts.outfit(
          color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
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
          label: 'Unpin & Delete',
          color: PaperColors.pinRed,
          onPressed: () async {
            Navigator.pop(context);
            await _momentService.deleteMoment(
              widget.moment.id,
              widget.moment.imageUrl,
            );
            if (mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
