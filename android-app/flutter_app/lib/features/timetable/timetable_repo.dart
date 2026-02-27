import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableRepo {
  final _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getPublishedEntries(String schoolId, String timetableId) async {
    final snap = await _db
        .collection('schools').doc(schoolId)
        .collection('timetables').doc(timetableId)
        .collection('entries').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
