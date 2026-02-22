import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static const String _baseUrl = 'https://sportexd-1bb0e.web.app';

  /// Generates the shareable profile URL for a given userId.
  static String generateProfileLink(String userId) {
    return '$_baseUrl/user-profile/$userId';
  }

  /// Generates the full share message text.
  static String generateShareMessage(String userId) {
    final link = generateProfileLink(userId);
    return "Sporsal'da profilime göz at: $link";
  }

  /// Shares the profile link. Returns [ShareResult] on mobile,
  /// copies to clipboard on web fallback.
  static Future<ShareResult> shareProfile(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId boş olamaz');
    }

    final message = generateShareMessage(userId);

    try {
      final result = await Share.share(message);
      return result;
    } catch (e) {
      if (kIsWeb) {
        await Clipboard.setData(
          ClipboardData(text: generateProfileLink(userId)),
        );
        return ShareResult('Panoya kopyalandı', ShareResultStatus.success);
      }
      rethrow;
    }
  }
}
