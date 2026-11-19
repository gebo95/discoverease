// Run from the project root with the Firebase Emulator (see docs/17):
//   firebase emulators:exec --only firestore "npm --prefix rules-tests test"
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  collectionGroup,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} = require('firebase/firestore');

let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-discoverease-rules',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});

test.after(async () => {
  await env.cleanup();
});

test.beforeEach(async () => {
  await env.clearFirestore();
});

const now = () => new Date();
const signedOut = () => env.unauthenticatedContext().firestore();
const asUser = (uid) => env.authenticatedContext(uid).firestore();
const asAdmin = () => env.authenticatedContext('admin-1', { admin: true }).firestore();
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const businessDoc = (uid, overrides = {}) => ({
  schemaVersion: 1,
  id: uid,
  ownerUid: uid,
  name: 'Island Tours',
  email: 'owner@example.com',
  phone: '555-0100',
  website: 'https://example.com',
  instagram: '@islandtours',
  status: 'pending_review',
  verified: false,
  subscriptionTier: 'free',
  createdAt: now(),
  ...overrides,
});

const experienceDoc = (id, overrides = {}) => ({
  schemaVersion: 1,
  id,
  title: 'Sunset Cruise',
  description: 'Evening boat tour.',
  category: 'Tours',
  subcategory: 'Boat',
  destinationId: 'nassau',
  destination: 'Bahamas',
  location: 'Paradise Island',
  price: '$$',
  imageUrl: '',
  status: 'pending_review',
  createdAt: now(),
  updatedAt: now(),
  ...overrides,
});

// ---------------------------------------------------------------- businesses

test('business contact details are not readable by the public', async () => {
  await seed((db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1', { status: 'published' })));
  await assertFails(getDoc(doc(signedOut(), 'businesses/biz-1')));
  await assertFails(getDoc(doc(asUser('someone-else'), 'businesses/biz-1')));
  await assertFails(
    getDocs(query(collectionGroup(asUser('someone-else'), 'businesses'), where('status', '==', 'published'))),
  );
});

test('a business owner and an admin can read the business profile', async () => {
  await seed((db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1')));
  await assertSucceeds(getDoc(doc(asUser('biz-1'), 'businesses/biz-1')));
  await assertSucceeds(getDoc(doc(asAdmin(), 'businesses/biz-1')));
});

test('a new business must be created pending, unverified, on the free tier, under its own uid', async () => {
  await assertSucceeds(setDoc(doc(asUser('biz-1'), 'businesses/biz-1'), businessDoc('biz-1')));
  await assertFails(
    setDoc(doc(asUser('biz-2'), 'businesses/biz-2'), businessDoc('biz-2', { status: 'published' })),
  );
  await assertFails(
    setDoc(doc(asUser('biz-3'), 'businesses/biz-3'), businessDoc('biz-3', { verified: true })),
  );
  await assertFails(
    setDoc(doc(asUser('biz-4'), 'businesses/biz-4'), businessDoc('biz-4', { subscriptionTier: 'pro' })),
  );
  await assertFails(setDoc(doc(asUser('intruder'), 'businesses/biz-5'), businessDoc('biz-5')));
});

test('a business cannot approve or verify itself', async () => {
  await seed((db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1')));
  const owner = asUser('biz-1');
  await assertFails(updateDoc(doc(owner, 'businesses/biz-1'), { status: 'published' }));
  await assertFails(updateDoc(doc(owner, 'businesses/biz-1'), { verified: true }));
  await assertSucceeds(updateDoc(doc(owner, 'businesses/biz-1'), { phone: '555-0199' }));
});

// --------------------------------------------------------------- experiences

test('an owner can submit a pending experience but not a published one', async () => {
  await seed((db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1')));
  const owner = asUser('biz-1');
  await assertSucceeds(setDoc(doc(owner, 'businesses/biz-1/experiences/exp-1'), experienceDoc('exp-1')));
  await assertFails(
    setDoc(doc(owner, 'businesses/biz-1/experiences/exp-2'), experienceDoc('exp-2', { status: 'published' })),
  );
});

test('an owner can edit a pending experience', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/exp-1'), experienceDoc('exp-1'));
  });
  await assertSucceeds(
    updateDoc(doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1'), {
      title: 'Sunset Cruise (updated)',
      updatedAt: now(),
    }),
  );
});

test('a published experience cannot be edited by its owner', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/exp-1'), experienceDoc('exp-1', { status: 'published' }));
  });
  await assertFails(
    updateDoc(doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1'), {
      title: 'Sneaky edit',
      updatedAt: now(),
    }),
  );
});

