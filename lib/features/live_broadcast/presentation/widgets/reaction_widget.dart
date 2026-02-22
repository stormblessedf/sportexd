import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/models.dart';

/// Tepki butonu ve animasyonları
class ReactionWidget extends StatefulWidget {
  final VoidCallback? onReactionSent;
  final ReactionType defaultType;

  const ReactionWidget({
    super.key,
    this.onReactionSent,
    this.defaultType = ReactionType.heart,
  });

  @override
  State<ReactionWidget> createState() => _ReactionWidgetState();
}

class _ReactionWidgetState extends State<ReactionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onTap() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
    widget.onReactionSent?.call();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red, Colors.pink],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Yüzen tepki animasyonu container'ı
class FloatingReactionsContainer extends StatefulWidget {
  final Stream<Reaction> reactionStream;

  const FloatingReactionsContainer({
    super.key,
    required this.reactionStream,
  });

  @override
  State<FloatingReactionsContainer> createState() =>
      _FloatingReactionsContainerState();
}

class _FloatingReactionsContainerState
    extends State<FloatingReactionsContainer> {
  final List<_FloatingReactionData> _reactions = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    widget.reactionStream.listen(_onReaction);
  }

  void _onReaction(Reaction reaction) {
    if (!mounted) return;

    final data = _FloatingReactionData(
      key: UniqueKey(),
      reaction: reaction,
      startX: _random.nextDouble() * 60,
    );

    setState(() {
      _reactions.add(data);
    });

    // 2 saniye sonra kaldır
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _reactions.remove(data);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _reactions.map((data) {
        return Positioned(
          right: 16 + data.startX,
          bottom: 80,
          child: FloatingReactionAnimation(
            key: data.key,
            emoji: data.reaction.type.emoji,
          ),
        );
      }).toList(),
    );
  }
}

class _FloatingReactionData {
  final Key key;
  final Reaction reaction;
  final double startX;

  _FloatingReactionData({
    required this.key,
    required this.reaction,
    required this.startX,
  });
}

/// Tek bir yüzen tepki animasyonu
class FloatingReactionAnimation extends StatefulWidget {
  final String emoji;
  final VoidCallback? onComplete;

  const FloatingReactionAnimation({
    super.key,
    required this.emoji,
    this.onComplete,
  });

  @override
  State<FloatingReactionAnimation> createState() =>
      _FloatingReactionAnimationState();
}

class _FloatingReactionAnimationState extends State<FloatingReactionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;

  final _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Fade out animasyonu (son %30'da)
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0),
      ),
    );

    // Scale animasyonu (başta büyü, sonra küçül)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.2),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 60,
      ),
    ]).animate(_controller);

    // Pozisyon animasyonu (yukarı doğru hareket)
    final horizontalDrift = (_random.nextDouble() - 0.5) * 40;
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(horizontalDrift, -200),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Hafif rotasyon
    final rotationAmount = (_random.nextDouble() - 0.5) * 0.5;
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: rotationAmount,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _positionAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Tepki türü seçici
class ReactionTypePicker extends StatelessWidget {
  final ReactionType selectedType;
  final ValueChanged<ReactionType> onTypeSelected;

  const ReactionTypePicker({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ReactionType.values.map((type) {
          final isSelected = type == selectedType;
          return GestureDetector(
            onTap: () => onTypeSelected(type),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  type.emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 28 : 24,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
