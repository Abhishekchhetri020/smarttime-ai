import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class OfflineSolverBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.smarttime.ai/offline_solver');
  static const EventChannel _eventChannel = EventChannel('com.smarttime.ai/offline_solver_progress');

  static Stream<Map<String, dynamic>> progressStream() {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is Map) {
        return event.map((key, value) => MapEntry(key.toString(), value));
      }
      return <String, dynamic>{};
    });
  }

  static Future<Map<String, dynamic>> solve({required Map<String, dynamic> payload}) async {
    final raw = await _methodChannel.invokeMethod<String>('solve', <String, dynamic>{
      'payload': jsonEncode(payload),
    });

    if (raw == null || raw.isEmpty) {
      throw PlatformException(code: 'EMPTY_RESULT', message: 'Offline solver returned empty response');
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw PlatformException(code: 'INVALID_RESULT', message: 'Offline solver returned non-object response');
    }
    return decoded;
  }
}
