import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/couple_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paper_widgets.dart';
import '../utils/paper_animations.dart';

class ChatScreen extends StatefulWidget {
  final CoupleModel couple;
  final String? myUid;

  const ChatScreen({
    super.key,
    required this.couple,
    this.myUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _isSending = false;
  bool _showEmojiDrawer = false;
  bool _isRecordingVoice = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  String get _myUid => _authService.currentUser?.uid ?? widget.myUid ?? '';
  String get _partnerName => widget.couple.partnerNameFor(_myUid);

  final List<String> _quickNotes = [
    '❤️ I Love You',
    '🌸 Thinking of You',
    '💌 Sending Hugs',
    '💋 Kisses',
    '✨ Miss You',
    '🌙 Good Night',
    '☕ Morning Coffee',
    '🎉 You Are Amazing',
  ];

  final List<String> _emojiStickers = [
    '❤️', '💖', '💕', '🌸', '💋', '💌', '🥰', '😍', 
    '😂', '🥳', '🌟', '🔥', '👍', '💯', '☕', '🎁',
    '🤗', '🥺', '🌹', '✨', '👑', '🌈', '🍦', '🧸',
  ];

  final List<String> _reactionEmojis = ['❤️', '💖', '😂', '😮', '😢', '👍', '🔥'];

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? customText, String? imageUrl]) async {
    final text = customText ?? _msgController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    if (customText == null && imageUrl == null) {
      _msgController.clear();
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isSending = true;
      _showEmojiDrawer = false;
    });

    try {
      await _chatService.sendMessage(
        coupleId: widget.couple.id,
        senderId: _myUid,
        text: text,
        imageUrl: imageUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message', style: GoogleFonts.outfit()),
            backgroundColor: PaperColors.roseCutout,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await _sendMessage('📷 Photo', base64Image);
    } catch (e) {
      debugPrint('Error picking chat photo: $e');
    }
  }

