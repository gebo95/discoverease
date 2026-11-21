// Run with both emulators (see docs/17):
//   firebase emulators:exec --only firestore,storage "npm --prefix rules-tests test"
// Storage rules read the business's Firestore document to find its owner, so
// the Firestore emulator must be running too.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc } = require('firebase/firestore');
const { deleteObject, getBytes, ref, uploadBytes } = require('firebase/storage');

let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    // The Storage emulator looks up the business owner in the Firestore
    // emulator under the project the emulators were started with, so the test
    // must use that same project (emulators:exec sets GCLOUD_PROJECT).
    projectId: process.env.GCLOUD_PROJECT || 'demo-discoverease-storage-rules',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
    storage: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'storage.rules'), 'utf8'),
    },
  });
});

test.after(async () => {
  await env.cleanup();
});

test.beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'businesses/biz-1'), { ownerUid: 'biz-1', status: 'published' }),
  );
});

const asUser = (uid, claims = {}) => env.authenticatedContext(uid, claims).storage();
const signedOut = () => env.unauthenticatedContext().storage();
const bytes = (n) => new Uint8Array(n);
const png = { contentType: 'image/png' };
const seedFile = (file, metadata = png) =>
  env.withSecurityRulesDisabled((ctx) => uploadBytes(ref(ctx.storage(), file), bytes(10), metadata));

test('an owner can upload an image to their pending folder', async () => {
  await assertSucceeds(uploadBytes(ref(asUser('biz-1'), 'pending/biz-1/exp-1/a1.png'), bytes(100), png));
  await assertSucceeds(
    uploadBytes(ref(asUser('biz-1'), 'pending/biz-1/exp-1/a2.jpg'), bytes(100), { contentType: 'image/jpeg' }),
  );
});

test('uploads must be small images with safe names', async () => {
  const owner = asUser('biz-1');
  await assertFails(uploadBytes(ref(owner, 'pending/biz-1/exp-1/big.png'), bytes(5 * 1024 * 1024 + 1), png));
  await assertFails(
    uploadBytes(ref(owner, 'pending/biz-1/exp-1/a.png'), bytes(100), { contentType: 'text/html' }),
  );
  await assertFails(
    uploadBytes(ref(owner, 'pending/biz-1/exp-1/a.gif'), bytes(100), { contentType: 'image/gif' }),
  );
  await assertFails(uploadBytes(ref(owner, 'pending/biz-1/exp-1/a.png.exe'), bytes(100), png));
  await assertFails(uploadBytes(ref(owner, 'pending/biz-1/exp-1/a.png'), bytes(0), png));
});

test('nobody else can upload to a business folder, and the public folder is read-only', async () => {
  await assertFails(uploadBytes(ref(asUser('intruder'), 'pending/biz-1/exp-1/a.png'), bytes(100), png));
  await assertFails(uploadBytes(ref(signedOut(), 'pending/biz-1/exp-1/a.png'), bytes(100), png));
  await assertFails(uploadBytes(ref(asUser('biz-1'), 'public/biz-1/exp-1/a.png'), bytes(100), png));
  await assertFails(
    uploadBytes(ref(asUser('admin-1', { admin: true }), 'public/biz-1/exp-1/a.png'), bytes(100), png),
  );
  await assertFails(uploadBytes(ref(asUser('biz-1'), 'elsewhere/a.png'), bytes(100), png));
});

test('a file cannot be overwritten once uploaded', async () => {
  await seedFile('pending/biz-1/exp-1/a1.png');
  await assertFails(uploadBytes(ref(asUser('biz-1'), 'pending/biz-1/exp-1/a1.png'), bytes(50), png));
});

test('only the owner and reviewers can read a pending photo', async () => {
  await seedFile('pending/biz-1/exp-1/a1.png');
  const file = 'pending/biz-1/exp-1/a1.png';
  await assertSucceeds(getBytes(ref(asUser('biz-1'), file)));
  await assertSucceeds(getBytes(ref(asUser('admin-1', { admin: true }), file)));
  await assertFails(getBytes(ref(asUser('intruder'), file)));
  await assertFails(getBytes(ref(signedOut(), file)));
});

test('approved photos are public to everyone', async () => {
  await seedFile('public/biz-1/exp-1/a1.png');
  await assertSucceeds(getBytes(ref(signedOut(), 'public/biz-1/exp-1/a1.png')));
});

test('an owner can delete their own pending photo but not an approved one', async () => {
  await seedFile('pending/biz-1/exp-1/a1.png');
  await seedFile('public/biz-1/exp-1/b1.png');
  await assertSucceeds(deleteObject(ref(asUser('biz-1'), 'pending/biz-1/exp-1/a1.png')));
  await assertFails(deleteObject(ref(asUser('biz-1'), 'public/biz-1/exp-1/b1.png')));
  await seedFile('pending/biz-1/exp-1/c1.png');
  await assertFails(deleteObject(ref(asUser('intruder'), 'pending/biz-1/exp-1/c1.png')));
});

test('rules fail closed when the business document does not exist', async () => {
  await env.withSecurityRulesDisabled((ctx) =>
    uploadBytes(ref(ctx.storage(), 'pending/ghost/exp-1/a1.png'), bytes(10), png),
  );
  await assertFails(uploadBytes(ref(asUser('ghost'), 'pending/ghost/exp-2/a1.png'), bytes(100), png));
  await assertFails(getBytes(ref(asUser('ghost'), 'pending/ghost/exp-1/a1.png')));
});
