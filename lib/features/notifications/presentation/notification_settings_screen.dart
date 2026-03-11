import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/notification_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationPreferences _preferences = NotificationPreferences();
  bool _isLoading = true;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await context.read<NotificationService>().getPreferences();
    if (mounted) {
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences(NotificationPreferences newPrefs) async {
    setState(() => _preferences = newPrefs);
    await context.read<NotificationService>().updatePreferences(newPrefs);
  }

  Future<void> _pickQuietHoursStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferences.quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (picked != null) {
      _updatePreferences(_preferences.copyWith(quietHoursStart: picked));
    }
  }

  Future<void> _pickQuietHoursEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferences.quietHoursEnd ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked != null) {
      _updatePreferences(_preferences.copyWith(quietHoursEnd: picked));
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return l10n.setLabel;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(l10n.notificationSettings),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Mute All
          _buildSectionHeader(l10n.generalSection),
          _buildSwitchTile(
            icon: Icons.notifications_off,
            iconColor: Colors.red,
            title: l10n.muteAllNotifications,
            subtitle: l10n.muteAllNotificationsSubtitle,
            value: _preferences.muteAll,
            onChanged: (value) {
              _updatePreferences(_preferences.copyWith(muteAll: value));
            },
          ),
          const Divider(height: 1),

          // Notification Types
          _buildSectionHeader(l10n.notificationTypes),
          _buildSwitchTile(
            icon: Icons.access_time,
            iconColor: Colors.blue,
            title: l10n.meetupReminders,
            subtitle: l10n.meetupRemindersSubtitle,
            value: _preferences.meetupReminders,
            onChanged: _preferences.muteAll
                ? null
                : (value) {
                    _updatePreferences(_preferences.copyWith(meetupReminders: value));
                  },
          ),
          _buildSwitchTile(
            icon: Icons.update,
            iconColor: Colors.orange,
            title: l10n.meetupUpdates,
            subtitle: l10n.meetupUpdatesSubtitle,
            value: _preferences.meetupUpdates,
            onChanged: _preferences.muteAll
                ? null
                : (value) {
                    _updatePreferences(_preferences.copyWith(meetupUpdates: value));
                  },
          ),
          _buildSwitchTile(
            icon: Icons.chat_bubble,
            iconColor: Colors.purple,
            title: l10n.chatMessages,
            subtitle: l10n.chatMessagesSubtitle,
            value: _preferences.chatMessages,
            onChanged: _preferences.muteAll
                ? null
                : (value) {
                    _updatePreferences(_preferences.copyWith(chatMessages: value));
                  },
          ),
          _buildSwitchTile(
            icon: Icons.person_add,
            iconColor: AppTheme.primary,
            title: l10n.newParticipants,
            subtitle: l10n.newParticipantsSubtitle,
            value: _preferences.newParticipants,
            onChanged: _preferences.muteAll
                ? null
                : (value) {
                    _updatePreferences(_preferences.copyWith(newParticipants: value));
                  },
          ),
          _buildSwitchTile(
            icon: Icons.info,
            iconColor: Colors.grey,
            title: l10n.systemNotifications,
            subtitle: l10n.systemNotificationsSubtitle,
            value: _preferences.systemNotifications,
            onChanged: _preferences.muteAll
                ? null
                : (value) {
                    _updatePreferences(_preferences.copyWith(systemNotifications: value));
                  },
          ),
          const Divider(height: 1),

          // Quiet Hours
          _buildSectionHeader(l10n.quietHours),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.quietHoursSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          _buildTimeTile(
            icon: Icons.bedtime,
            title: l10n.startLabel,
            time: _preferences.quietHoursStart,
            onTap: _pickQuietHoursStart,
          ),
          _buildTimeTile(
            icon: Icons.wb_sunny,
            title: l10n.endLabel,
            time: _preferences.quietHoursEnd,
            onTap: _pickQuietHoursEnd,
          ),
          if (_preferences.quietHoursStart != null || _preferences.quietHoursEnd != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextButton(
                onPressed: () {
                  _updatePreferences(_preferences.copyWith(
                    quietHoursStart: null,
                    quietHoursEnd: null,
                  ));
                },
                child: Text(l10n.clearQuietHours),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: onChanged == null ? Colors.grey : AppTheme.textDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String title,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.indigo, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: TextButton(
        onPressed: onTap,
        child: Text(
          _formatTime(time),
          style: TextStyle(
            color: time != null ? AppTheme.primary : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

