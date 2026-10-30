import 'package:flutter/material.dart';

import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/me_screen.dart';
import 'screens/polls_screen.dart';
import 'screens/updates_screen.dart';
import 'widgets/ad_slot.dart';

void main() {
  runApp(const ChitradurgaLiveApp());
}

class ChitradurgaLiveApp extends StatelessWidget {
  const ChitradurgaLiveApp({super.key});

  static const _brandRed = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chitradurga Live',
      debugShowCheckedModeBanner: false,
      // Always light, even when the phone is in dark mode.
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _brandRed, brightness: Brightness.light),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF15171C),
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandRed,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainShell(),
    );
  }
}

/// Bottom menu: Home, Events, Updates, Polls and Me, with an ad strip above it.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          EventsScreen(),
          const UpdatesScreen(),
          PollsScreen(),
          MeScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdSlot(height: 48),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.temple_hindu_outlined),
                selectedIcon: Icon(Icons.temple_hindu),
                label: 'Events',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Updates',
              ),
              NavigationDestination(
                icon: Icon(Icons.poll_outlined),
                selectedIcon: Icon(Icons.poll),
                label: 'Polls',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Me',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
