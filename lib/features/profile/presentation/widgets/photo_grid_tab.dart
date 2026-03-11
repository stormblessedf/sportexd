import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sporsal/core/models/profile_photo_model.dart';
import 'package:sporsal/core/services/profile_photo_service.dart';
import 'package:sporsal/features/profile/presentation/controllers/photo_upload_controller.dart';
import 'package:sporsal/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

import 'full_screen_photo_viewer.dart';

class PhotoGridTab extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const PhotoGridTab({
    super.key,
    required this.userId,
    required this.isOwnProfile,
  });

  @override
  State<PhotoGridTab> createState() => _PhotoGridTabState();
}

class _PhotoGridTabState extends State<PhotoGridTab> {
  final ProfilePhotoService _photoService = ProfilePhotoService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    if (widget.isOwnProfile) {
      PhotoUploadController.instance.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    if (widget.isOwnProfile) {
      PhotoUploadController.instance.removeListener(_onControllerChanged);
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (PhotoUploadController.instance.shouldTriggerUpload) {
      PhotoUploadController.instance.consumeTrigger();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickAndUploadPhoto();
      });
    }
  }

  void _setUploading(bool value) {
    setState(() => _isUploading = value);
    PhotoUploadController.instance.setUploading(value);
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 95,
    );
    if (pickedFile == null) return;

    _setUploading(true);

    try {
      final bytes = await pickedFile.readAsBytes();
      await _photoService.uploadPhoto(
        userId: widget.userId,
        imageBytes: bytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoLoadFailed),
          ),
        );
      }
    } finally {
      if (mounted) _setUploading(false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.addPhoto,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.primary),
                title: Text(l10n.selectFromGallery,
                    style: GoogleFonts.lexend(fontSize: 14)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.primary),
                title: Text(l10n.takePhoto,
                    style: GoogleFonts.lexend(fontSize: 14)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.deletePhotoTitle,
          style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n.deletePhotoConfirm,
          style: GoogleFonts.lexend(fontSize: 14, color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: GoogleFonts.lexend()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: GoogleFonts.lexend(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deletePhoto(ProfilePhotoModel photo) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    try {
      await _photoService.deletePhoto(
        photoId: photo.photoId,
        storagePath: photo.storagePath,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoDeleteFailed),
          ),
        );
      }
    }
  }

  void _openFullScreen(ProfilePhotoModel photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenPhotoViewer(
          photoUrl: photo.photoUrl,
          heroTag: 'profile_photo_${photo.photoId}',
          canDelete: widget.isOwnProfile,
          onDelete: widget.isOwnProfile ? () => _deletePhoto(photo) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProfilePhotoModel>>(
      stream: _photoService.getPhotosForUser(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              l10n.photoLoadFailed,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          );
        }

        final photos = snapshot.data ?? [];

        return CustomScrollView(
          slivers: [
            if (_isUploading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              ),
            if (photos.isEmpty && !_isUploading)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.all(2),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PhotoGridItem(
                      photo: photos[index],
                      showDelete: widget.isOwnProfile,
                      onTap: () => _openFullScreen(photos[index]),
                      onDelete: () => _deletePhoto(photos[index]),
                    ),
                    childCount: photos.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noPhotosYet,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGridItem extends StatelessWidget {
  final ProfilePhotoModel photo;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoGridItem({
    required this.photo,
    required this.showDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'profile_photo_${photo.photoId}',
            child: Image.network(
              photo.photoUrl,
              fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppTheme.borderLight,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppTheme.borderLight,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppTheme.textLight,
                ),
              );
            },
            ),
          ),
          if (showDelete)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