test('a rejected experience can be resubmitted, and only with the review fields cleared', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(
      doc(db, 'businesses/biz-1/experiences/exp-1'),
      experienceDoc('exp-1', {
        status: 'rejected',
        reviewNote: 'Please add a clearer description.',
        reviewedAt: now(),
        reviewedBy: 'admin-1',
      }),
    );
  });
  const ref = doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1');
  // Keeping the old feedback attached is not a valid resubmission.
  await assertFails(updateDoc(ref, { status: 'pending_review', updatedAt: now() }));
  await assertSucceeds(
    updateDoc(ref, {
      title: 'Sunset Cruise',
      status: 'pending_review',
      reviewNote: '',
      reviewedAt: null,
      reviewedBy: null,
      updatedAt: now(),
    }),
  );
});

test('a business cannot approve its own experience', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/exp-1'), experienceDoc('exp-1'));
  });
  await assertFails(
    updateDoc(doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1'), {
      status: 'published',
      updatedAt: now(),
    }),
  );
});

test('pending experiences are private to the owner and admins; published ones are public', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/pending'), experienceDoc('pending'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/live'), experienceDoc('live', { status: 'published' }));
  });
  await assertFails(getDoc(doc(asUser('stranger'), 'businesses/biz-1/experiences/pending')));
  await assertFails(getDoc(doc(signedOut(), 'businesses/biz-1/experiences/pending')));
  await assertSucceeds(getDoc(doc(asUser('biz-1'), 'businesses/biz-1/experiences/pending')));
  await assertSucceeds(getDoc(doc(asAdmin(), 'businesses/biz-1/experiences/pending')));
  await assertSucceeds(getDoc(doc(signedOut(), 'businesses/biz-1/experiences/live')));
});

test('only admins can run the moderation query across all businesses', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/pending'), experienceDoc('pending'));
  });
  const pendingQuery = (db) =>
    getDocs(query(collectionGroup(db, 'experiences'), where('status', '==', 'pending_review')));
  await assertSucceeds(pendingQuery(asAdmin()));
  await assertFails(pendingQuery(asUser('biz-1')));
  await assertFails(pendingQuery(signedOut()));
});

test('experience details (address, links, hours) can be submitted and edited while pending', async () => {
  await seed((db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1')));
  const owner = asUser('biz-1');
  const details = {
    address: '1 Bay Street, Nassau',
    website: 'https://example.com',
    bookingUrl: 'https://example.com/book',
    phone: '+1 242 555 0100',
    hours: 'Mon-Sat 9am-5pm',
    schedule: 'Fri and Sat 8pm',
  };
  await assertSucceeds(
    setDoc(doc(owner, 'businesses/biz-1/experiences/exp-1'), experienceDoc('exp-1', details)),
  );
  await assertSucceeds(
    updateDoc(doc(owner, 'businesses/biz-1/experiences/exp-1'), {
      hours: 'Daily 10am-6pm',
      website: '',
      updatedAt: now(),
    }),
  );
});

test('experience links must be plain http(s) addresses and details must stay a sane size', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/exp-1'), experienceDoc('exp-1'));
  });
  const owner = asUser('biz-1');
  const ref = doc(owner, 'businesses/biz-1/experiences/exp-1');
  await assertFails(updateDoc(ref, { website: 'javascript:alert(1)', updatedAt: now() }));
  await assertFails(updateDoc(ref, { bookingUrl: 'ftp://example.com', updatedAt: now() }));
  await assertFails(updateDoc(ref, { website: 'https://exa mple.com', updatedAt: now() }));
  await assertFails(updateDoc(ref, { hours: 'x'.repeat(301), updatedAt: now() }));
  await assertFails(updateDoc(ref, { phone: 12345, updatedAt: now() }));
  await assertFails(
    setDoc(
      doc(owner, 'businesses/biz-1/experiences/exp-2'),
      experienceDoc('exp-2', { website: 'javascript:alert(1)' }),
    ),
  );
  // Unknown fields are still rejected.
  await assertFails(updateDoc(ref, { featured: true, updatedAt: now() }));
});

test('a published experience cannot have its details changed by the owner', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(
      doc(db, 'businesses/biz-1/experiences/exp-1'),
      experienceDoc('exp-1', { status: 'published', website: 'https://example.com' }),
    );
  });
  await assertFails(
    updateDoc(doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1'), {
      website: 'https://evil.example.com',
      updatedAt: now(),
    }),
  );
});

// ------------------------------------------------------- live experience edits

