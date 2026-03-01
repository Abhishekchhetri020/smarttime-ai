import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../timetable/offline_solver_channel.dart';
import '../timetable/offline_solver_models.dart';
import '../timetable/offline_solver_diagnostics_view.dart';
import 'planner_state.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _channel = OfflineSolverChannel();
  bool _loading = false;
  String _status = '';
  OfflineSolverResult? _result;

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _status = '';
      _result = null;
    });

    try {
      final planner = context.read<PlannerState>();
      final payload = planner.toSolverPayload();
      final result = await _channel.solve(payload);
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = 'Generation complete: ${result.status}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Generate failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Timetable')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Compile full local payload and run solver bridge.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _generate,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Generate Now'),
            ),
            if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_status),
            ],
            if (_result != null) ...[
              const SizedBox(height: 12),
              OfflineSolverDiagnosticsView(result: _result!),
            ]
          ],
        ),
      ),
    );
  }
}
