import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HabiteeApp());
}

class HabiteeApp extends StatelessWidget {
  const HabiteeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'habitee',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
