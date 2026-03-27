import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/database.dart';
import '../../core/theme/app_theme.dart';
import '../timetable/data/conflict_service.dart';
import '../timetable/data/native_solver_client.dart';
import '../timetable/data/solver_payload_mapper.dart';
import '../timetable/presentation/controllers/solver_controller.dart';
import '../timetable/presentation/screens/cockpit_screen.dart';
import 'planner_state.dart';

class GenerationProgressScreen extends StatefulWidget {
  const GenerationProgressScreen({super.key});

  @override
  State<GenerationProgressScreen> createState() => _GenerationProgressScreenState();
}

class _GenerationProgressScreenState extends State<GenerationProgressScreen>
    with TickerProviderStateMixin {
  late final SolverController _solver;
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  
  _SolverPhase _phase = _SolverPhase.validating;
  double _progress = 0.0;
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
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _syncPlannerToDatabase(PlannerState planner) async {
    final db = planner.db;
    if (db == null) return;

    // Subjects
    for (final s in planner.subjects) {
      await db.into(db.subjects).insertOnConflictUpdate(
        SubjectsCompanion.insert(
          id: s.id,
          guid: Value(s.id),
          name: s.name,
          abbr: s.abbr,
          color: Value(s.color),
          groupId: Value(s.relationshipGroupKey),
        ),
      );
    }

    // Teachers
    for (final t in planner.teachers) {
      await db.into(db.teachers).insertOnConflictUpdate(
        TeachersCompanion.insert(
          id: t.id,
          guid: Value(t.id),
          name: t.fullName,
          abbreviation: t.abbr,
          maxGapsPerDay: Value(t.maxGapsPerDay),
        ),
      );
    }

    // Classes & Divisions
    for (final c in planner.classes) {
      await db.into(db.classes).insertOnConflictUpdate(
        ClassesCompanion.insert(
          id: c.id,
          guid: Value(c.id),
          name: c.name,
          abbr: c.abbr,
        ),
      );
      for (final d in c.divisions) {
        await db.into(db.divisions).insertOnConflictUpdate(
          DivisionsCompanion.insert(
            id: d.id,
            classId: c.id,
            name: d.name,
          ),
        );
      }
    }

    // Lessons
    for (final l in planner.lessons) {
      await db.into(db.lessons).insertOnConflictUpdate(
        LessonsCompanion.insert(
          id: l.id,
          subjectId: l.subjectId,
          periodsPerWeek: Value(l.countPerWeek),
          teacherIds: Value(l.teacherIds),
          classIds: Value(l.classIds),
          classDivisionId: Value(l.classDivisionId),
          isPinned: Value(l.isPinned),
          fixedDay: Value(l.fixedDay),
          fixedPeriod: Value(l.fixedPeriod),
          roomTypeId: Value(l.roomTypeId),
          relationshipType: Value(l.relationshipType),
          relationshipGroupKey: Value(l.relationshipGroupKey),
        ),
      );
    }
  }

  Future<void> _run() async {
    final planner = context.read<PlannerState>();
    setState(() {
      _cleanError = null;
      _completed = false;
      _phase = _SolverPhase.validating;
      _progress = 0.0;
    });

    // Phase 1: Validating
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _phase = _SolverPhase.seeding;
      _progress = 0.15;
    });
    _ringController.animateTo(0.15, curve: Curves.easeOut);

    // Phase 2: Seeding
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _phase = _SolverPhase.solving;
      _progress = 0.3;
    });
    _ringController.animateTo(0.3, curve: Curves.easeOut);

    // Sync Draft to Relational Tables first (required for Cards DB inserts and Cockpit view)
    await _syncPlannerToDatabase(planner);

    // Run the Dart solver
    await _solver.runDartSolver(planner);
    if (!mounted) return;

    final rawError = _solver.error;
    if (rawError != null && rawError.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to generate timetable. Check the error below.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() {
        _cleanError = _friendlyError(rawError);
        _completed = false;
        _progress = _ringController.value;
      });
      return;
    }

    // Phase 3: Optimizing — persist results to DB
    setState(() {
      _phase = _SolverPhase.optimizing;
      _progress = 0.85;
    });
    await _ringController.animateTo(0.85, curve: Curves.easeOut);

    // ── PERSIST solver assignments to the cards DB table ──
    final db = planner.db;
    if (db != null && _solver.assignments.isNotEmpty) {
      try {
        // Clear old cards first
        await db.delete(db.cards).go();

        // Build a map from lesson ID to the planner lesson
        final lessonMap = <String, dynamic>{};
        for (final l in planner.lessons) {
          for (int k = 0; k < l.countPerWeek; k++) {
            lessonMap['${l.id}_$k'] = l;
          }
        }

        for (final a in _solver.assignments) {
          final lastUnderscore = a.lessonId.lastIndexOf('_');
          final originalId = lastUnderscore != -1 ? a.lessonId.substring(0, lastUnderscore) : a.lessonId;
          
          await db.into(db.cards).insert(
            CardsCompanion.insert(
              id: '${originalId}_${a.day}_${a.period}',
              lessonId: originalId,
              dayIndex: a.day,     // solver slots are already 0-indexed
              periodIndex: a.period,
              roomId: Value(a.roomId.isEmpty ? null : a.roomId),
            ),
          );
        }
        debugPrint('--- PERSISTED ${_solver.assignments.length} cards to DB ---');
      } catch (e, st) {
        debugPrint('--- DB PERSIST ERROR: $e ---\n$st');
        if (mounted) {
          setState(() {
            _cleanError = 'Database error while saving schedule. Check logs.';
            _completed = false;
          });
        }
        return;
      }
    }
    if (!mounted) return;

    // Done!
    planner.markTimetableGenerated();
    setState(() {
      _phase = _SolverPhase.done;
      _progress = 1.0;
      _completed = true;
    });
    _ringController.animateTo(1.0, curve: Curves.easeOutCubic);
    _pulseController.stop();
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    
    // Custom constraint intercepts based on Card Relationships logic
    if (lower.contains('consecutive limit exceeded') || lower.contains('maxconsecutive')) {
      return 'Constraint Violation: A class or teacher exceeded their maximum consecutive periods limit. Check your Global Constraints or add more breaks.';
    }
    if (lower.contains('dailylimit') || lower.contains('distribution')) {
      return 'Constraint Violation: Subject daily limits were breached. Check if "Card distribution over the week" rules are too strict for the available days.';
    }
    
    if (lower.contains('double booking') ||
        lower.contains('fatal') ||
        lower.contains('halt') ||
        lower.contains('illegalstateexception')) {
      return 'Conflicting constraints detected (double-booked teachers or overlapping requirements). Please adjust lessons, teacher availability, or class assignments.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _cleanError != null
        ? AppTheme.errorRed
        : _completed
            ? AppTheme.successGreen
            : AppTheme.motherSage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generating Timetable'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated Progress Ring ──
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_ringController, _pulseController]),
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: _ringController.value,
                        pulseValue: _completed ? 0.0 : _pulseController.value,
                        color: statusColor,
                        hasError: _cleanError != null,
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _completed
                                ? Icons.check_circle_rounded
                                : _cleanError != null
                                    ? Icons.error_outline_rounded
                                    : Icons.auto_awesome_rounded,
                            key: ValueKey(_completed ? 'done' : _cleanError != null ? 'error' : 'working'),
                            size: 40,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Phase Label ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _phase.label,
                  key: ValueKey(_phase),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _phase.description,
                  key: ValueKey('desc_${_phase.name}'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.espresso.withOpacity(0.6),
                      ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Phase Steps ──
              _PhaseStepIndicator(currentPhase: _phase, hasError: _cleanError != null),
              const SizedBox(height: 32),

              // ── Error Card ──
              if (_cleanError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Conflict Detected',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _cleanError!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _run,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Back to Setup'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── Success Card ──
              if (_completed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.successGreen.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Timetable Generated!',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_solver.assignments.length} lessons scheduled successfully.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_solver.variants.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${_solver.variants.length} variant(s) generated for comparison.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final planner = context.read<PlannerState>();
                            final db = planner.db;
                            if (db == null) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => CockpitScreen(db: db, dbId: planner.dbId)),
                            );
                          },
                          icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
                          label: const Text('View Timetable'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Solver Phases ──
enum _SolverPhase {
  validating('Validating Input', 'Checking teachers, classes, and lesson data...'),
  seeding('Seeding Schedule', 'Creating initial timetable using greedy heuristic...'),
  solving('Solving Constraints', 'Running AC-3 backtracking solver with MRV...'),
  optimizing('Optimizing Quality', 'Simulated annealing to minimize teacher gaps...'),
  done('Complete', 'Your timetable is ready for review.');

  const _SolverPhase(this.label, this.description);
  final String label;
  final String description;
}

// ── Phase Step Indicator ──
class _PhaseStepIndicator extends StatelessWidget {
  const _PhaseStepIndicator({required this.currentPhase, required this.hasError});
  final _SolverPhase currentPhase;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final phases = _SolverPhase.values.where((p) => p != _SolverPhase.done).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < phases.length; i++) ...[
          _PhaseStep(
            label: phases[i].label.split(' ').first,
            isActive: currentPhase.index >= phases[i].index,
            isComplete: currentPhase.index > phases[i].index,
            hasError: hasError && currentPhase == phases[i],
          ),
          if (i < phases.length - 1)
            Container(
              width: 24,
              height: 2,
              color: currentPhase.index > phases[i].index
                  ? AppTheme.motherSage
                  : AppTheme.espresso.withOpacity(0.15),
            ),
        ],
      ],
    );
  }
}

class _PhaseStep extends StatelessWidget {
  const _PhaseStep({
    required this.label,
    required this.isActive,
    required this.isComplete,
    required this.hasError,
  });

  final String label;
  final bool isActive;
  final bool isComplete;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final color = hasError
        ? AppTheme.errorRed
        : isComplete
            ? AppTheme.successGreen
            : isActive
                ? AppTheme.motherSage
                : AppTheme.espresso.withOpacity(0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete || isActive
                ? color.withOpacity(0.12)
                : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isComplete
                ? Icon(Icons.check_rounded, size: 16, color: color)
                : hasError
                    ? Icon(Icons.close_rounded, size: 16, color: color)
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? color : Colors.transparent,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Progress Ring Painter ──
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.pulseValue,
    required this.color,
    required this.hasError,
  });

  final double progress;
  final double pulseValue;
  final Color color;
  final bool hasError;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Pulse glow (only while working)
    if (pulseValue > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.06 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, glowPaint);
    }

    // Progress arc
    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      progress != old.progress || pulseValue != old.pulseValue || color != old.color;
}
