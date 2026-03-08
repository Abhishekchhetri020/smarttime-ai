import 'package:flutter/services.dart';

enum SolverStatus {
  success,
  seedFound,
  seedNotFound,
  seedTimeout,
  seedInfeasibleInput,
  optTimeout,
  invalidPayload,
  unsupportedPayloadVersion,
  internalSolverError,
  unknown,
}

class NativeSolverResponse {
  final SolverStatus status;
  final String rawStatus;
  final String? phase;
  final Map<String, dynamic> raw;
  final String? errorCode;
  final String? errorMessage;

  const NativeSolverResponse({
    required this.status,
    required this.rawStatus,
    required this.raw,
    this.phase,
    this.errorCode,
    this.errorMessage,
  });

  bool get isOk =>
      status == SolverStatus.success ||
      status == SolverStatus.seedFound ||
      status == SolverStatus.optTimeout;
}

class NativeSolverClient {
  static const MethodChannel _channel = MethodChannel('smarttime/offline_solver');

  Future<NativeSolverResponse> solve(Map<String, dynamic> payload) async {
    final raw = await _invoke('solveTimetable', payload);
    return _decode(raw);
  }

  Future<Map<String, dynamic>> _invoke(
    String method,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(method, payload);
      if (res == null) {
        return {
          'status': 'INTERNAL_SOLVER_ERROR',
          'error': {'code': 'NULL_RESPONSE', 'message': 'Native solver returned null'}
        };
      }
      return Map<String, dynamic>.from(res);
    } on PlatformException catch (e) {
      return {
        'status': 'INTERNAL_SOLVER_ERROR',
        'error': {'code': e.code, 'message': e.message ?? 'PlatformException'}
      };
    } catch (e) {
      return {
        'status': 'INTERNAL_SOLVER_ERROR',
        'error': {'code': 'DART_EXCEPTION', 'message': e.toString()}
      };
    }
  }

  NativeSolverResponse _decode(Map<String, dynamic> raw) {
    final rawStatus = (raw['status'] ?? 'UNKNOWN').toString();
    final err = raw['error'] is Map ? Map<String, dynamic>.from(raw['error']) : null;

    return NativeSolverResponse(
      status: _mapStatus(rawStatus),
      rawStatus: rawStatus,
      phase: raw['phase']?.toString(),
      raw: raw,
      errorCode: err?['code']?.toString(),
      errorMessage: err?['message']?.toString(),
    );
  }

  SolverStatus _mapStatus(String s) {
    switch (s) {
      case 'SUCCESS':
        return SolverStatus.success;
      case 'SEED_FOUND':
        return SolverStatus.seedFound;
      case 'SEED_NOT_FOUND':
        return SolverStatus.seedNotFound;
      case 'SEED_TIMEOUT':
        return SolverStatus.seedTimeout;
      case 'SEED_INFEASIBLE_INPUT':
        return SolverStatus.seedInfeasibleInput;
      case 'OPT_TIMEOUT':
        return SolverStatus.optTimeout;
      case 'INVALID_PAYLOAD':
        return SolverStatus.invalidPayload;
      case 'UNSUPPORTED_PAYLOAD_VERSION':
        return SolverStatus.unsupportedPayloadVersion;
      case 'INTERNAL_SOLVER_ERROR':
        return SolverStatus.internalSolverError;
      default:
        return SolverStatus.unknown;
    }
  }
}