const liveExperience = (overrides = {}) =>
  experienceDoc('exp-1', { status: 'published', ...overrides });

const revisionFor = (overrides = {}) => ({
  title: 'Sunset Cruise (new name)',
  description: 'Evening boat tour.',
  category: 'Tours',
  subcategory: 'Boat',
  destinationId: 'nassau',
  destination: 'Bahamas',
  location: 'Paradise Island',
  price: '$$',
  imageUrl: '',
  website: 'https://example.com',
  ...overrides,
});

const submitRevisionFields = (revision) => ({
  pendingRevision: revision,
  revisionStatus: 'pending_review',
  revisionNote: '',
  revisionSubmittedAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

async function seedLiveExperience(extra = {}) {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/exp-1'), liveExperience(extra));
  });
}

const liveRef = (db) => doc(db, 'businesses/biz-1/experiences/exp-1');

test('an owner can propose changes to a live experience without touching the live fields', async () => {
  await seedLiveExperience();
  await assertSucceeds(updateDoc(liveRef(asUser('biz-1')), submitRevisionFields(revisionFor())));
  // Direct edits of the live fields stay blocked, even alongside a revision.
  await assertFails(
    updateDoc(liveRef(asUser('biz-1')), {
      ...submitRevisionFields(revisionFor()),
      title: 'Edited without review',
    }),
  );
});

test('a proposed change must be well-formed and cannot change the photo yet', async () => {
  await seedLiveExperience();
  const owner = asUser('biz-1');
  await assertFails(updateDoc(liveRef(owner), submitRevisionFields(revisionFor({ website: 'javascript:alert(1)' }))));
  await assertFails(updateDoc(liveRef(owner), submitRevisionFields(revisionFor({ imageUrl: 'https://example.com/x.jpg' }))));
  await assertFails(updateDoc(liveRef(owner), submitRevisionFields(revisionFor({ title: '' }))));
  await assertFails(updateDoc(liveRef(owner), submitRevisionFields(revisionFor({ featured: true }))));
  await assertFails(updateDoc(liveRef(owner), submitRevisionFields(revisionFor({ hours: 'x'.repeat(301) }))));
});

test('an owner cannot approve, reject, or annotate their own proposed change', async () => {
  await seedLiveExperience();
  const owner = asUser('biz-1');
  await assertFails(updateDoc(liveRef(owner), { ...submitRevisionFields(revisionFor()), revisionStatus: 'rejected' }));
  await assertFails(updateDoc(liveRef(owner), { ...submitRevisionFields(revisionFor()), revisionNote: 'Looks good' }));
  await assertFails(updateDoc(liveRef(owner), { ...submitRevisionFields(revisionFor()), status: 'pending_review' }));
  await assertFails(updateDoc(liveRef(asUser('stranger')), submitRevisionFields(revisionFor())));
});

test('an owner can withdraw or resubmit a proposed change', async () => {
  await seedLiveExperience({
    pendingRevision: revisionFor(),
    revisionStatus: 'rejected',
    revisionNote: 'Please fix the description.',
    revisionSubmittedAt: now(),
  });
  const owner = asUser('biz-1');
  await assertSucceeds(updateDoc(liveRef(owner), submitRevisionFields(revisionFor({ title: 'Better name' }))));
  await assertSucceeds(
    updateDoc(liveRef(owner), {
      pendingRevision: deleteField(),
      revisionStatus: deleteField(),
      revisionNote: deleteField(),
      revisionSubmittedAt: deleteField(),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('admins can apply or reject a proposed change and find them with one query', async () => {
  await seedLiveExperience({
    pendingRevision: revisionFor(),
    revisionStatus: 'pending_review',
    revisionNote: '',
    revisionSubmittedAt: now(),
  });
  const pendingRevisions = (db) =>
    getDocs(query(collectionGroup(db, 'experiences'), where('revisionStatus', '==', 'pending_review')));
  await assertSucceeds(pendingRevisions(asAdmin()));
  await assertFails(pendingRevisions(asUser('biz-1')));
  await assertSucceeds(
    updateDoc(liveRef(asAdmin()), {
      revisionStatus: 'rejected',
      revisionNote: 'Please add a clearer description.',
    }),
  );
  await assertSucceeds(
    updateDoc(liveRef(asAdmin()), {
      title: 'Sunset Cruise (new name)',
      pendingRevision: deleteField(),
      revisionStatus: deleteField(),
      revisionNote: deleteField(),
      revisionSubmittedAt: deleteField(),
    }),
  );
});

// ------------------------------------------------------------------- catalog

test('the public catalog shows only published entries and only admins can write it', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'catalog/live'), { status: 'published', title: 'Live' });
    await setDoc(doc(db, 'catalog/draft'), { status: 'pending_review', title: 'Draft' });
  });
  await assertSucceeds(getDoc(doc(signedOut(), 'catalog/live')));
  await assertFails(getDoc(doc(signedOut(), 'catalog/draft')));
  await assertFails(setDoc(doc(asUser('biz-1'), 'catalog/new'), { status: 'published' }));
  await assertSucceeds(setDoc(doc(asAdmin(), 'catalog/new'), { status: 'published' }));
  await assertFails(deleteDoc(doc(asUser('biz-1'), 'catalog/live')));
});

