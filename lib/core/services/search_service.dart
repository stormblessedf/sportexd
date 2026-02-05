import 'dart:async';
import 'package:flutter/material.dart';
import '../models/meetup_model.dart';

class SearchService {
  /// Debounce duration
  static const Duration debounceDuration = Duration(milliseconds: 300);

  /// Search across meetup fields
  List<MeetupModel> search(List<MeetupModel> meetups, String query) {
    if (query.isEmpty || query.length < 2) {
      return meetups;
    }

    final lowerQuery = query.toLowerCase();

    return meetups.where((meetup) {
      return meetup.title.toLowerCase().contains(lowerQuery) ||
          meetup.description.toLowerCase().contains(lowerQuery) ||
          meetup.locationName.toLowerCase().contains(lowerQuery) ||
          meetup.locationAddress.toLowerCase().contains(lowerQuery) ||
          meetup.organizerName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Highlight matching text in search results
  List<TextSpan> highlightMatches(
    String text,
    String query, {
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    if (query.isEmpty || query.length < 2) {
      return [TextSpan(text: text, style: normalStyle)];
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);

    while (index >= 0) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: normalStyle,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlightStyle ??
            normalStyle?.copyWith(
              backgroundColor: Colors.yellow.withValues(alpha: 0.3),
              fontWeight: FontWeight.bold,
            ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: normalStyle,
      ));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: normalStyle)] : spans;
  }

  /// Check if a meetup matches the search query
  bool matches(MeetupModel meetup, String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase();
    return meetup.title.toLowerCase().contains(lowerQuery) ||
        meetup.description.toLowerCase().contains(lowerQuery) ||
        meetup.locationName.toLowerCase().contains(lowerQuery) ||
        meetup.locationAddress.toLowerCase().contains(lowerQuery);
  }
}

/// Debouncer utility for search input
class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer({this.duration = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
