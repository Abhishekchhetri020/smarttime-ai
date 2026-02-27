import { db } from '../lib/firebase';

export async function publishTimetable(schoolId: string, versionId: string, actorId: string) {
  const col = db.collection('schools').doc(schoolId).collection('timetables');
  const now = Date.now();

  // archive currently published
  const published = await col.where('status', '==', 'published').get();
  const batch = db.batch();
  published.docs.forEach((d) => {
    batch.set(d.ref, { status: 'archived', archivedAt: now, archivedBy: actorId }, { merge: true });
  });

  const targetRef = col.doc(versionId);
  batch.set(targetRef, { status: 'published', publishedAt: now, publishedBy: actorId }, { merge: true });
  await batch.commit();

  return { versionId, status: 'published', publishedAt: now };
}
