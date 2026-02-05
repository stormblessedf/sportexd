import 'package:flutter/material.dart';

enum AttendanceStatus { notSelected, attended, noShow }

class AttendanceToggle extends StatelessWidget {
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  const AttendanceToggle({
    super.key,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Cycle through states: notSelected -> attended -> noShow -> notSelected
        switch (status) {
          case AttendanceStatus.notSelected:
            onChanged(AttendanceStatus.attended);
            break;
          case AttendanceStatus.attended:
            onChanged(AttendanceStatus.noShow);
            break;
          case AttendanceStatus.noShow:
            onChanged(AttendanceStatus.attended);
            break;
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            // Swiped right -> attended
            onChanged(AttendanceStatus.attended);
          } else {
            // Swiped left -> noShow
            onChanged(AttendanceStatus.noShow);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 32,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Label
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: status == AttendanceStatus.attended ? 0 : 24,
                    right: status == AttendanceStatus.noShow ? 0 : 24,
                  ),
                  child: Text(
                    _getLabelText(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _getLabelColor(),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            // Thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: _getThumbPosition(),
              top: 3,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getThumbIcon(),
                    size: 14,
                    color: _getThumbIconColor(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case AttendanceStatus.attended:
        return const Color(0xFF13EC5B);
      case AttendanceStatus.noShow:
        return const Color(0xFFEF4444);
      case AttendanceStatus.notSelected:
        return Colors.grey[300]!;
    }
  }

  String _getLabelText() {
    switch (status) {
      case AttendanceStatus.attended:
        return 'GELDİ';
      case AttendanceStatus.noShow:
        return 'GELMEDİ';
      case AttendanceStatus.notSelected:
        return '';
    }
  }

  Color _getLabelColor() {
    switch (status) {
      case AttendanceStatus.attended:
        return const Color(0xFF102216);
      case AttendanceStatus.noShow:
        return Colors.white;
      case AttendanceStatus.notSelected:
        return Colors.grey[500]!;
    }
  }

  double _getThumbPosition() {
    switch (status) {
      case AttendanceStatus.attended:
        return 80 - 26 - 3; // Right side
      case AttendanceStatus.noShow:
        return 3; // Left side
      case AttendanceStatus.notSelected:
        return (80 - 26) / 2; // Center
    }
  }

  IconData _getThumbIcon() {
    switch (status) {
      case AttendanceStatus.attended:
        return Icons.check;
      case AttendanceStatus.noShow:
        return Icons.close;
      case AttendanceStatus.notSelected:
        return Icons.drag_handle;
    }
  }

  Color _getThumbIconColor() {
    switch (status) {
      case AttendanceStatus.attended:
        return const Color(0xFF13EC5B);
      case AttendanceStatus.noShow:
        return const Color(0xFFEF4444);
      case AttendanceStatus.notSelected:
        return Colors.grey[400]!;
    }
  }
}
