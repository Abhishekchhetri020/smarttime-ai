import 'dart:async';
import 'package:flutter/services.dart';

/// Real-time progress data streamed from the Kotlin CSP solver via EventChannel.
class NativeSolverProgress {
  final int nodesVisited;
  final int assignedLessons;
  final int totalLessons;
  final int backtracks;

  const NativeSolverProgress({
    required this.nodesVisited,
    required this.assignedLessons,
    required this.totalLessons,
    required this.backtracks,
  });

  /// Percentage of lessons placed (0.0 → 1.0).
  double get progressFraction =>
      totalLessons > 0 ? assignedLessons / totalLessons : 0.0;

  /// Human-readable status string for the UI.
  String get displayMessage {
    final pct = (progressFraction * 100).toStringAsFixed(0);
    return 'Placing lessons: $pct% ($assignedLessons/$totalLessons)';
  }

  factory NativeSolverProgress.fromMap(Map<dynamic, dynamic> map) {
    return NativeSolverProgress(
      nodesVisited: (map['nodesVisited'] as num?)?.toInt() ?? 0,
      assignedLessons: (map['assignedLessons'] as num?)?.toInt() ?? 0,
      totalLessons: (map['totalLessons'] as num?)?.toInt() ?? 0,
      backtracks: (map['backtracks'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Listens to the Kotlin solver's EventChannel for incremental progress updates.
///
/// Usage:
/// ```dart
/// final stream = SolverProgressStream();
/// stream.listen((progress) {
///   setState(() => _pct = progress.progressFraction);
/// });
/// // After solver completes, dispose:
/// stream.dispose();
/// ```
class SolverProgressStream {
  static const _channel = EventChannel('smarttime/solver_progress');

  StreamSubscription<NativeSolverProgress>? _subscription;

  /// The broadcast stream of progress events.
  /// Multiple listeners can subscribe (e.g. controller + UI widget).
  late final Stream<NativeSolverProgress> stream = _channel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) =>
          NativeSolverProgress.fromMap(event as Map<dynamic, dynamic>));

  /// Convenience: subscribe with a single callback.
  StreamSubscription<NativeSolverProgress> listen(
    void Function(NativeSolverProgress) onData, {
    void Function()? onDone,
    void Function(Object error)? onError,
  }) {
    _subscription = stream.listen(
      onData,
      onDone: onDone,
      onError: onError != null ? (e, _) => onError(e) : null,
    );
    return _subscription!;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
