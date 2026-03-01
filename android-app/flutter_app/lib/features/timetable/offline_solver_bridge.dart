import 'package:flutter/services.dart';

class OfflineSolverBridge {
  // Keep this exactly in sync with MainActivity.kt
  static const MethodChannel _methodChannel =
      MethodChannel('smarttime/offline_solver');

  static Future<Map<String, dynamic>> solve(
      {required Map<String, dynamic> payload}) async {
    final raw = await _methodChannel.invokeMapMethod<String, dynamic>(
      'solveTimetable',
      payload,
    );

    if (raw == null) {
      throw PlatformException(
        code: 'null_result',
        message: 'Offline solver returned empty result',
      );
    }
    return raw;
  }
}
