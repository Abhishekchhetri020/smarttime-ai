import 'package:flutter/services.dart';

import 'offline_solver_models.dart';

class OfflineSolverChannel {
  static const MethodChannel _channel =
      MethodChannel('smarttime/offline_solver');

  Future<OfflineSolverResult> solve(Map<String, dynamic> payload) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
        'solveTimetable', payload);
    if (raw == null) {
      throw PlatformException(
          code: 'null_result', message: 'Offline solver returned empty result');
    }
    return OfflineSolverResult.fromJson(raw);
  }
}
