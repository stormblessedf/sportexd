import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/map_preferences_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/models/user_model.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: FutureBuilder<UserModel?>(
        future: authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;

          return ListView(
            children: [
              _buildSectionHeader(l10n.sectionPremium),
              Consumer<PremiumService>(
                builder: (context, premiumService, _) {
                  final isActive = premiumService.hasActivePremium;
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l10n.premiumSettingsTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isActive
                          ? l10n.premiumSettingsSubtitleActive
                          : l10n.premiumSettingsSubtitleInactive,
                    ),
                    trailing: isActive
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.push('/premium'),
                  );
                },
              ),
              const Divider(),

              _buildSectionHeader(l10n.sectionAccount),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.editProfile),
                subtitle: Text(l10n.editProfileSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: user != null
                    ? () async {
                        await context.push('/edit-profile', extra: user);
                      }
                    : null,
              ),
              const Divider(),

              _buildSectionHeader(l10n.sectionPrivacy),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(l10n.changePassword),
                subtitle: Text(l10n.changePasswordSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.passwordChangeSoon)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.privacySettings),
                subtitle: Text(l10n.privacySettingsSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.privacySettingsSoon)),
                ),
              ),
              const Divider(),

              _buildSectionHeader(l10n.sectionNotifications),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: Text(l10n.notificationSettings),
                subtitle: Text(l10n.notificationSettingsSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/notification-settings'),
              ),
              const Divider(),

              _buildSectionHeader(l10n.sectionAppearance),
              Consumer<MapPreferencesService>(
                builder: (context, mapPrefs, _) => ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(l10n.mapStyle),
                  subtitle: Text(_getStyleName(mapPrefs.currentStyle, l10n)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showMapStylePicker(context, mapPrefs, l10n),
                ),
              ),
              Consumer<LocaleService>(
                builder: (context, localeService, _) {
                  final current = localeService.currentOption;
                  return ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(l10n.appLanguage),
                    subtitle: Text('${current.flag}  ${current.name}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () =>
                        _showLanguagePicker(context, localeService, l10n),
                  );
                },
              ),
              const Divider(),

              _buildSectionHeader(l10n.sectionSupport),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l10n.helpSupport),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.helpSoon))),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutApp),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Sporsal',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 Sporsal.',
                  children: [
                    const SizedBox(height: 16),
                    Text(l10n.aboutAppDescription),
                  ],
                ),
              ),
              const Divider(),

              _buildSectionHeader(l10n.sectionAdmin),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: Text(l10n.adminActions),
                subtitle: Text(l10n.adminActionsSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => context.push('/admin-actions'),
              ),
              const Divider(),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.logoutConfirmTitle),
                      content: Text(l10n.logoutConfirmContent),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () {
                            authService.signOut();
                            context.go('/login');
                          },
                          child: Text(
                            l10n.logout,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    l10n.logout,
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    LocaleService localeService,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _LanguagePickerSheet(
        localeService: localeService,
        title: l10n.appLanguage,
        subtitle: l10n.appLanguageSubtitle,
      ),
    );
  }

  void _showMapStylePicker(
    BuildContext context,
    MapPreferencesService mapPrefs,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.mapStyle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<MapStyleOption>(
              groupValue: mapPrefs.currentStyle,
              onChanged: (MapStyleOption? value) {
                if (value != null) {
                  mapPrefs.setMapStyle(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                children: MapStyleOption.values
                    .map(
                      (style) => RadioListTile<MapStyleOption>(
                        title: Text(_getStyleName(style, l10n)),
                        subtitle: Text(_getStyleDescription(style, l10n)),
                        value: style,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getStyleDescription(MapStyleOption style, AppLocalizations l10n) {
    switch (style) {
      case MapStyleOption.cityNightGold:
        return l10n.mapStyleCityNightGoldDesc;
      case MapStyleOption.enhanced:
        return l10n.mapStyleEnhancedDesc;
      case MapStyleOption.dark:
        return l10n.mapStyleDarkDesc;
      case MapStyleOption.light:
        return l10n.mapStyleLightDesc;
      case MapStyleOption.minimal:
        return l10n.mapStyleMinimalDesc;
    }
  }

  String _getStyleName(MapStyleOption style, AppLocalizations l10n) {
    switch (style) {
      case MapStyleOption.cityNightGold:
        return l10n.mapStyleCityNightGoldName;
      case MapStyleOption.enhanced:
        return l10n.mapStyleEnhancedName;
      case MapStyleOption.dark:
        return l10n.mapStyleDarkName;
      case MapStyleOption.light:
        return l10n.mapStyleLightName;
      case MapStyleOption.minimal:
        return l10n.mapStyleMinimalName;
    }
  }
}

// ── Language Picker Bottom Sheet ──

class _LanguagePickerSheet extends StatefulWidget {
  final LocaleService localeService;
  final String title;
  final String subtitle;

  const _LanguagePickerSheet({
    required this.localeService,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.localeService.locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          ...LocaleService.supportedLocales.map(
            (option) => _LanguageTile(
              option: option,
              isSelected: _selectedCode == option.locale.languageCode,
              onTap: () async {
                setState(() => _selectedCode = option.locale.languageCode);
                await widget.localeService.setLocale(option.locale);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final LocaleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(option.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primary : AppTheme.textDark,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
