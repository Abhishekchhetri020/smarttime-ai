import 'package:flutter/material.dart';
import 'features/auth/auth_gate.dart';

void main() {
  runApp(const SmartTimeApp());
}

class SmartTimeApp extends StatelessWidget {
  const SmartTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTime AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3D91)),
        useMaterial3: true,
      ),
      home: const AppHomeScreen(),
    );
  }
}

class AppHomeScreen extends StatelessWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartTime AI')),
      body: const Center(child: AuthGate()),
    );
  }
}