// ----------------------------------------------------------------- analytics

test('analytics are readable by the owning business and admins, and never writable by clients', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/analytics/exp-1'), { uniqueSharers: 2 });
    await setDoc(doc(db, 'businesses/biz-1/analytics/exp-1/daily/20261114'), { views: 3 });
  });
  await assertSucceeds(getDoc(doc(asUser('biz-1'), 'businesses/biz-1/analytics/exp-1')));
  await assertSucceeds(getDoc(doc(asUser('biz-1'), 'businesses/biz-1/analytics/exp-1/daily/20261114')));
  await assertSucceeds(getDoc(doc(asAdmin(), 'businesses/biz-1/analytics/exp-1')));
  await assertFails(getDoc(doc(asUser('stranger'), 'businesses/biz-1/analytics/exp-1')));
  await assertFails(getDoc(doc(signedOut(), 'businesses/biz-1/analytics/exp-1')));
  // A business cannot inflate its own numbers.
  await assertFails(updateDoc(doc(asUser('biz-1'), 'businesses/biz-1/analytics/exp-1'), { uniqueSharers: 999 }));
  await assertFails(updateDoc(doc(asUser('biz-1'), 'businesses/biz-1/analytics/exp-1/daily/20261114'), { views: 999 }));
  await assertFails(updateDoc(doc(asAdmin(), 'businesses/biz-1/analytics/exp-1'), { uniqueSharers: 999 }));
});

test('engagement receipts are not accessible from client apps', async () => {
  await seed((db) => setDoc(doc(db, 'engagementReceipts/abc'), { metric: 'views' }));
  await assertFails(getDoc(doc(asUser('anyone'), 'engagementReceipts/abc')));
  await assertFails(setDoc(doc(asUser('anyone'), 'engagementReceipts/new'), { metric: 'views' }));
  await assertFails(getDoc(doc(asAdmin(), 'engagementReceipts/abc')));
});

// ---------------------------------------------------------------- user data

test('a signed-in user can only touch their own saved places', async () => {
  const saved = {
    schemaVersion: 1,
    id: 'saved-sunset',
    listingId: 'sunset',
    destination: 'Bahamas',
    listName: null,
  };
  await assertSucceeds(setDoc(doc(asUser('u1'), 'users/u1/saved/sunset'), saved));
  await assertSucceeds(getDoc(doc(asUser('u1'), 'users/u1/saved/sunset')));
  await assertFails(getDoc(doc(asUser('u2'), 'users/u1/saved/sunset')));
  await assertFails(setDoc(doc(asUser('u2'), 'users/u1/saved/other'), { ...saved, listingId: 'other' }));
  await assertFails(getDoc(doc(signedOut(), 'users/u1/saved/sunset')));
});

test('likes can only be created for published catalog listings', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'catalog/live'), { status: 'published' });
    await setDoc(doc(db, 'catalog/draft'), { status: 'pending_review' });
  });
  const like = (listingId) => ({ schemaVersion: 1, listingId, createdAt: now() });
  await assertSucceeds(setDoc(doc(asUser('u1'), 'users/u1/likes/live'), like('live')));
  await assertFails(setDoc(doc(asUser('u1'), 'users/u1/likes/draft'), like('draft')));
  await assertFails(setDoc(doc(asUser('u1'), 'users/u1/likes/missing'), like('missing')));
  await assertFails(setDoc(doc(asUser('u2'), 'users/u1/likes/live'), like('live')));
});

test('a user cannot read another user trips', async () => {
  await seed((db) => setDoc(doc(db, 'users/u1/trips/t1'), { id: 't1' }));
  await assertFails(getDoc(doc(asUser('u2'), 'users/u1/trips/t1')));
  await assertSucceeds(getDoc(doc(asUser('u1'), 'users/u1/trips/t1')));
});
