import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/theme/app_theme.dart';
import '../data/statistics_service.dart';
import '../models/user_statistics_model.dart';
import 'widgets/summary_card.dart';
import 'widgets/sport_distribution_chart.dart';
import 'widgets/activity_trend_chart.dart';
import 'widgets/reliability_trend_chart.dart';
import 'widgets/partner_growth_chart.dart';
import '../../../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  final String userId;

  const StatisticsScreen({super.key, required this.userId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();

  UserStatisticsModel? _statistics;
  String? _username;
  bool _isLoading = false;
  String? _error;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Load username for subtitle
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final username = userDoc.data()?['username'] as String?;

      final stats =
          await _statisticsService.getUserStatistics(widget.userId);
      if (mounted) {
        setState(() {
          _statistics = stats;
          _username = username;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = l10n.statsLoadFailed(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statistics,
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            if (_username != null)
              Text(
                '@$_username',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
          ],
        ),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: Text(l10n.retryButton),
            ),
          ],
        ),
      );
    }

    final stats = _statistics;
    if (stats == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary cards grid (2x2)
            _buildSummaryGrid(stats),
            const SizedBox(height: 16),
            SportDistributionChart(
              sportPercentages: stats.sportPercentages,
              sportDistribution: stats.sportDistribution,
            ),
            const SizedBox(height: 16),
            ActivityTrendChart(
              monthlyActivities: stats.monthlyActivities,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ReliabilityTrendChart(
                    reliabilityScore: stats.reliabilityScore,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PartnerGrowthChart(
                    partnerCount: stats.partnerCount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(UserStatisticsModel stats) {
    final mostSportName =
        stats.mostParticipatedSport?.displayName ?? '-';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        SummaryCard(
          title: l10n.totalEvents,
          value: '${stats.totalMeetups}',
          icon: Icons.event,
          iconColor: AppTheme.primary,
        ),
        SummaryCard(
          title: l10n.mostDone,
          value: mostSportName,
          icon: Icons.sports,
          iconColor: const Color(0xFFFF9800),
        ),
        SummaryCard(
          title: l10n.monthlyAverage,
          value: stats.averageMonthlyParticipation.toStringAsFixed(1),
          icon: Icons.trending_up,
          iconColor: const Color(0xFF4CAF50),
        ),
        SummaryCard(
          title: l10n.partnersShort,
          value: '${stats.partnerCount}',
          icon: Icons.people,
          iconColor: const Color(0xFF2196F3),
        ),
      ],
    );
  }
}


