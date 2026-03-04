import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/event_photo_model.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/services/event_photo_service.dart';
import '../../../core/services/meetup_service.dart';
import '../../../theme/app_theme.dart';
import '../utils/live_feed_utils.dart';

/// Ana sayfada "Canlı" modunda gösterilen sayfa.
/// O an gerçekleşen etkinliklerde paylaşılan fotoğrafları gösterir.
class LiveFeedPage extends StatelessWidget {
  const LiveFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final meetupService = context.read<MeetupService>();
    final eventPhotoService = context.read<EventPhotoService>();

    return StreamBuilder<List<MeetupModel>>(
      stream: meetupService.getActiveMeetupsStream(),
      builder: (context, meetupsSnapshot) {
        if (meetupsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        final activeMeetups = meetupsSnapshot.data ?? [];

        if (activeMeetups.isEmpty) {
          return _buildEmptyState(context);
        }

        final meetupMap = {for (final m in activeMeetups) m.id: m};

        return StreamBuilder<List<EventPhotoModel>>(
          stream: eventPhotoService.getLivePhotosStream(),
          builder: (context, photosSnapshot) {
            if (photosSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final allPhotos = photosSnapshot.data ?? [];
            final activeMeetupIds = meetupMap.keys.toSet();
            final livePhotos = filterLivePhotos(allPhotos, activeMeetupIds);

            if (livePhotos.isEmpty) {
              return _buildEmptyState(context);
            }

            final grouped = groupPhotosByMeetup(livePhotos);

            return RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surfaceLight,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: grouped.length,
                itemBuilder: (context, index) {
                  final meetupId = grouped.keys.elementAt(index);
                  final photos = grouped[meetupId]!;
                  final meetup = meetupMap[meetupId];
                  final meetupTitle = meetup?.title ?? 'Etkinlik';

                  return _MeetupPhotoGroup(
                    meetupId: meetupId,
                    meetupTitle: meetupTitle,
                    photos: photos,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Şu anda aktif etkinlik bulunmuyor',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Aktif etkinliklerden paylaşılan fotoğraflar burada görünecek',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MeetupPhotoGroup extends StatelessWidget {
  final String meetupId;
  final String meetupTitle;
  final List<EventPhotoModel> photos;

  const _MeetupPhotoGroup({
    required this.meetupId,
    required this.meetupTitle,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meetupTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Canlı',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...photos.map(
          (photo) => _PhotoCard(
            photo: photo,
            meetupId: meetupId,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final EventPhotoModel photo;
  final String meetupId;

  const _PhotoCard({
    required this.photo,
    required this.meetupId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/live-event/$meetupId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: photo.photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.backgroundLight,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.backgroundLight,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppTheme.textLight,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.backgroundLight,
                    backgroundImage: photo.userImageUrl != null &&
                            photo.userImageUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(photo.userImageUrl!)
                        : null,
                    child: photo.userImageUrl == null ||
                            photo.userImageUrl!.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 16,
                            color: AppTheme.textLight,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.userName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatRelativeTime(photo.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textLight,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Az önce';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else {
      return '${diff.inDays} gün önce';
    }
  }
}
