// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/profile_photo_model.dart';
import '../../../core/models/swipe_candidate_model.dart';
import '../../../core/models/swipe_invite_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/swipe_invite_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

// â”€â”€â”€ Swipe feedback colours (only these diverge from the light theme) â”€â”€â”€â”€â”€â”€â”€â”€
const _kPass = Color(0xFFEF4444);
const _kInvite = AppTheme.primary; // #13EC5B
const _kGold = Color(0xFFF59E0B);

class SwipeInviteScreen extends StatefulWidget {
  const SwipeInviteScreen({super.key});
  @override
  State<SwipeInviteScreen> createState() => _SwipeInviteScreenState();
}

class _SwipeInviteScreenState extends State<SwipeInviteScreen>
    with TickerProviderStateMixin {
  final _auth = AuthService();
  final _svc = SwipeInviteService();
  final Map<String, int> _photoIdx = {};

  List<SwipeCandidateModel> _candidates = const [];
  bool _isPremium = false;
  bool _loading = true;
  bool _hasError = false;
  bool _processing = false;
  Offset _drag = Offset.zero;
  bool _dragging = false;
  bool _showInfo = false;

  late final TabController _tabs;
  String? get _uid => _auth.currentUserId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // â”€â”€â”€ Data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted)
      setState(() {
        _loading = true;
        _hasError = false;
      });
    try {
      final premium = await _svc.hasPremiumAccess(uid);
      final candidates = await _svc.fetchCandidates(currentUserId: uid);
      if (!mounted) return;
      setState(() {
        _isPremium = premium;
        _candidates = candidates;
        _photoIdx.clear();
        _loading = false;
      });
    } catch (e) {
      debugPrint('SwipeInviteScreen._load: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  void _resetDeckInteraction() {
    _drag = Offset.zero;
    _dragging = false;
    _showInfo = false;
  }

  void _removeTopCandidate() {
    if (_candidates.isEmpty) return;
    final removedUserId = _candidates.first.user.id;
    setState(() {
      _photoIdx.remove(removedUserId);
      _candidates = _candidates.sublist(1);
      _resetDeckInteraction();
    });
  }

  Future<void> _swipeLeft() async {
    final uid = _uid;
    final l10n = AppLocalizations.of(context)!;
    if (uid == null || _candidates.isEmpty || _processing) return;
    HapticFeedback.lightImpact();
    final candidate = _candidates.first;
    setState(() {
      _processing = true;
      _drag = Offset.zero;
      _dragging = false;
    });
    try {
      await _svc.swipeLeft(actorId: uid, targetId: candidate.user.id);
      if (!mounted) return;
      _removeTopCandidate();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _drag = Offset.zero;
        _dragging = false;
      });
      _toast(l10n.errorRetry, ok: false);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _swipeRight() async {
    final uid = _uid;
    if (uid == null || _candidates.isEmpty || _processing) return;
    if (!_isPremium) {
      HapticFeedback.heavyImpact();
      setState(() {
        _drag = Offset.zero;
        _dragging = false;
      });
      _showPremiumSheet();
      return;
    }
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final candidate = _candidates.first;
    setState(() {
      _processing = true;
      _drag = Offset.zero;
      _dragging = false;
    });
    try {
      final result = await _svc.swipeRight(
        actorId: uid,
        targetId: candidate.user.id,
      );
      if (!mounted) return;
      if (result.premiumRequired) {
        setState(() => _isPremium = false);
        _showPremiumSheet();
        return;
      }
      if (result.inviteCreated || result.autoMatched) {
        _removeTopCandidate();
      }
      if (result.autoMatched) {
        _showMatch();
      } else if (result.inviteCreated) {
        _toast(l10n.swipeInviteSent, ok: true);
      }
    } catch (_) {
      if (!mounted) return;
      _toast(l10n.errorRetry, ok: false);
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _accept(SwipeInviteModel inv) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _svc.acceptInvite(inviteId: inv.id, currentUserId: uid);
      if (mounted)
        _toast(AppLocalizations.of(context)!.swipeInviteAccepted, ok: true);
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context)!.errorRetry, ok: false);
    }
  }

  Future<void> _reject(SwipeInviteModel inv) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _svc.rejectInvite(inviteId: inv.id, currentUserId: uid);
      if (mounted)
        _toast(AppLocalizations.of(context)!.swipeInviteRejected, ok: true);
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context)!.errorRetry, ok: false);
    }
  }

  Future<void> _chat(SwipeInviteModel inv) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final chatId = await _svc.startChatFromInvite(
        invite: inv,
        currentUserId: uid,
      );
      if (!mounted || chatId == null) return;
      final other = await _svc.getUser(inv.otherUserId(uid));
      if (!mounted) return;
      context.push(
        '/chat',
        extra: {
          'chatId': chatId,
          'title': other?.username ?? AppLocalizations.of(context)!.chat,
        },
      );
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context)!.errorRetry, ok: false);
    }
  }

  void _toast(String msg, {required bool ok}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                ok ? Icons.check_circle_outline : Icons.error_outline,
                color: ok ? _kInvite : _kPass,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
        ),
      );
  }

  void _showPremiumSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PremiumSheet(l10n: AppLocalizations.of(context)!),
    );
  }

  void _showMatch() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _MatchDialog(l10n: AppLocalizations.of(context)!),
    );
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: _appBar(l10n),
        body: Center(
          child: Text(
            l10n.loginToUseSwipeInvites,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n),
            _buildTabStrip(l10n),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _discoverTab(l10n),
                  _incomingTab(uid, l10n),
                  _matchesTab(uid, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(AppLocalizations l10n) => AppBar(
    title: Text(l10n.swipeInviteTitle),
    backgroundColor: AppTheme.backgroundLight,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  );

  // â”€â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.textDark.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textDark,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.swipeInviteTitle,
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const Spacer(),
          _PremiumBadge(isPremium: _isPremium, l10n: l10n),
        ],
      ),
    );
  }

  // â”€â”€â”€ Tab strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTabStrip(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppTheme.textDark,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: l10n.swipeTabDiscover),
            Tab(text: l10n.swipeTabIncoming),
            Tab(text: l10n.swipeTabMatches),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  DISCOVER TAB
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _discoverTab(AppLocalizations l10n) {
    if (_loading) return _loadingState();
    if (_hasError) return _errorState();
    if (_candidates.isEmpty) return _emptyDeckState();

    final current = _candidates.first;
    final size = MediaQuery.sizeOf(context);
    // Card shrinks when info panel is open to make room below
    final cardH = _showInfo
        ? (size.height * 0.40).clamp(240.0, 360.0)
        : (size.height * 0.52).clamp(340.0, 500.0);

    return Column(
      children: [
        const SizedBox(height: 16),
        // â”€â”€ Card deck (animated height) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: cardH + 20,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                for (int i = _candidates.take(3).length - 1; i >= 0; i--)
                  _stackedCard(
                    candidate: _candidates[i],
                    stackIdx: i,
                    isTop: i == 0,
                    cardW: size.width - 32,
                    cardH: cardH,
                    l10n: l10n,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // â”€â”€ About panel â€” tap card to toggle, bounded by remaining space â”€â”€â”€â”€
        Flexible(
          child: ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _showInfo
                  ? _AboutPanel(candidate: current, l10n: l10n)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        // â”€â”€ Action buttons â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _actionRow(l10n),
        const SizedBox(height: 20),
      ],
    );
  }

  // â”€â”€â”€ Stacked card helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _stackedCard({
    required SwipeCandidateModel candidate,
    required int stackIdx,
    required bool isTop,
    required double cardW,
    required double cardH,
    required AppLocalizations l10n,
  }) {
    final scale = 1.0 - (stackIdx * 0.045);
    final translateY = stackIdx * 16.0;
    final offset = isTop ? _drag : Offset.zero;
    final rotation = isTop ? (_drag.dx / 380) * 0.14 : 0.0;

    final card = _buildCard(
      candidate: candidate,
      cardW: cardW,
      cardH: cardH,
      isTop: isTop,
      l10n: l10n,
    );

    return AnimatedContainer(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Transform.translate(
        offset: Offset(offset.dx, translateY + offset.dy),
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: isTop
                ? GestureDetector(
                    onTap: () => setState(() => _showInfo = !_showInfo),
                    onPanUpdate: (d) => setState(() {
                      _dragging = true;
                      _drag += d.delta;
                    }),
                    onPanEnd: (_) {
                      if (_drag.dx > 100)
                        _swipeRight();
                      else if (_drag.dx < -100)
                        _swipeLeft();
                      else
                        setState(() {
                          _dragging = false;
                          _drag = Offset.zero;
                        });
                    },
                    child: card,
                  )
                : IgnorePointer(child: card),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Single card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildCard({
    required SwipeCandidateModel candidate,
    required double cardW,
    required double cardH,
    required bool isTop,
    required AppLocalizations l10n,
  }) {
    final user = candidate.user;
    final urls = _photoUrls(candidate);
    final idx = _currentIdx(candidate);
    final photoUrl = urls.isNotEmpty ? urls[idx] : null;

    return Container(
      width: cardW,
      height: cardH,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textDark.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            if (photoUrl != null)
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(user),
              )
            else
              _fallback(user),

            // Gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: cardH * 0.55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
              ),
            ),

            // Photo indicators
            if (urls.length > 1)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _PhotoIndicators(total: urls.length, current: idx),
              ),

            // Photo nav taps
            if (isTop && urls.length > 1)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _changePhoto(candidate, -1),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _changePhoto(candidate, 1),
                      ),
                    ),
                  ],
                ),
              ),

            // Swipe feedback overlay
            if (isTop)
              _SwipeFeedback(drag: _drag, isPremium: _isPremium, l10n: l10n),

            // User info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // â”€â”€ Name + score â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            user.age != null
                                ? '${user.username}, ${user.age}'
                                : user.username,
                            style: GoogleFonts.lexend(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(blurRadius: 8, color: Colors.black38),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reliability score badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kInvite,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: Colors.black,
                                size: 13,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                user.reliabilityScore.toStringAsFixed(0),
                                style: GoogleFonts.lexend(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Online dot
                        if (user.isCurrentlyOnline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: _kInvite,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ã‡evrimiÃ§i',
                                  style: GoogleFonts.lexend(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            user.location?.isNotEmpty == true
                                ? user.location!
                                : l10n.locationUnknown,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(UserModel user) {
    final initial = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : '?';
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: GoogleFonts.lexend(
                  color: AppTheme.primary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              user.username,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ Action buttons row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _actionRow(AppLocalizations l10n) {
    final can =
        !_processing && !_loading && !_hasError && _candidates.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionBtn(
            onTap: can ? _swipeLeft : null,
            icon: Icons.close_rounded,
            color: _kPass,
            label: l10n.swipePass,
          ),
          const SizedBox(width: 40),
          _ActionBtn(
            onTap: can ? _swipeRight : null,
            icon: _isPremium ? Icons.favorite_rounded : Icons.lock_rounded,
            color: _kInvite,
            label: _isPremium ? l10n.swipeInvite : l10n.swipePremiumOnly,
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ State placeholders â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _loadingState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2.5,
        ),
        const SizedBox(height: 16),
        Text(
          'Spor arkadaÅŸlarÄ± yÃ¼kleniyor...',
          style: GoogleFonts.lexend(color: AppTheme.textMuted, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kPass.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _kPass.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: _kPass, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Bir sorun oluÅŸtu',
            style: GoogleFonts.lexend(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'BaÄŸlantÄ±nÄ± kontrol edip tekrar dene',
            style: GoogleFonts.lexend(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar Dene'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textDark,
              side: const BorderSide(color: AppTheme.borderLight),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _emptyDeckState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderLight, width: 2),
            ),
            child: const Icon(
              Icons.sports_kabaddi_rounded,
              color: AppTheme.textLight,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Herkesle TanÄ±ÅŸtÄ±n!',
            style: GoogleFonts.lexend(
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Åimdilik yeni spor arkadaÅŸÄ± yok.\nBiraz sonra tekrar dene.',
            style: GoogleFonts.lexend(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Yenile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textDark,
              side: const BorderSide(color: AppTheme.borderLight),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
          ),
        ],
      ),
    ),
  );

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  INCOMING TAB
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _incomingTab(String uid, AppLocalizations l10n) {
    return StreamBuilder<List<SwipeInviteModel>>(
      stream: _svc.watchIncomingInvites(uid),
      builder: (_, snap) {
        if (snap.hasError) {
          return _emptyListState(
            icon: Icons.error_outline_rounded,
            title: l10n.errorRetry,
            sub: l10n.errorRetry,
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _loadingState();
        }
        final list = snap.data ?? const [];
        if (list.isEmpty)
          return _emptyListState(
            icon: Icons.mark_email_unread_outlined,
            title: 'Gelen Davet Yok',
            sub: 'Sana gonderilen spor arkadasi\ndavetleri burada gorunur.',
          );
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _InviteTile(
            invite: list[i],
            uid: uid,
            svc: _svc,
            isIncoming: true,
            l10n: l10n,
            onAccept: () => _accept(list[i]),
            onReject: () => _reject(list[i]),
            onChat: () => _chat(list[i]),
          ),
        );
      },
    );
  }

  Widget _matchesTab(String uid, AppLocalizations l10n) {
    return StreamBuilder<List<SwipeInviteModel>>(
      stream: _svc.watchAcceptedInvites(uid),
      builder: (_, snap) {
        if (snap.hasError) {
          return _emptyListState(
            icon: Icons.error_outline_rounded,
            title: l10n.errorRetry,
            sub: l10n.errorRetry,
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _loadingState();
        }
        final list = snap.data ?? const [];
        if (list.isEmpty)
          return _emptyListState(
            icon: Icons.handshake_outlined,
            title: 'Henuz Eslesme Yok',
            sub: 'Davet gonder veya kabul et,\neslesmeler burada gorunur.',
          );
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _InviteTile(
            invite: list[i],
            uid: uid,
            svc: _svc,
            isIncoming: false,
            l10n: l10n,
            onAccept: () => _accept(list[i]),
            onReject: () => _reject(list[i]),
            onChat: () => _chat(list[i]),
          ),
        );
      },
    );
  }

  Widget _emptyListState({
    required IconData icon,
    required String title,
    required String sub,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderLight, width: 2),
            ),
            child: Icon(icon, color: AppTheme.textLight, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.lexend(
              color: AppTheme.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: GoogleFonts.lexend(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  // â”€â”€â”€ Photo helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<String> _photoUrls(SwipeCandidateModel c) {
    final result = <String>[];
    final primary = c.primaryPhotoUrl?.trim();
    if (primary != null && primary.isNotEmpty) result.add(primary);
    for (final p in c.photos) {
      final u = p.photoUrl.trim();
      if (u.isNotEmpty && !result.contains(u)) result.add(u);
    }
    return result;
  }

  int _currentIdx(SwipeCandidateModel c) {
    final u = _photoUrls(c);
    if (u.isEmpty) return 0;
    return (_photoIdx[c.user.id] ?? 0).clamp(0, u.length - 1);
  }

  void _changePhoto(SwipeCandidateModel c, int delta) {
    final u = _photoUrls(c);
    if (u.length < 2) return;
    final next = (_currentIdx(c) + delta).clamp(0, u.length - 1);
    setState(() => _photoIdx[c.user.id] = next);
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  ABOUT PANEL  â”€  shown below the card
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _AboutPanel extends StatelessWidget {
  final SwipeCandidateModel candidate;
  final AppLocalizations l10n;
  const _AboutPanel({required this.candidate, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final user = candidate.user;
    final sports = user.interestedSports ?? <SportType>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textDark.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ Stats row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Row(
                  children: [
                    _StatCell(
                      icon: Icons.event_available_rounded,
                      value: user.totalMeetupsJoined.toString(),
                      label: 'Etkinlik',
                      color: AppTheme.primary,
                    ),
                    _vDivider(),
                    _StatCell(
                      icon: Icons.bolt_rounded,
                      value: user.reliabilityScore.toStringAsFixed(0),
                      label: 'GÃ¼venilirlik',
                      color: const Color(0xFF3B82F6),
                    ),
                    _vDivider(),
                    _StatCell(
                      icon: Icons.star_rounded,
                      value: user.totalRatings > 0
                          ? user.averageRating.toStringAsFixed(1)
                          : 'â€”',
                      label: 'DeÄŸerlendirme',
                      color: _kGold,
                    ),
                    _vDivider(),
                    _StatCell(
                      icon: Icons.sports_score_rounded,
                      value: candidate.commonSportsCount.toString(),
                      label: 'Ortak Spor',
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),

                // â”€â”€ Bio â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (user.bio?.isNotEmpty == true) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppTheme.borderLight),
                  ),
                  Text(
                    user.bio!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lexend(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                ],

                // â”€â”€ Sports â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                if (sports.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppTheme.borderLight),
                  ),
                  _SectionLabel(
                    icon: Icons.sports_rounded,
                    text: 'Spor Ä°lgileri',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sports.map((s) => _SportChip(sport: s)).toList(),
                  ),
                ],

                // â”€â”€ Details: level, playStyle, preferredTimes â”€â”€â”€â”€â”€â”€â”€â”€â”€
                ..._buildDetails(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 40,
    color: AppTheme.borderLight,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  List<Widget> _buildDetails(UserModel user) {
    final chips = <Widget>[];

    if (user.level != null) {
      chips.add(
        _DetailChip(
          icon: Icons.trending_up_rounded,
          label: _levelLabel(user.level!),
          color: const Color(0xFF3B82F6),
        ),
      );
    }
    if (user.playStyle != null) {
      chips.add(
        _DetailChip(
          icon: user.playStyle == PlayStyle.competitive
              ? Icons.emoji_events_rounded
              : Icons.sentiment_satisfied_alt_rounded,
          label: user.playStyle == PlayStyle.competitive
              ? 'RekabetÃ§i'
              : 'EÄŸlenceli',
          color: user.playStyle == PlayStyle.competitive
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
        ),
      );
    }
    if (user.preferredTimes?.isNotEmpty == true) {
      for (final t in user.preferredTimes!) {
        chips.add(
          _DetailChip(
            icon: Icons.access_time_rounded,
            label: _timeLabel(t),
            color: const Color(0xFF8B5CF6),
          ),
        );
      }
    }
    if (user.height != null) {
      chips.add(
        _DetailChip(
          icon: Icons.height_rounded,
          label: '${user.height} cm',
          color: AppTheme.textMuted,
        ),
      );
    }

    if (chips.isEmpty) return const [];

    return [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: AppTheme.borderLight),
      ),
      _SectionLabel(icon: Icons.person_outline_rounded, text: 'Ã–zellikler'),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: chips),
    ];
  }

  String _levelLabel(Level l) {
    switch (l) {
      case Level.beginner:
        return 'BaÅŸlangÄ±Ã§';
      case Level.intermediate:
        return 'Orta Seviye';
      case Level.advanced:
        return 'Ä°leri Seviye';
    }
  }

  String _timeLabel(PreferredTime t) {
    switch (t) {
      case PreferredTime.weekdayMorning:
        return 'Hf. iÃ§i sabah';
      case PreferredTime.weekdayEvening:
        return 'Hf. iÃ§i akÅŸam';
      case PreferredTime.weekendMorning:
        return 'Hf. sonu sabah';
      case PreferredTime.weekendEvening:
        return 'Hf. sonu akÅŸam';
    }
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lexend(
            color: AppTheme.textDark,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lexend(color: AppTheme.textLight, fontSize: 10),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: AppTheme.textMuted),
      const SizedBox(width: 5),
      Text(
        text,
        style: GoogleFonts.lexend(
          color: AppTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _SportChip extends StatelessWidget {
  final SportType sport;
  const _SportChip({required this.sport});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
    ),
    child: Text(
      sport.label,
      style: GoogleFonts.lexend(
        color: AppTheme.textDark,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.lexend(
            color: AppTheme.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

// â”€â”€â”€ Photo indicators â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PhotoIndicators extends StatelessWidget {
  final int total, current;
  const _PhotoIndicators({required this.total, required this.current});

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      total,
      (i) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: i == current
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ),
    ),
  );
}

// â”€â”€â”€ Swipe feedback overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SwipeFeedback extends StatelessWidget {
  final Offset drag;
  final bool isPremium;
  final AppLocalizations l10n;
  const _SwipeFeedback({
    required this.drag,
    required this.isPremium,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final force = (drag.dx / 100).clamp(-1.0, 1.0);
    if (force.abs() < 0.06) return const SizedBox.shrink();
    final isRight = force > 0;
    final color = isRight ? (isPremium ? _kInvite : Colors.grey) : _kPass;
    final label = isRight ? (isPremium ? 'DAVET' : 'PREMIUM') : 'PAS';
    final icon = isRight ? Icons.favorite_rounded : Icons.close_rounded;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: force.abs() * 0.45),
              Colors.transparent,
            ],
            begin: isRight ? Alignment.centerRight : Alignment.centerLeft,
            end: isRight ? Alignment.centerLeft : Alignment.centerRight,
          ),
        ),
        child: Align(
          alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Opacity(
              opacity: force.abs().clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.lexend(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Action button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ActionBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color color;
  final String label;
  const _ActionBtn({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceLight,
              border: Border.all(
                color: enabled
                    ? color.withValues(alpha: 0.5)
                    : AppTheme.borderLight,
                width: 2,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: enabled ? color : AppTheme.textLight,
              size: 26,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.lexend(
              color: enabled ? color : AppTheme.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Premium badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final AppLocalizations l10n;
  const _PremiumBadge({required this.isPremium, required this.l10n});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isPremium ? _kGold.withValues(alpha: 0.1) : AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: isPremium ? _kGold.withValues(alpha: 0.4) : AppTheme.borderLight,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPremium ? Icons.workspace_premium_rounded : Icons.lock_rounded,
          size: 13,
          color: isPremium ? _kGold : AppTheme.textLight,
        ),
        const SizedBox(width: 5),
        Text(
          isPremium ? l10n.premiumActive : l10n.premiumLocked,
          style: GoogleFonts.lexend(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isPremium ? _kGold : AppTheme.textLight,
          ),
        ),
      ],
    ),
  );
}

// â”€â”€â”€ Invite tile (Incoming / Matches tabs) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _InviteTile extends StatelessWidget {
  final SwipeInviteModel invite;
  final String uid;
  final SwipeInviteService svc;
  final bool isIncoming;
  final AppLocalizations l10n;
  final VoidCallback onAccept, onReject, onChat;

  const _InviteTile({
    required this.invite,
    required this.uid,
    required this.svc,
    required this.isIncoming,
    required this.l10n,
    required this.onAccept,
    required this.onReject,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final otherId = invite.otherUserId(uid);
    return FutureBuilder<UserModel?>(
      future: svc.getUser(otherId),
      builder: (_, userSnap) {
        final other = userSnap.data;
        final fallbackProfileUrl = other?.profileImageUrl?.trim();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textDark.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              FutureBuilder<List<ProfilePhotoModel>>(
                future: svc.getUserPhotos(otherId, limit: 1),
                builder: (_, photoSnap) {
                  final photoUrl = photoSnap.data?.isNotEmpty == true
                      ? photoSnap.data!.first.photoUrl.trim()
                      : null;
                  final url = photoUrl?.isNotEmpty == true
                      ? photoUrl
                      : (fallbackProfileUrl?.isNotEmpty == true
                            ? fallbackProfileUrl
                            : null);
                  if (url?.isNotEmpty == true) {
                    return CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(url!),
                    );
                  }
                  return CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      other?.username.isNotEmpty == true
                          ? other!.username[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.lexend(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            other?.username ?? '...',
                            style: GoogleFonts.lexend(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Score badge
                        if (other != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: AppTheme.primary,
                                  size: 11,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  other.reliabilityScore.toStringAsFixed(0),
                                  style: GoogleFonts.lexend(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (other?.location?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          other!.location!,
                          style: GoogleFonts.lexend(
                            color: AppTheme.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (other?.bio?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          other!.bio!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lexend(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Actions
              if (isIncoming)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TileBtn(
                      label: l10n.acceptButton,
                      color: _kInvite,
                      onTap: onAccept,
                    ),
                    const SizedBox(height: 6),
                    _TileBtn(
                      label: l10n.rejectButton,
                      color: _kPass,
                      onTap: onReject,
                      outlined: true,
                    ),
                  ],
                )
              else
                _TileBtn(
                  label: l10n.startChatButton,
                  color: _kInvite,
                  onTap: onChat,
                  icon: Icons.chat_bubble_rounded,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TileBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  final IconData? icon;
  const _TileBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: outlined ? 0.45 : 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.lexend(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

// â”€â”€â”€ Premium bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PremiumSheet extends StatelessWidget {
  final AppLocalizations l10n;
  const _PremiumSheet({required this.l10n});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.borderLight,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kGold, Color(0xFFEF6C00)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Premium Gerekli',
          style: GoogleFonts.lexend(
            color: AppTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.swipePremiumRequired,
          style: GoogleFonts.lexend(
            color: AppTheme.textMuted,
            fontSize: 13,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              "Premium'a GeÃ§",
              style: GoogleFonts.lexend(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// â”€â”€â”€ Match dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MatchDialog extends StatefulWidget {
  final AppLocalizations l10n;
  const _MatchDialog({required this.l10n});
  @override
  State<_MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<_MatchDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale, _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.35, curve: Curves.easeIn),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: AppTheme.primary,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'EÅŸleÅŸme!',
                    style: GoogleFonts.lexend(
                      color: AppTheme.textDark,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Spor arkadaÅŸÄ± buldun!\nArtÄ±k mesajlaÅŸabilirsiniz.',
                    style: GoogleFonts.lexend(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Harika! ğŸ‰',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lexend(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
