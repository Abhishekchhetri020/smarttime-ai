import 'offline_solver_models.dart';

class OfflineSolverViewState {
  final bool isLoading;
  final String? message;
  final OfflineSolverResult? result;

  const OfflineSolverViewState({
    required this.isLoading,
    this.message,
    this.result,
  });

  const OfflineSolverViewState.idle() : this(isLoading: false);

  OfflineSolverViewState copyWith({
    bool? isLoading,
    String? message,
    OfflineSolverResult? result,
    bool clearMessage = false,
    bool clearResult = false,
  }) {
    return OfflineSolverViewState(
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : (message ?? this.message),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}
