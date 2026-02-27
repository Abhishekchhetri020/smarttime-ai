import admin from 'firebase-admin';

async function main() {
  const uid = process.argv[2];
  const role = process.argv[3];
  const schoolId = process.argv[4];

  if (!uid || !role || !schoolId) {
    console.error('Usage: ts-node setRoleClaims.ts <uid> <role> <schoolId>');
    process.exit(1);
  }

  if (!admin.apps.length) admin.initializeApp();
  await admin.auth().setCustomUserClaims(uid, { role, schoolId });
  console.log('claims_set', { uid, role, schoolId });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
