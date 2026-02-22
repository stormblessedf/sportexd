import 'package:flutter/material.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/features/profile/presentation/widgets/counter_widget.dart';
import 'package:sporsal/theme/app_theme.dart';

enum CounterType { events, partners, reliability, rating }

class ProfileHeaderRow extends StatelessWidget {
  final UserModel user;
  final Function(CounterType) onCounterTap;

  const ProfileHeaderRow({
    super.key,
    required this.user,
    required this.onCounterTap,
  });

  @override
  Widget build(BuildContext context) {
    final counters = [
      (value: '${user.totalMeetupsRegistered}', label: 'Etkinlik', type: CounterType.events),
      (value: '${user.partners.length}', label: 'Partner', type: CounterType.partners),
      (value: '${user.reliabilityScore.round()}%', label: 'Güvenilir', type: CounterType.reliability),
      (value: '${user.averageRating.toStringAsFixed(1)}⭐', label: 'Puan', type: CounterType.rating),
    ];

    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: counters
                .map((c) => CounterWidget(
                      value: c.value,
                      label: c.label,
                      onTap: () => onCounterTap(c.type),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.surfaceLight,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            onBackgroundImageError: user.profileImageUrl != null
                ? (e, _) {}
                : null,
            child: user.profileImageUrl == null
                ? Icon(Icons.person, size: 36, color: Colors.grey[400])
                : null,
          ),
        ),
        if (user.isCurrentlyOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.backgroundLight,
                  width: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
