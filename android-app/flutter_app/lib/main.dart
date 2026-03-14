import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/planner_state.dart';
import 'features/admin/timetable_dashboard_screen.dart';
import 'features/auth/auth_gate.dart';

final AppDatabase _db = AppDatabase();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartTimeApp());
}

class SmartTimeApp extends StatelessWidget {
  const SmartTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlannerState>(
      create: (_) => PlannerState(_db),
      child: MaterialApp(
        title: 'SmartTime AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const TimetableDashboardScreen(),
      ),
    );
  }
}

class AppHomeScreen extends StatelessWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartTime AI')),
      body: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Firebase init failed:\n${snap.error}'),
              ),
            );
          }
          return const AuthGate();
        },
      ),
    );
  }
}
