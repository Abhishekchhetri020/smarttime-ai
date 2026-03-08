import 'package:flutter/services.dart';

class EnginePayload {
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> lessons;

  const EnginePayload({
    required this.teachers,
    required this.classes,
    required this.lessons,
  });

  Map<String, dynamic> toMap() => {
        'teachers': teachers,
        'classes': classes,
        'lessons': lessons,
      };
}

class EngineBridge {
  static const MethodChannel _channel = MethodChannel('com.smarttime.ai/engine');

  static Future<String> triggerSolver(EnginePayload payload) async {
    final response = await _channel.invokeMethod<String>(
      'solve_timetable',
      payload.toMap(),
    );
    return response ?? 'Engine returned no response';
  }
}
