import 'package:flutter/material.dart';

import 'screens/coming_soon.dart';
import 'screens/events_screen.dart';
import 'screens/helplines_screen.dart';
import 'screens/home_screen.dart';
import 'screens/polls_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _brandRed),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF15171C),
          elevation: 0.5,
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

/// Bottom menu. Sections not built yet show a short note.
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
        children: const [
          HomeScreen(),
          EventsScreen(),
          PollsScreen(),
          HelplinesScreen(),
          ComingSoonScreen(
            title: 'Me',
            note: 'Sign in, your profile and your posts are coming in the next update.',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.temple_hindu_outlined),
            selectedIcon: Icon(Icons.temple_hindu),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.poll_outlined),
            selectedIcon: Icon(Icons.poll),
            label: 'Polls',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Helplines',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
