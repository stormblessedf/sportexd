import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tam ekran fotoğraf görüntüleyici.
///
/// Hero animasyonu ile geçiş, pinch-to-zoom desteği (InteractiveViewer),
/// ve opsiyonel silme butonu sunar.
///
/// Validates: Requirements 2.3, 3.1
class FullScreenPhotoViewer extends StatelessWidget {
  final String photoUrl;
  final String? heroTag;
  final bool canDelete;
  final VoidCallback? onDelete;

  const FullScreenPhotoViewer({
    super.key,
    required this.photoUrl,
    this.heroTag,
    this.canDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (canDelete && onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Fotoğrafı Sil',
              onPressed: () {
                onDelete!();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: heroTag ?? photoUrl,
            child: Image.network(
              photoUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fotoğraf yüklenemedi',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: Colors.white54,
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