  void _toggleRecording() {
    HapticFeedback.mediumImpact();
    if (_isRecordingVoice) {
      // Stop & Send Voice Note
      _recordingTimer?.cancel();
      final durationStr = '0:${_recordingSeconds.toString().padLeft(2, '0')}';
      setState(() {
        _isRecordingVoice = false;
        _recordingSeconds = 0;
      });
      _sendMessage('🎙️ Voice Note ($durationStr)');
    } else {
      // Start Recording Simulation
      setState(() {
        _isRecordingVoice = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _recordingSeconds++);
      });
    }
  }

  void _showReactionMenu(MessageModel msg) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2825) : const Color(0xFFFCFAF7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white24 : PaperColors.stampBorder, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionEmojis.map((emoji) {
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _chatService.addReaction(
                    coupleId: widget.couple.id,
                    messageId: msg.id,
                    emoji: emoji,
                  );
                },
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _viewFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: imageUrl.startsWith('data:image')
                  ? Image.memory(base64Decode(imageUrl.split(',').last))
                  : Image.network(imageUrl),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? Colors.white : const Color(0xFF5A3E36);

    return PaperDioramaBackground(
      isDark: isDark,
      child: Scaffold(
        extendBody: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF161925).withValues(alpha: 0.95)
              : const Color(0xFFECE4D6).withValues(alpha: 0.95),
          surfaceTintColor: Colors.transparent,
          elevation: 2,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textCol),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE0636C),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Text(
                    _partnerName.isNotEmpty ? _partnerName[0].toUpperCase() : 'P',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _partnerName,
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Petals Love Notes 🌸',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : PaperColors.inkMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── 1. MESSAGES STREAM LIST ──
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _chatService.watchMessages(widget.couple.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: PaperColors.roseCutout),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_border_rounded, color: Color(0xFFE0636C), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No love notes yet',
                              style: GoogleFonts.caveat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Send a sweet paper note or photo to $_partnerName!',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == _myUid;

                        return _buildMessageBubble(msg, isMe, isDark);
                      },
                    );
                  },
                ),
              ),

              // ── 2. EMOJI & STICKER DRAWER (IF OPEN) ──
              if (_showEmojiDrawer)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 160,
                  color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF4EDE2),
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _emojiStickers.length,
                    itemBuilder: (context, index) {
                      final sticker = _emojiStickers[index];
                      return GestureDetector(
                        onTap: () => _sendMessage(sticker),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2B2E3A) : const Color(0xFFFCFAF7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2D8C6)),
                          ),
                          child: Center(
                            child: Text(sticker, style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ── 3. QUICK NOTES CHIP BAR ──
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _quickNotes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final note = _quickNotes[index];
                    return PaperChip(
                      label: note,
                      backgroundColor: isDark ? const Color(0xFF2C2624) : const Color(0xFFFAF6EE),
                      textColor: isDark ? const Color(0xFFF2C94C) : const Color(0xFFC54E5E),
                      onTap: () => _sendMessage(note),
                    );
                  },
                ),
              ),

              // ── 4. VOICE RECORDING BANNER (IF RECORDING) ──
              if (_isRecordingVoice)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFFED8891).withValues(alpha: 0.15),
                  child: Row(
                    children: [
                      const Icon(Icons.fiber_manual_record_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Recording Voice Note... 0:${_recordingSeconds.toString().padLeft(2, '0')}',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _recordingTimer?.cancel();
                          setState(() {
                            _isRecordingVoice = false;
                            _recordingSeconds = 0;
                          });
                        },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.nunito(color: isDark ? Colors.white70 : PaperColors.inkMedium),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── 5. INPUT BAR ANCHORED AT BOTTOM ──
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2028) : const Color(0xFFF4EDE2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    // Photo Upload Button 📷
                    IconButton(
                      icon: const Icon(Icons.photo_camera_rounded, color: Color(0xFFED8891), size: 22),
                      tooltip: 'Send Photo',
                      onPressed: _pickAndSendPhoto,
                    ),

                    // Emoji Drawer Toggle 😊
                    IconButton(
                      icon: Icon(
                        _showEmojiDrawer ? Icons.keyboard_hide_rounded : Icons.sentiment_satisfied_alt_rounded,
                        color: const Color(0xFFED8891),
                        size: 22,
                      ),
                      tooltip: 'Stickers & Emojis',
                      onPressed: () => setState(() => _showEmojiDrawer = !_showEmojiDrawer),
                    ),

                    // Text Field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2725) : const Color(0xFFFAF6EE),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? const Color(0xFF403C38) : const Color(0xFFE2D8C6),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _msgController,
                          style: GoogleFonts.outfit(
                            color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
                            fontSize: 14.5,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Write a note...',
                            hintStyle: GoogleFonts.outfit(
                              color: isDark ? Colors.white38 : PaperColors.inkMedium.withValues(alpha: 0.6),
                              fontSize: 13.5,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Voice Note Button 🎙️
                    IconButton(
                      icon: Icon(
                        _isRecordingVoice ? Icons.stop_circle_rounded : Icons.mic_rounded,
                        color: _isRecordingVoice ? Colors.redAccent : const Color(0xFF94A88B),
                        size: 24,
                      ),
                      tooltip: _isRecordingVoice ? 'Stop & Send Voice Note' : 'Record Voice Note',
                      onPressed: _toggleRecording,
                    ),

                    // Send Button 🚀
                    GestureDetector(
                      onTap: () => _sendMessage(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: PaperColors.roseCutout,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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

  Widget _buildMessageBubble(MessageModel msg, bool isMe, bool isDark) {
    final bubbleBg = isMe
        ? const Color(0xFFE0636C) // Rose Cutout for My Messages
        : (isDark ? const Color(0xFF2C2825) : const Color(0xFFFAF6EE)); // Paper Parchment for Partner

    final textColor = isMe
        ? Colors.white
        : (isDark ? const Color(0xFFFAF6EE) : const Color(0xFF2C2825));

    final timeColor = isMe
        ? Colors.white70
        : (isDark ? Colors.white38 : PaperColors.inkMedium.withValues(alpha: 0.7));

    final isVoiceNote = msg.text.startsWith('🎙️ Voice Note');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: () => _showReactionMenu(msg),
        onTap: () => _showReactionMenu(msg),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: Border.all(
                      color: isMe
                          ? const Color(0xFFC54E5E)
                          : (isDark ? const Color(0xFF403C38) : const Color(0xFFE2D8C6)),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Attachment (if present)
                      if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () => _viewFullScreenImage(msg.imageUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: msg.imageUrl!.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(msg.imageUrl!.split(',').last),
                                    fit: BoxFit.cover,
                                    height: 180,
                                    width: double.infinity,
                                  )
                                : Image.network(
                                    msg.imageUrl!,
                                    fit: BoxFit.cover,
                                    height: 180,
                                    width: double.infinity,
                                  ),
                          ),
                        ),
                        if (msg.text.isNotEmpty && msg.text != '📷 Photo') const SizedBox(height: 6),
                      ],

                      // Voice Note or Standard Text
                      if (msg.text.isNotEmpty && msg.text != '📷 Photo') ...[
                        if (isVoiceNote)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isMe ? Colors.white24 : const Color(0xFFED8891),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: isMe ? Colors.white : Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                msg.text,
                                style: GoogleFonts.outfit(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            msg.text,
                            style: GoogleFonts.outfit(
                              color: textColor,
                              fontSize: 14.5,
                              height: 1.3,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                // Emoji Reaction Badge on Bottom Right of Bubble (if present)
                if (msg.emojiReaction != null && msg.emojiReaction!.isNotEmpty)
                  Positioned(
                    bottom: -8,
                    right: isMe ? null : -6,
                    left: isMe ? -6 : null,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2825) : const Color(0xFFFCFAF7),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.white24 : PaperColors.stampBorder),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                      ),
                      child: Text(msg.emojiReaction!, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatTime(msg.createdAt),
                style: GoogleFonts.nunito(
                  fontSize: 10.5,
                  color: timeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

