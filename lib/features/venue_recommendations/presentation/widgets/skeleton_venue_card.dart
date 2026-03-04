import 'package:flutter/material.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Shimmer-animated skeleton loading card that mimics VenueCard layout.
/// Shows placeholder boxes for photo, title, address, and rating
/// while venue data is being fetched.
///
/// Validates: Requirements 17.1
class SkeletonVenueCard extends StatefulWidget {
  const SkeletonVenueCard({super.key});

  @override
  State<SkeletonVenueCard> createState() => _SkeletonVenueCardState();
}

class _SkeletonVenueCardState extends State<SkeletonVenueCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              // Image placeholder (80x80)
              _buildShimmerBox(width: 80, height: 80, borderRadius: 10),
              const SizedBox(width: 12),
              // Text placeholders column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title placeholder (~60% width)
                    _buildShimmerBox(
                      widthFactor: 0.6,
                      height: 14,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 10),
                    // Address placeholder (~80% width)
                    _buildShimmerBox(
                      widthFactor: 0.8,
                      height: 12,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 10),
                    // Rating placeholder (~30% width)
                    _buildShimmerBox(
                      widthFactor: 0.3,
                      height: 12,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    double? width,
    double? widthFactor,
    required double height,
    required double borderRadius,
  }) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: [
            _clamp(_animation.value - 0.3),
            _clamp(_animation.value),
            _clamp(_animation.value + 0.3),
          ],
        ),
      ),
    );

    if (widthFactor != null) {
      return FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: box,
      );
    }
    return box;
  }

  double _clamp(double value) => value.clamp(0.0, 1.0);
}
