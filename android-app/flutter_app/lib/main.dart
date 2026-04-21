import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/my_timetables_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('GLOBAL_ERROR: ${details.exception}');
    debugPrint('STACK_TRACE: ${details.stack}');
  };

  runApp(const SmartTimeApp());
}

class SmartTimeApp extends StatelessWidget {
  const SmartTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartTime AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MyTimetablesScreen(),
    );
  }
}
