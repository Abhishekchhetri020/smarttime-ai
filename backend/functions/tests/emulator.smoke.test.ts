import admin from 'firebase-admin';

const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;

(hasEmulator ? describe : describe.skip)('firestore emulator smoke', () => {
  beforeAll(() => {
    if (!admin.apps.length) admin.initializeApp({ projectId: 'smarttime-emulator' });
  });

  it('writes and reads a document', async () => {
    const db = admin.firestore();
    const ref = db.collection('schools').doc('emu-school').collection('teachers').doc('t1');
    await ref.set({ name: 'Teacher 1', createdAt: Date.now() });
    const snap = await ref.get();
    expect(snap.exists).toBe(true);
    expect(snap.data()?.name).toBe('Teacher 1');
  });
});
