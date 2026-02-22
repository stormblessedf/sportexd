import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sporsal/features/profile/presentation/controllers/photo_upload_controller.dart';

class MainShell extends StatefulWidget {
  final Widget navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Kullanıcı kendi profil ekranındaysa true döner.
  /// `/profile` rotası kendi profili; `/profile/:id` başka kullanıcı.
  bool get _isOnOwnProfile {
    final location = GoRouterState.of(context).uri.toString();
    return location == '/profile';
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = _isOnOwnProfile;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: ListenableBuilder(
        listenable: PhotoUploadController.instance,
        builder: (context, _) {
          return NavigationBar(
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (index) =>
                _onItemTapped(index, context, isOwnProfile),
            destinations: _buildDestinations(isOwnProfile),
          );
        },
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(bool isOwnProfile) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Akış',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Sohbetler',
      ),
      const NavigationDestination(
        icon: Icon(Icons.add_circle_outline),
        selectedIcon: Icon(Icons.add_circle),
        label: 'Oluştur',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    if (isOwnProfile) {
      final isUploading = PhotoUploadController.instance.isUploading;
      destinations.add(
        NavigationDestination(
          icon: Icon(
            Icons.add_a_photo_outlined,
            color: isUploading ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.add_a_photo,
            color: isUploading ? Colors.grey : null,
          ),
          label: 'Fotoğraf',
          enabled: !isUploading,
        ),
      );
    }

    return destinations;
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/chats')) return 1;
    if (location.startsWith('/create')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isOwnProfile) {
    // Intercept the 5th button (photo upload action)
    if (isOwnProfile && index == 4) {
      if (!PhotoUploadController.instance.isUploading) {
        PhotoUploadController.instance.triggerUpload();
      }
      return;
    }

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/chats');
        break;
      case 2:
        context.go('/create');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
