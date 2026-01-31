import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/presence_service.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import 'widgets/profile_header.dart';
import 'widgets/stats_cards.dart';
import 'widgets/about_me_card.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  final String? userId;

  const ProfileScreen({super.key, this.user, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final PresenceService _presenceService = PresenceService();
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _user = widget.user;
    } else if (widget.userId != null) {
      _loadUserById(widget.userId!);
    } else {
      _loadCurrentUser();
    }
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserById(String userId) async {
    setState(() => _isLoading = true);
    try {
      final doc = await _authService.firestore.collection('users').doc(userId).get();
      if (doc.exists && mounted) {
        setState(() {
          _user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final userId = _authService.currentUserId;

      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final ref = FirebaseStorage.instance.ref('profile_pictures/$userId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId},
      );
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _authService.updateUser(
        userId: userId,
        profileImageUrl: downloadUrl,
      );

      await _loadCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil resmi güncellendi!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Kullanıcı bilgisi bulunamadı.",
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _user!;
    final isOwnProfile = _authService.currentUserId == user.id;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('@${user.username}'),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                context.push('/edit-profile');
              },
            ),
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                context.push('/settings');
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.userId != null) {
            await _loadUserById(widget.userId!);
          } else {
            await _loadCurrentUser();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // New Profile Header
              ProfileHeader(
                user: user,
                isOwnProfile: isOwnProfile,
                onProfilePictureChange: _changeProfilePicture,
              ),

              const SizedBox(height: 20),

              // Stats Cards
              StatsCards(
                reliabilityScore: user.reliabilityScore,
                totalMeetups: user.totalMeetupsJoined,
                averageRating: user.averageRating,
                totalRatings: user.totalRatings,
              ),

              const SizedBox(height: 20),

              // About Me Card
              AboutMeCard(bio: user.bio),

              const SizedBox(height: 20),

              // Follow Button (only for other users' profiles)
              if (!isOwnProfile) _buildFollowButton(context, user),
              if (!isOwnProfile) const SizedBox(height: 16),

              // Past Events Button (only for own profile)
              if (isOwnProfile) _buildPastEventsButton(context, user),
              if (isOwnProfile) const SizedBox(height: 16),

              // Rate Participants Button (only for own profile)
              if (isOwnProfile) _buildRateParticipantsButton(context),
              if (isOwnProfile) const SizedBox(height: 24),

              // About Section (detailed info)
              _buildAboutSection(context, user),
              const SizedBox(height: 24),

              // Badges
              _buildBadges(context, user),
              const SizedBox(height: 24),

              // Certificates
              _buildCertificates(context, user),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPastEventsButton(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          context.push('/past-meetups', extra: user.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geçmiş Etkinliklerim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Katıldığın geçmiş etkinlikleri gör',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateParticipantsButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () {
          // Navigate to past meetups - user can rate from there
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geçmiş etkinliklerden değerlendirme yapabilirsiniz'),
              duration: Duration(seconds: 2),
            ),
          );
          context.push('/past-meetups', extra: _user?.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rate,
                  color: Color(0xFFFF9800),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katılımcıları Değerlendir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Geçmiş etkinlik katılımcılarını puanla',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, UserModel user) {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) return const SizedBox.shrink();

    final isFollowing = user.followers?.contains(currentUserId) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            try {
              if (isFollowing) {
                await _authService.unfollowUser(currentUserId, user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.username} takipten çıkarıldı'),
                      backgroundColor: Colors.grey,
                    ),
                  );
                  await _loadUserById(user.id);
                }
              } else {
                await _authService.followUser(currentUserId, user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.username} takip ediliyor'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                  await _loadUserById(user.id);
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: Icon(
            isFollowing ? Icons.person_remove : Icons.person_add,
            size: 20,
          ),
          label: Text(
            isFollowing ? 'Takipten Çık' : 'Takip Et',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey[300] : AppTheme.primary,
            foregroundColor: isFollowing ? AppTheme.textDark : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, UserModel user) {
    final hasInfo = user.location != null ||
        user.age != null ||
        (user.height != null && user.weight != null) ||
        user.gender != null ||
        user.level != null ||
        user.playStyle != null ||
        (user.interestedSports != null && user.interestedSports!.isNotEmpty);

    if (!hasInfo) return const SizedBox.shrink();

    String? levelText;
    if (user.level != null) {
      switch (user.level!) {
        case Level.beginner:
          levelText = 'Başlangıç';
          break;
        case Level.intermediate:
          levelText = 'Orta';
          break;
        case Level.advanced:
          levelText = 'İleri';
          break;
      }
    }

    String? playStyleText;
    if (user.playStyle != null) {
      switch (user.playStyle!) {
        case PlayStyle.competitive:
          playStyleText = 'Rekabetçi';
          break;
        case PlayStyle.casual:
          playStyleText = 'Rahat';
          break;
      }
    }

    String? genderText;
    if (user.gender != null) {
      switch (user.gender!.toLowerCase()) {
        case 'erkek':
          genderText = 'Erkek';
          break;
        case 'kadın':
          genderText = 'Kadın';
          break;
        case 'belirtmek_istemiyorum':
          genderText = 'Belirtilmemiş';
          break;
        default:
          genderText = user.gender;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              iconColor: AppTheme.primary,
              collapsedIconColor: AppTheme.textMuted,
              title: Text(
                'Detaylı Bilgiler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user.height != null && user.weight != null)
                        _buildInfoRow(
                          Icons.straighten_outlined,
                          'Fiziksel',
                          '${user.height} cm • ${user.weight} kg',
                        ),
                      if (genderText != null)
                        _buildInfoRow(Icons.person_outline, 'Cinsiyet', genderText),
                      if (levelText != null)
                        _buildInfoRow(Icons.bar_chart_outlined, 'Seviye', levelText),
                      if (playStyleText != null)
                        _buildInfoRow(Icons.sports_outlined, 'Oyun Stili', playStyleText),
                      if (user.interestedSports != null && user.interestedSports!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.sports_soccer_outlined,
                              size: 20,
                              color: AppTheme.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'İlgi Alanı Sporlar',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.interestedSports!.map((sport) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                sport.displayName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(BuildContext context, UserModel user) {
    if (user.badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Rozetler & Başarımlar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: user.badges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final badge = user.badges[index];
              return Container(
                width: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCertificates(BuildContext context, UserModel user) {
    if (user.certificates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Sertifikalar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: user.certificates.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cert = user.certificates[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cert.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          '${cert.issuer} • ${cert.dateDate.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
