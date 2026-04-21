import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableRepo {
  final _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getPublishedEntries(
      String schoolId, String ignoredTtId) async {
    final tt = await _db
        .collection('schools')
        .doc(schoolId)
        .collection('timetables')
        .where('status', isEqualTo: 'published')
        .orderBy('publishedAt', descending: true)
        .limit(1)
        .get();

    if (tt.docs.isEmpty) return [];

    final latestId = tt.docs.first.id;
    final snap = await _db
        .collection('schools')
        .doc(schoolId)
        .collection('timetables')
        .doc(latestId)
        .collection('entries')
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<Map<String, dynamic>?> getLatestSolverDiagnostics(
      String schoolId) async {
    final jobs = await _db
        .collection('schools')
        .doc(schoolId)
        .collection('solverJobs')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();

    if (jobs.docs.isEmpty) return null;

    final doc = jobs.docs.first;
    final data = doc.data();
    return {
      'jobId': doc.id,
      'status': data['status'],
      'runDurationMs': data['runDurationMs'],
      'outputSummary': data['outputSummary'],
      'diagnostics': data['diagnostics'],
    };
  }
}
