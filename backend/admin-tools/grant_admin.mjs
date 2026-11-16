import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const [uid, ...extraArgs] = process.argv.slice(2);
if (!uid || extraArgs.length > 0 || uid.length < 10) {
  console.error('Usage: npm run grant-admin -- <Firebase Auth UID>');
  process.exit(2);
}

const projectId = process.env.FIREBASE_PROJECT_ID ?? 'discoverease-dev';
if (projectId !== 'discoverease-dev') {
  console.error(`Refusing unexpected project: ${projectId}`);
  process.exit(2);
}

try {
  const app = initializeApp({ credential: applicationDefault(), projectId });
  const auth = getAuth(app);
  const user = await auth.getUser(uid);
  await auth.setCustomUserClaims(uid, { ...user.customClaims, admin: true });
  console.log(`Granted admin claim to UID ${uid} in ${projectId}.`);
  console.log('The user must sign out and back in, or refresh their ID token, before the claim appears in the app.');
} catch (error) {
  console.error('Could not grant admin claim. Verify Application Default Credentials and Firebase Auth permissions.');
  console.error(error.message);
  process.exit(1);
}
