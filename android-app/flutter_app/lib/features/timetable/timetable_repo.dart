import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableRepo {
  final _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getPublishedEntries(String schoolId, String _unused) async {
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
        .collection('schools').doc(schoolId)
        .collection('timetables').doc(latestId)
        .collection('entries').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
