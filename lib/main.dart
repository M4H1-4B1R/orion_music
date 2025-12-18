import 'package:flutter/material.dart';
import 'screens/music_player_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: false,
      debugShowCheckedModeBanner: false, // Removes the debug ribbon
      theme: ThemeData.dark(),
      home: const MusicPlayerScreen(),
    );
  }
}
