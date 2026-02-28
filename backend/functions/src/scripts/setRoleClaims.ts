import admin from 'firebase-admin';
import fs from 'node:fs';

async function main() {
  const uid = process.argv[2];
  const role = process.argv[3];
  const schoolId = process.argv[4];

  if (!uid || !role || !schoolId) {
    console.error('Usage: ts-node setRoleClaims.ts <uid> <role> <schoolId>');
    process.exit(1);
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_JSON || process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const projectId = process.env.FIREBASE_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT || 'smarttime-ai-1b64f';

  if (!admin.apps.length) {
    if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
      const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId,
      });
    } else {
      // fallback to ADC (works on GCP or when application-default creds are configured)
      admin.initializeApp({ projectId });
    }
  }

  await admin.auth().setCustomUserClaims(uid, { role, schoolId });
  console.log('claims_set', { uid, role, schoolId, projectId });
}

main().catch((e: any) => {
  const msg = String(e?.message || e);
  if (msg.includes('metadata.google.internal') || msg.includes('invalid-credential')) {
    console.error('Credential error: provide service account json via FIREBASE_SERVICE_ACCOUNT_JSON env var.');
    console.error('Example: FIREBASE_SERVICE_ACCOUNT_JSON=/path/key.json FIREBASE_PROJECT_ID=smarttime-ai-1b64f npx ts-node src/scripts/setRoleClaims.ts <uid> incharge demo-school');
  }
  console.error(e);
  process.exit(1);
});
