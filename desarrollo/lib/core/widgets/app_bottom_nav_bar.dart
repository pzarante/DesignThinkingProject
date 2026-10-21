import 'package:flutter/material.dart';

import '../app_keys.dart';

/// Main navigation bar shared by the top-level destinations of the app.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 72,
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          key: AppKeys.navHome,
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        NavigationDestination(
          key: AppKeys.navExplore,
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Explorar',
        ),
        NavigationDestination(
          key: AppKeys.navMyProjects,
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Mis Proyectos',
        ),
        NavigationDestination(
          key: AppKeys.navProfile,
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
