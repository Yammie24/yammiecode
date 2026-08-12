import 'package:flutter/material.dart';

import 'screens/ide_screen.dart';

void main() {
  runApp(const YammieCodeApp());
}

class YammieCodeApp extends StatelessWidget {
  const YammieCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YammieCode',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color(0xFF0D1117),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3776AB),
          brightness: Brightness.dark,
        ),
      ),
      home: const IDEScreen(),
    );
  }
}
