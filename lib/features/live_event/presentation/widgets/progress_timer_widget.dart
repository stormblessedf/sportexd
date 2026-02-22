import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sporsal/features/live_event/utils/progress_utils.dart';
import 'package:sporsal/theme/app_theme.dart';

/// Canlı etkinlik ilerleme sayacı widget'ı.
///
/// Her saniye güncellenen ilerleme çubuğu ve kalan süre gösterir.
/// Etkinlik tamamlandığında %100 ve "Etkinlik Tamamlandı" mesajı gösterir.
class ProgressTimerWidget extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;

  const ProgressTimerWidget({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<ProgressTimerWidget> createState() => _ProgressTimerWidgetState();
}

class _ProgressTimerWidgetState extends State<ProgressTimerWidget> {
  Timer? _timer;
  double _progress = 0.0;
  String _remainingTime = '00:00:00';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateProgress();
    });
  }

  @override
  void didUpdateWidget(covariant ProgressTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startTime != widget.startTime ||
        oldWidget.endTime != widget.endTime) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    final now = DateTime.now();
    final progress = calculateProgress(widget.startTime, widget.endTime, now);
    final remaining = widget.endTime.difference(now);
    final completed = progress >= 1.0;

    setState(() {
      _progress = progress;
      _remainingTime = formatRemainingTime(remaining);
      _isCompleted = completed;
    });

    if (completed) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentText = '${(_progress * 100).toInt()}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCompleted ? 'Etkinlik Tamamlandı' : 'Etkinlik Süresi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isCompleted
                      ? AppTheme.primary
                      : AppTheme.textDark,
                ),
              ),
              Text(
                percentText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isCompleted
                      ? AppTheme.primary
                      : AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isCompleted ? AppTheme.primary : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isCompleted ? Icons.check_circle : Icons.timer_outlined,
                size: 18,
                color: _isCompleted
                    ? AppTheme.primary
                    : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _isCompleted ? 'Tamamlandı' : 'Kalan: $_remainingTime',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _isCompleted
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
