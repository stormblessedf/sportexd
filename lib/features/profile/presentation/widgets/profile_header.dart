import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;
  final VoidCallback? onProfilePictureChange;
  final VoidCallback? onPartnersTap;

  const ProfileHeader({
    super.key,
    required this.user,
    this.isOwnProfile = false,
    this.onProfilePictureChange,
    this.onPartnersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primary.withValues(alpha:0.15),
            AppTheme.primary.withValues(alpha:0.05),
            AppTheme.backgroundLight,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          // Profile Picture with online indicator
          GestureDetector(
            onTap: isOwnProfile ? onProfilePictureChange : null,
            child: Stack(
              children: [
                // Profile picture with green border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha:0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: AppTheme.surfaceLight,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Icon(Icons.person, size: 55, color: Colors.grey[400])
                        : null,
                  ),
                ),

                // Online indicator (green dot)
                if (user.isCurrentlyOnline)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha:0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Camera icon for own profile
                if (isOwnProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Name, rating and age
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.username,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              if (user.averageRating > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (user.age != null) ...[
                const SizedBox(width: 8),
                Text(
                  ', ${user.age}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ],
          ),

          // Location
          if (user.location != null && user.location!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  user.location!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],

          // Partners count
          const SizedBox(height: 16),
          InkWell(
            onTap: onPartnersTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.handshake, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${user.partners.length} Spor Partneri',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
