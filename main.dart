import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

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
      home: const HomeScreen(),
    );
  }
}
