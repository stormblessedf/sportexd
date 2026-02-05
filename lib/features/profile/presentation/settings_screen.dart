import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/map_preferences_service.dart';
import '../../../core/models/user_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: FutureBuilder<UserModel?>(
        future: authService.getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          return ListView(
            children: [
              // Account Section
              _buildSectionHeader('Hesap'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profili Düzenle'),
                subtitle: const Text('Bilgilerinizi güncelleyin'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: user != null
                    ? () async {
                        final result =
                            await context.push('/edit-profile', extra: user);
                        if (result == true) {
                          // Refresh if needed
                        }
                      }
                    : null,
              ),
              const Divider(),

              // Privacy Section
              _buildSectionHeader('Gizlilik'),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Şifre Değiştir'),
                subtitle: const Text('Hesap güvenliğinizi koruyun'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Şifre değiştirme yakında eklenecek!'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gizlilik Ayarları'),
                subtitle: const Text('Kim sizi görebilir?'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gizlilik ayarları yakında eklenecek!'),
                    ),
                  );
                },
              ),
              const Divider(),

              // Notifications Section
              _buildSectionHeader('Bildirimler'),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Bildirim Ayarları'),
                subtitle: const Text('Hangi bildirimleri almak istersiniz?'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/notification-settings');
                },
              ),
              const Divider(),

              // Appearance Section
              _buildSectionHeader('Görünüm'),
              Consumer<MapPreferencesService>(
                builder: (context, mapPrefs, _) {
                  return ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('Harita Stili'),
                    subtitle: Text(mapPrefs.currentStyle.displayName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showMapStylePicker(context, mapPrefs),
                  );
                },
              ),
              const Divider(),

              // Support Section
              _buildSectionHeader('Destek'),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Yardım & Destek'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yardım sayfası yakında eklenecek!'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hakkında'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Sporsal',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 Sporsal. Tüm hakları saklıdır.',
                    children: const [
                      SizedBox(height: 16),
                      Text(
                        'Spor tutkunlarını bir araya getiren sosyal platform.',
                      ),
                    ],
                  );
                },
              ),
              const Divider(),

              // Admin Section (for maintenance tasks)
              _buildSectionHeader('Yönetim'),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin İşlemleri'),
                subtitle: const Text('Bakım ve yönetim araçları'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/admin-actions');
                },
              ),
              const Divider(),

              // Logout Section
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text(
                          'Hesabınızdan çıkmak istediğinize emin misiniz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () {
                              authService.signOut();
                              context.go('/login');
                            },
                            child: const Text(
                              'Çıkış Yap',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Çıkış Yap',
                    style: TextStyle(color: Colors.red),
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

  void _showMapStylePicker(BuildContext context, MapPreferencesService mapPrefs) {
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Harita Stili',
                style: TextStyle(
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
                children: MapStyleOption.values.map((style) => RadioListTile<MapStyleOption>(
                  title: Text(style.displayName),
                  subtitle: Text(_getStyleDescription(style)),
                  value: style,
                  activeColor: Theme.of(context).colorScheme.primary,
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _getStyleDescription(MapStyleOption style) {
    switch (style) {
      case MapStyleOption.enhanced:
        return 'Yeşil tonlarında sportif görünüm';
      case MapStyleOption.dark:
        return 'Gece kullanımı için karanlık tema';
      case MapStyleOption.light:
        return 'Klasik açık renkli harita';
      case MapStyleOption.minimal:
        return 'Sade ve temiz görünüm';
    }
  }
}
