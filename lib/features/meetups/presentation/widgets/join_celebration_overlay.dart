import 'dart:math';
import 'package:flutter/material.dart';

/// Premium katılım animasyonu — ring pulse + glow + elegant text reveal
class JoinCelebrationOverlay {
  static Future<void> show(BuildContext context) async {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _CelebrationWidget(
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _CelebrationWidget extends StatefulWidget {
  final VoidCallback onDismiss;
  const _CelebrationWidget({required this.onDismiss});

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> _backdropOpacity;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring2Opacity;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _glowRadius;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _exitOpacity;

  static const Color accent = Color(0xFF13EC5B);

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    // Backdrop: fade in 0-10%, hold, fade out 85-100%
    _backdropOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 75),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _masterController, curve: Curves.easeOut));

    // Ring 1: expand outward 5-35%
    _ringScale = Tween<double>(begin: 0.0, end: 2.8).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.05, 0.35, curve: Curves.easeOutCubic),
      ),
    );
    _ringOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.7), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.05, 0.40),
    ));

    // Ring 2: delayed, slightly slower
    _ring2Scale = Tween<double>(begin: 0.0, end: 3.2).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.12, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _ring2Opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 75),
    ]).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.12, 0.50),
    ));

    // Check icon: spring in 15-35%
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.15, 0.40, curve: Curves.easeOut),
    ));
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.15, 0.25, curve: Curves.easeOut),
      ),
    );

    // Glow behind icon: pulse
    _glowRadius = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 40.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 40.0, end: 25.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 25.0, end: 30.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
    ));

    // "Katıldın!" text: slide up + fade in 30-50%
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.30, 0.48, curve: Curves.easeOutCubic),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.30, 0.45, curve: Curves.easeOut),
      ),
    );

    // Subtitle: slide up + fade in 38-55%
    _subtitleSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.38, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.38, 0.52, curve: Curves.easeOut),
      ),
    );

    // Exit: everything fades out 82-100%
    _exitOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 82),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 18),
    ]).animate(CurvedAnimation(parent: _masterController, curve: Curves.easeIn));

    _masterController.forward();
    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _masterController,
      builder: (context, _) {
        return IgnorePointer(
          child: Opacity(
            opacity: _exitOpacity.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft dark backdrop
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.45 * _backdropOpacity.value,
                    ),
                  ),
                ),

                // Ring pulse 1
                _buildRing(_ringScale.value, _ringOpacity.value, 3.0),

                // Ring pulse 2
                _buildRing(_ring2Scale.value, _ring2Opacity.value, 2.0),

                // Floating particles (subtle, few)
                ..._buildFloatingDots(),

                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glow + Icon
                    Transform.scale(
                      scale: _iconScale.value,
                      child: Opacity(
                        opacity: _iconOpacity.value,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF13EC5B),
                                Color(0xFF0BD94E),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.5),
                                blurRadius: _glowRadius.value,
                                spreadRadius: _glowRadius.value * 0.3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // "Katıldın!" text
                    Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: const Text(
                          'Katıldın!',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Transform.translate(
                      offset: Offset(0, _subtitleSlide.value),
                      child: Opacity(
                        opacity: _subtitleOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Etkinlikte görüşürüz 🤝',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRing(double scale, double opacity, double strokeWidth) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accent,
              width: strokeWidth,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingDots() {
    final progress = _masterController.value;
    if (progress < 0.15 || progress > 0.85) return [];

    final dotProgress = ((progress - 0.15) / 0.70).clamp(0.0, 1.0);
    final opacity = (1.0 - dotProgress).clamp(0.0, 0.8);
    final random = Random(42); // Fixed seed for consistent positions

    return List.generate(8, (i) {
      final angle = (i / 8) * 2 * pi + (dotProgress * 0.5);
      final radius = 80 + dotProgress * 120 + random.nextDouble() * 30;
      final size = 4.0 + random.nextDouble() * 4;

      return Positioned(
        left: MediaQuery.of(context).size.width / 2 + cos(angle) * radius - size / 2,
        top: MediaQuery.of(context).size.height / 2 + sin(angle) * radius - size / 2 - 40,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.6),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
