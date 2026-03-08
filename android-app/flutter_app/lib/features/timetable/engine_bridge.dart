import 'package:flutter/services.dart';

class EnginePayload {
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> rooms;
  final List<Map<String, dynamic>> lessons;

  const EnginePayload({
    required this.teachers,
    required this.classes,
    required this.rooms,
    required this.lessons,
  });

  Map<String, dynamic> toMap() => {
        'teachers': teachers,
        'classes': classes,
        'rooms': rooms,
        'lessons': lessons,
      };
}

class EngineBridge {
  static const MethodChannel _channel = MethodChannel('com.smarttime.ai/engine');

  static Future<Map<String, dynamic>> triggerSolver(EnginePayload payload) async {
    final response = await _channel.invokeMethod<dynamic>(
      'solve_timetable',
      payload.toMap(),
    );
    if (response is Map) {
      return response.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{
      'status': 'error',
      'message': 'Engine returned non-map response',
      'cards': const <Map<String, dynamic>>[],
    };
  }
}
