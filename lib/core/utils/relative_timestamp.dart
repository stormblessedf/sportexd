/// Utility class for formatting timestamps into human-readable relative time.
///
/// Used primarily in chat list to show when the last message was sent.
class RelativeTimestamp {
  // Turkish day names
  static const List<String> _turkishDayNames = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  /// Format a timestamp into a human-readable relative time string.
  ///
  /// - Today: returns time in HH:mm format (e.g., "10:42")
  /// - Yesterday: returns "Dün"
  /// - This week: returns day name (e.g., "Pazartesi")
  /// - Older: returns date in DD.MM.YYYY format
  static String format(DateTime? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final timestampDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final difference = today.difference(timestampDate).inDays;

    if (difference == 0) {
      // Today: return time in HH:mm format
      return _formatTime(timestamp);
    } else if (difference == 1) {
      // Yesterday
      return 'Dün';
    } else if (difference < 7) {
      // This week: return day name
      // DateTime.weekday returns 1 for Monday, 7 for Sunday
      return _turkishDayNames[timestamp.weekday - 1];
    } else {
      // Older: return date in DD.MM.YYYY format
      return _formatDate(timestamp);
    }
  }

  /// Format time as HH:mm
  static String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format date as DD.MM.YYYY
  static String _formatDate(DateTime timestamp) {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year.toString();
    return '$day.$month.$year';
  }

  /// Format timestamp for meetup status display (e.g., "BUGÜN 14:00", "YARIN 10:00")
  static String formatMeetupStatus(DateTime meetupDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetupDay = DateTime(meetupDate.year, meetupDate.month, meetupDate.day);
    final difference = meetupDay.difference(today).inDays;

    final time = _formatTime(meetupDate);

    if (difference == 0) {
      return 'BUGÜN $time';
    } else if (difference == 1) {
      return 'YARIN $time';
    } else if (difference < 7 && difference > 0) {
      final dayName = _turkishDayNames[meetupDate.weekday - 1].toUpperCase();
      return '$dayName $time';
    } else if (difference < 0) {
      return 'TAMAMLANDI';
    } else {
      return '${_formatDate(meetupDate)} $time';
    }
  }
}
