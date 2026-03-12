import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../timetable/data/conflict_service.dart';
import '../timetable/data/native_solver_client.dart';
import '../timetable/data/solver_payload_mapper.dart';
import '../timetable/presentation/controllers/solver_controller.dart';
import 'planner_state.dart';

class GenerationProgressScreen extends StatefulWidget {
  const GenerationProgressScreen({super.key});

  @override
  State<GenerationProgressScreen> createState() => _GenerationProgressScreenState();
}

class _GenerationProgressScreenState extends State<GenerationProgressScreen> {
  late final SolverController _solver;
  int _activeStep = 0;
  bool _completed = false;
  String? _cleanError;

  @override
  void initState() {
    super.initState();
    _solver = SolverController(
      client: NativeSolverClient(),
      mapper: SolverPayloadMapper(),
      conflictService: ConflictService(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final planner = context.read<PlannerState>();
    setState(() {
      _cleanError = null;
      _completed = false;
      _activeStep = 0;
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _activeStep = 1);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _activeStep = 2);

    await _solver.run(planner);
    if (!mounted) return;

    final rawError = _solver.error;
    if (rawError != null && rawError.isNotEmpty) {
      setState(() {
        _cleanError = _friendlyError(rawError);
        _completed = false;
      });
      return;
    }

    setState(() {
      _activeStep = 2;
      _completed = true;
    });
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('critical: double booking detected')) {
      return 'Generation stopped because a teacher was double-booked in the same day/period. Please review lessons and teacher assignments, then try again.';
    }
    if (lower.contains('illegalstateexception')) {
      return 'Generation stopped because the solver detected an invalid scheduling state. Please review your timetable inputs and try again.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generating Timetable')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Generation Progress',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Stepper(
            currentStep: _completed ? 2 : _activeStep,
            controlsBuilder: (_, __) => const SizedBox.shrink(),
            steps: [
              Step(
                title: const Text('Validating input'),
                content: const Text('Checking that core timetable data is present and ready.'),
                isActive: _activeStep >= 0,
                state: _stepState(0),
              ),
              Step(
                title: const Text('Checking constraints'),
                content: const Text('Preparing teacher, class, and lesson constraints for the solver.'),
                isActive: _activeStep >= 1,
                state: _stepState(1),
              ),
              Step(
                title: const Text('Optimizing schedule'),
                content: const Text('Running the native solver and building the timetable output.'),
                isActive: _activeStep >= 2,
                state: _stepState(2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cleanError != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generation failed',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _cleanError!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton(
                          onPressed: _run,
                          child: const Text('Retry'),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Back to setup'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (_completed)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generation complete', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Assigned lessons: ${_solver.assignments.length}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to setup'),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Expanded(child: Text('Working through validation and solver stages...')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  StepState _stepState(int step) {
    if (_cleanError != null && _activeStep == step) return StepState.error;
    if (_completed || _activeStep > step) return StepState.complete;
    if (_activeStep == step) return StepState.editing;
    return StepState.indexed;
  }
}
