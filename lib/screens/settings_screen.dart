import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/couple_model.dart';
import '../services/auth_service.dart';
import '../widgets/paper_widgets.dart';
import '../utils/paper_animations.dart';
import 'pairing_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'post_screen.dart';
import 'messages_screen.dart';

class SettingsScreen extends StatefulWidget {
  final CoupleModel couple;
  final bool hideBottomDock;
  const SettingsScreen({
    super.key,
    required this.couple,
    this.hideBottomDock = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await _authService.getUserName();
    if (mounted) setState(() => _myName = name);
  }

  String get _partnerName =>
      widget.couple.partnerNameFor(_authService.currentUser?.uid ?? '');

  Future<void> _signOut() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showPaperDialog<bool>(
      context: context,
      title: Row(
        children: [
          const Icon(Icons.link_off_rounded, color: PaperColors.pinRed, size: 22),
          const SizedBox(width: 8),
          Text(
            'Disconnect Petals?',
            style: GoogleFonts.caveat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
            ),
          ),
        ],
      ),
      content: Text(
        'This will disconnect you from your partner. Your paper moments will remain safe.',
        style: GoogleFonts.outfit(
          color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.outfit(
              color: isDark ? PaperColors.darkInkSecondary : PaperColors.inkMedium,
            ),
          ),
        ),
        PaperButton(
          label: 'Disconnect',
          color: PaperColors.pinRed,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (confirmed == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PairingScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF161925) : const Color(0xFFECE4D6);
    final textCol = isDark ? Colors.white : const Color(0xFF5A3E36);
    final cardTextCol = isDark ? const Color(0xFFFAF6EE) : const Color(0xFF3E3427);
    final subTextCol = isDark ? const Color(0xFFB0B4C0) : const Color(0xFF7A6A58);

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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, color: Color(0xFFC54E5E), size: 24),
              const SizedBox(width: 8),
              Text(
                'Petals Settings',
                style: GoogleFonts.caveat(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
          children: [
            // Top Couple Journal Scrapbook Card (Ref Image Match)
            PaperCard(
              showTapeHeader: true,
              tapeText: 'COUPLE JOURNAL',
              rotationAngle: -0.01,
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Avatar(name: _myName, isPrimary: true, textColor: cardTextCol),
                      Column(
                        children: [
                          // 3D Layered Paper Cut Heart Emblem
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFAF6EE),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            ),
                            child: const Icon(Icons.favorite_rounded, color: Color(0xFFE0636C), size: 28),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFFC56B3A), size: 15),
                              const SizedBox(width: 4),
                              Text(
                                'Connected',
                                style: GoogleFonts.caveat(
                                  color: const Color(0xFFC56B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _Avatar(name: _partnerName, isPrimary: false, textColor: cardTextCol),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded, color: subTextCol, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Petals created on ${_formatDate(widget.couple.createdAt)}',
                        style: GoogleFonts.caveat(
                          color: subTextCol,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const _SectionTitle('Your Profile'),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Your Name',
              subtitle: _myName,
              onTap: _editName,
              cardTextCol: cardTextCol,
              subTextCol: subTextCol,
            ),

            const SizedBox(height: 14),

            const _SectionTitle('Appearance'),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                final isDarkMode = currentMode == ThemeMode.dark;
                return _SettingsTile(
                  icon: isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  title: 'App Theme',
                  subtitle: isDarkMode ? 'Night Mode (Dark Charcoal)' : 'Day Mode (Light Parchment)',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
                  },
                  trailing: Switch.adaptive(
                    value: isDarkMode,
                    activeColor: PaperColors.roseCutout,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                  cardTextCol: cardTextCol,
                  subTextCol: subTextCol,
                );
              },
            ),

            const SizedBox(height: 14),

            const _SectionTitle('Home Screen Widget'),
            _SettingsTile(
              icon: Icons.widgets_outlined,
              title: 'Live Widget Mounts',
              subtitle: '4 paper widget sizes available on Android Home Screen',
              onTap: null,
              cardTextCol: cardTextCol,
              subTextCol: subTextCol,
            ),

            const SizedBox(height: 14),

            const _SectionTitle('App Info'),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Petals Paper Edition',
              subtitle: 'Version 1.0.0 · Handcrafted Edition',
              onTap: null,
              cardTextCol: cardTextCol,
              subTextCol: subTextCol,
            ),

            const SizedBox(height: 28),

            // Disconnect Dark Charcoal Paper Button
            GestureDetector(
              onTap: _signOut,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF282625),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_off_rounded, color: Color(0xFFED7280), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Disconnect from Partner',
                      style: GoogleFonts.caveat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFED7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: widget.hideBottomDock
            ? null
            : PaperBottomDock(
                currentIndex: 3,
                onHomeTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                onChatTap: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  final uid = _authService.currentUser?.uid ?? '';
                  Navigator.push(
                    context,
                    PaperPageRoute(
                      builder: (_) => MessagesScreen(
                        couple: widget.couple,
                        myUid: uid,
                      ),
                    ),
                  );
                },
                onProfileTap: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                  final uid = _authService.currentUser?.uid ?? '';
                  Navigator.push(
                    context,
                    PaperPageRoute(
                      builder: (_) => ProfileScreen(
                        couple: widget.couple,
                        myUid: uid,
                      ),
                    ),
                  );
                },
                onSettingsTap: () {},
              ),
      ),
    );
  }

  void _editName() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: _myName);
    showPaperDialog(
      context: context,
      title: Text(
        'Edit Name',
        style: GoogleFonts.caveat(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: isDark ? PaperColors.darkInkPrimary : PaperColors.inkDark,
        ),
      ),
      content: PaperTextField(
        controller: ctrl,
        label: 'Display Name',
        hint: 'Your name',
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
          label: 'Save',
          color: PaperColors.roseCutout,
          onPressed: () async {
            await _authService.saveUserName(ctrl.text.trim());
            if (!mounted) return;
            setState(() => _myName = ctrl.text.trim());
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isPrimary;
  final Color textColor;
  const _Avatar({required this.name, required this.isPrimary, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPrimary ? const Color(0xFFE0636C) : const Color(0xFF86A07E),
            border: Border.all(color: const Color(0xFFFAF6EE), width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFAF6EE),
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.caveat(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        title,
        style: GoogleFonts.caveat(
          color: const Color(0xFFC54E5E),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color cardTextCol;
  final Color subTextCol;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.cardTextCol,
    required this.subTextCol,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? const Color(0xFF38262A) : const Color(0xFFF2D6DC);
    final iconBorder = isDark ? const Color(0xFF5E3A42) : const Color(0xFFE8B8C2);
    final iconColor = isDark ? const Color(0xFFE0636C) : const Color(0xFFC54E5E);

    return PaperCard(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      rotationAngle: 0.0,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
              border: Border.all(color: iconBorder),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.caveat(
                    color: cardTextCol,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    color: subTextCol,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC54E5E), size: 24),
        ],
      ),
    );
  }
}
