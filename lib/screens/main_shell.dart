import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Local UI state: only the shell uses it, so setState (not Provider).
  int _currentIndex = 0; // 0 = Home, 1 = Saved, 2 = Profile

  void _goToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all tabs alive (only hides them),
      // so Home's initState runs once and products are not reloaded.
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          // Callback: Saved reports "Browse pressed", the shell changes the tab.
          SavedScreen(onBrowse: () => _goToTab(0)),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
