import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bildirim ayarları yakında eklenecek!'),
                    ),
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
}
