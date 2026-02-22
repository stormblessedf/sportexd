import 'package:flutter/material.dart';
import 'package:sporsal/core/models/meetup_model.dart';

const sportColors = <MeetupType, Color>{
  MeetupType.football: Color(0xFF4CAF50),
  MeetupType.basketball: Color(0xFFFF9800),
  MeetupType.volleyball: Color(0xFF2196F3),
  MeetupType.tennis: Color(0xFFCDDC39),
  MeetupType.tableTennis: Color(0xFF009688),
  MeetupType.badminton: Color(0xFF00BCD4),
  MeetupType.swimming: Color(0xFF03A9F4),
  MeetupType.running: Color(0xFFE91E63),
  MeetupType.cycling: Color(0xFF9C27B0),
  MeetupType.hiking: Color(0xFF795548),
  MeetupType.yoga: Color(0xFF607D8B),
  MeetupType.fitness: Color(0xFFFF5722),
  MeetupType.boxing: Color(0xFFF44336),
  MeetupType.climbing: Color(0xFF8BC34A),
  MeetupType.skiing: Color(0xFF3F51B5),
  MeetupType.other: Color(0xFF9E9E9E),
};

const turkishMonthAbbreviations = [
  'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
  'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
];

/// Emoji for each MeetupType (used in chart legends)
const sportEmojis = <MeetupType, String>{
  MeetupType.football: '⚽',
  MeetupType.basketball: '🏀',
  MeetupType.volleyball: '🏐',
  MeetupType.tennis: '🎾',
  MeetupType.tableTennis: '🏓',
  MeetupType.badminton: '🏸',
  MeetupType.swimming: '🏊',
  MeetupType.running: '🏃',
  MeetupType.cycling: '🚴',
  MeetupType.hiking: '🥾',
  MeetupType.yoga: '🧘',
  MeetupType.fitness: '💪',
  MeetupType.boxing: '🥊',
  MeetupType.climbing: '🧗',
  MeetupType.skiing: '⛷️',
  MeetupType.other: '🏅',
};
