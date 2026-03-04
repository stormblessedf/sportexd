import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attendance_record_model.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/proximity_attendance_service.dart';
import '../../../theme/app_theme.dart';

class ReliabilityDetailScreen extends StatefulWidget {
  final String userId;
  final double reliabilityScore;

  const ReliabilityDetailScreen({
    super.key,
    required this.userId,
    required this.reliabilityScore,
  });

  @override
  State<ReliabilityDetailScreen> createState() => _ReliabilityDetailScreenState();
}

class _ReliabilityDetailScreenState extends State<ReliabilityDetailScreen> {
  final ProximityAttendanceService _proximityService = ProximityAttendanceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'attended', 'missed'
  late final bool _isOwnProfile;

  double _liveScore = 0;
  int _totalRegistered = 0;
  int _totalJoined = 0;

  @override
  void initState() {
    super.initState();
    _isOwnProfile = _authService.currentUserId == widget.userId;
    _liveScore = widget.reliabilityScore;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _loadUserStats();
      if (_isOwnProfile) {
        final history = await _proximityService.getAttendanceHistory(widget.userId);
        if (mounted) {
          setState(() => _history = history);
        }
      } else {
        if (mounted) {
          setState(() => _history = []);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserStats() async {
    final doc = await _firestore.collection('users').doc(widget.userId).get();
    final data = doc.data() ?? const <String, dynamic>{};

    final score = (data['reliabilityScore'] as num?)?.toDouble() ?? widget.reliabilityScore;
    final registered = (data['totalMeetupsRegistered'] as num?)?.toInt() ?? 0;
    final joined = (data['totalMeetupsJoined'] as num?)?.toInt() ?? 0;

    if (!mounted) return;
    setState(() {
      _liveScore = score.clamp(0, 100).toDouble();
      _totalRegistered = registered < 0 ? 0 : registered;
      _totalJoined = joined < 0 ? 0 : joined;
    });
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_filter == 'attended') {
      return _history.where((h) => h['didAttend'] == true).toList();
    }
    if (_filter == 'missed') {
      return _history.where((h) => h['didAttend'] == false).toList();
    }
    return _history;
  }

  int get _attendedCount => _totalJoined;
  int get _missedCount {
    final value = _totalRegistered - _totalJoined;
    return value < 0 ? 0 : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
        title: const Text(
          'Guvenilirlik Detayi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildScoreHeader(),
                    const SizedBox(height: 10),
                    _buildStatsRow(),
                    if (_isOwnProfile) ...[
                      const SizedBox(height: 10),
                      _buildFilterChips(),
                      const SizedBox(height: 8),
                      _buildMeetupList(),
                    ] else ...[
                      const SizedBox(height: 8),
                      _buildPublicInfoCard(),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScoreHeader() {
    final score = _liveScore;
    final color = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 50
            ? const Color(0xFFFF9800)
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            '%${score.round()}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Guvenilirlik Puani',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getScoreDescription(score),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getScoreDescription(double score) {
    if (score >= 90) return 'Mukemmel!';
    if (score >= 70) return 'Iyi gidiyorsun.';
    if (score >= 50) return 'Ortalama seviye.';
    return 'Katilim oranin dusuk.';
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildMiniStat(
            icon: Icons.check_circle,
            color: const Color(0xFF4CAF50),
            value: _attendedCount.toString(),
            label: 'Katildim',
          ),
          const SizedBox(width: 12),
          _buildMiniStat(
            icon: Icons.cancel,
            color: const Color(0xFFEF4444),
            value: _missedCount.toString(),
            label: 'Katilmadim',
          ),
          const SizedBox(width: 12),
          _buildMiniStat(
            icon: Icons.assignment_turned_in,
            color: const Color(0xFF2196F3),
            value: _totalRegistered.toString(),
            label: 'Kayitli',
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip('Tumu', 'all'),
          const SizedBox(width: 8),
          _buildChip('Katildim', 'attended'),
          const SizedBox(width: 8),
          _buildChip('Katilmadim', 'missed'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primary : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetupList() {
    final filtered = _filteredHistory;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _filter == 'all'
                  ? 'Henuz sonuclanmis etkinlik yok'
                  : _filter == 'attended'
                      ? 'Katildigin etkinlik bulunamadi'
                      : 'Katilmadigin etkinlik bulunamadi',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final meetup = item['meetup'] as MeetupModel;
        final didAttend = (item['didAttend'] as bool?) ?? false;
        final record = item['record'] as AttendanceRecordModel?;
        return _buildMeetupCard(meetup, didAttend, record);
      },
    );
  }

  Widget _buildPublicInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Detayli etkinlik gecmisi sadece profil sahibine gosterilir. '
          'Guvenilirlik puani ve toplam sayaclar herkese aciktir.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetupCard(MeetupModel meetup, bool didAttend, AttendanceRecordModel? record) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (didAttend) {
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle;
      statusText = 'Katildi';
    } else {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel;
      statusText = 'Katilmadi';
    }

    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(meetup.date);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getSportIcon(meetup.type),
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meetup.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  meetup.locationName,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record != null && record.didAttend && record.distanceMeters != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${record.distanceMeters!.toStringAsFixed(0)}m mesafeden dogrulandi',
                    style: TextStyle(fontSize: 10, color: Colors.green[400]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.volleyball:
        return Icons.sports_volleyball;
      case MeetupType.tennis:
      case MeetupType.tableTennis:
      case MeetupType.badminton:
        return Icons.sports_tennis;
      case MeetupType.swimming:
        return Icons.pool;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.cycling:
        return Icons.directions_bike;
      case MeetupType.hiking:
        return Icons.terrain;
      case MeetupType.yoga:
        return Icons.self_improvement;
      case MeetupType.fitness:
        return Icons.fitness_center;
      case MeetupType.boxing:
        return Icons.sports_mma;
      case MeetupType.climbing:
        return Icons.landscape;
      case MeetupType.skiing:
        return Icons.downhill_skiing;
      default:
        return Icons.sports;
    }
  }
}
