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
  collection,
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

// ------------------------------------------------------------- availability

test('anyone can read an unavailable notice but no client can write one', async () => {
  await seed((db) =>
    setDoc(doc(db, 'unavailable/sunset'), { listingId: 'sunset', title: 'Sunset Cruise', reason: 'temporary', message: '' }),
  );
  await assertSucceeds(getDoc(doc(signedOut(), 'unavailable/sunset')));
  await assertSucceeds(getDoc(doc(asUser('u1'), 'unavailable/sunset')));
  await assertFails(setDoc(doc(asUser('biz-1'), 'unavailable/new'), { listingId: 'new', reason: 'temporary' }));
  await assertFails(updateDoc(doc(asUser('biz-1'), 'unavailable/sunset'), { reason: 'removed' }));
  await assertFails(deleteDoc(doc(asUser('biz-1'), 'unavailable/sunset')));
  await assertFails(setDoc(doc(asAdmin(), 'unavailable/new'), { listingId: 'new', reason: 'temporary' }));
});

test('an owner cannot hide, end or relist a live experience directly', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1', { status: 'published' }));
    await setDoc(doc(db, 'businesses/biz-1/experiences/exp-1'), experienceDoc('exp-1', { status: 'published' }));
  });
  const ref = doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1');
  await assertFails(updateDoc(ref, { availability: 'hidden', updatedAt: now() }));
  await assertFails(updateDoc(ref, { endsAt: now(), updatedAt: now() }));
  await assertFails(updateDoc(ref, { availability: 'live', updatedAt: now() }));
});

test('an owner can still edit a pending experience that has an end date', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(
      doc(db, 'businesses/biz-1/experiences/exp-1'),
      experienceDoc('exp-1', { endsAt: new Date(Date.now() + 86400000) }),
    );
  });
  await assertSucceeds(
    updateDoc(doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1'), {
      title: 'Sunset Cruise 2',
      updatedAt: now(),
    }),
  );
});

test('an owner can still propose a revision to a hidden live experience', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1', { status: 'published' }));
    await setDoc(
      doc(db, 'businesses/biz-1/experiences/exp-1'),
      experienceDoc('exp-1', { status: 'published', availability: 'hidden', availabilityMessage: 'Back soon' }),
    );
  });
  const live = experienceDoc('exp-1');
  await assertSucceeds(
    updateDoc(doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1'), {
      pendingRevision: {
        title: 'Sunset Cruise Deluxe',
        description: live.description,
        category: live.category,
        subcategory: live.subcategory,
        destinationId: live.destinationId,
        destination: live.destination,
        location: live.location,
        price: live.price,
        imageUrl: live.imageUrl,
      },
      revisionStatus: 'pending_review',
      revisionNote: '',
      revisionSubmittedAt: serverTimestamp(),
      updatedAt: now(),
    }),
  );
});

test('a hidden catalog listing is not readable by the public', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'catalog/exp-1'), { status: 'hidden', title: 'Sunset Cruise' });
    await setDoc(doc(db, 'catalog/exp-2'), { status: 'published', title: 'Kayak' });
  });
  await assertFails(getDoc(doc(signedOut(), 'catalog/exp-1')));
  await assertSucceeds(getDoc(doc(signedOut(), 'catalog/exp-2')));
});

// ------------------------------------------------------------------- photos

test('an owner can propose photos in a revision but not write them to a live experience', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1', { status: 'published' }));
    await setDoc(
      doc(db, 'businesses/biz-1/experiences/exp-1'),
      experienceDoc('exp-1', { status: 'published', photos: [] }),
    );
  });
  const live = experienceDoc('exp-1');
  const revision = (photos) => ({
    title: live.title,
    description: live.description,
    category: live.category,
    subcategory: live.subcategory,
    destinationId: live.destinationId,
    destination: live.destination,
    location: live.location,
    price: live.price,
    imageUrl: live.imageUrl,
    photos,
  });
  const proposal = (photos) => ({
    pendingRevision: revision(photos),
    revisionStatus: 'pending_review',
    revisionNote: '',
    revisionSubmittedAt: serverTimestamp(),
    updatedAt: now(),
  });
  const ref = doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-1');
  await assertSucceeds(updateDoc(ref, proposal(['pending/biz-1/exp-1/a1.jpg'])));
  const tooMany = Array.from({ length: 6 }, (_, i) => `pending/biz-1/exp-1/p${i}.jpg`);
  await assertFails(updateDoc(ref, proposal(tooMany)));
  await assertFails(updateDoc(ref, { photos: ['pending/biz-1/exp-1/a1.jpg'], updatedAt: now() }));
  await assertFails(updateDoc(ref, { imageUrl: 'https://example.com/x.jpg', updatedAt: now() }));
});

test('an owner can attach photos to a pending submission', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'businesses/biz-1/experiences/exp-1'), experienceDoc('exp-1'));
  });
  const owner = asUser('biz-1');
  await assertSucceeds(
    updateDoc(doc(owner, 'businesses/biz-1/experiences/exp-1'), {
      photos: ['pending/biz-1/exp-1/a1.jpg', 'pending/biz-1/exp-1/a2.png'],
      updatedAt: now(),
    }),
  );
  await assertFails(
    updateDoc(doc(owner, 'businesses/biz-1/experiences/exp-1'), {
      photos: 'not a list',
      updatedAt: now(),
    }),
  );
  await assertSucceeds(
    setDoc(doc(owner, 'businesses/biz-1/experiences/exp-2'), experienceDoc('exp-2', { photos: ['pending/biz-1/exp-2/b.jpg'] })),
  );
});

// --------------------------------------------- price, tags and why-you'll-love-it

test('an owner can add the extra details when proposing a live change', async () => {
  await seedLiveExperience();
  const ref = liveRef(asUser('biz-1'));
  await assertSucceeds(
    updateDoc(ref, submitRevisionFields(revisionFor({
      price: '$$$',
      whyYoullLoveIt: 'Golden hour on the water.',
      perfectFor: ['Couples', 'Friends'],
      features: ['Ocean View', 'Romantic', 'Photo Friendly'],
    }))),
  );
});

test('the extra details are capped in length and number', async () => {
  await seedLiveExperience();
  const ref = liveRef(asUser('biz-1'));
  const six = ['a', 'b', 'c', 'd', 'e', 'f'];
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ perfectFor: six }))));
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ features: six }))));
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ whyYoullLoveIt: 'x'.repeat(601) }))));
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ perfectFor: 'Couples' }))));
});

test('a new submission can include the extra details, within the caps', async () => {
  await seed(async (db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1')));
  const owner = asUser('biz-1');
  await assertSucceeds(
    setDoc(doc(owner, 'businesses/biz-1/experiences/exp-9'), experienceDoc('exp-9', {
      whyYoullLoveIt: 'Great views.',
      perfectFor: ['Couples'],
      features: ['Ocean View'],
    })),
  );
  await assertFails(
    setDoc(doc(owner, 'businesses/biz-1/experiences/exp-8'), experienceDoc('exp-8', {
      features: ['1', '2', '3', '4', '5', '6'],
    })),
  );
});

// ------------------------------------------------------------ business name

const businessRef = (db) => doc(db, 'businesses/biz-1');

test('an owner can correct the business name at any time, approved or not', async () => {
  await seed(async (db) => setDoc(businessRef(db), businessDoc('biz-1')));
  await assertSucceeds(updateDoc(businessRef(asUser('biz-1')), { name: 'Island Tours Bahamas' }));
  await seed(async (db) => setDoc(businessRef(db), businessDoc('biz-1', { status: 'published', verified: true })));
  await assertSucceeds(updateDoc(businessRef(asUser('biz-1')), { name: 'Island Tours Nassau' }));
});

test('a business name must be 1 to 100 characters and only the owner can change it', async () => {
  await seed(async (db) => setDoc(businessRef(db), businessDoc('biz-1', { status: 'published', verified: true })));
  const owner = asUser('biz-1');
  await assertFails(updateDoc(businessRef(owner), { name: '' }));
  await assertFails(updateDoc(businessRef(owner), { name: 'x'.repeat(101) }));
  await assertFails(updateDoc(businessRef(owner), { name: 7 }));
  await assertFails(updateDoc(businessRef(asUser('stranger')), { name: 'Hijacked' }));
  // Renaming does not unlock approval fields.
  await assertFails(updateDoc(businessRef(owner), { name: 'Fine', verified: false }));
  await assertFails(updateDoc(businessRef(owner), { name: 'Fine', status: 'pending_review' }));
});

// ------------------------------------------------------------------- map pin

test('an owner can propose a map pin, but only a real one', async () => {
  await seedLiveExperience();
  const ref = liveRef(asUser('biz-1'));
  await assertSucceeds(updateDoc(ref, submitRevisionFields(revisionFor({ latitude: 25.078, longitude: -77.343 }))));
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ latitude: 95, longitude: 0 }))));
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ latitude: 0, longitude: -181 }))));
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ latitude: '25.1', longitude: 0 }))));
});

test('a new submission can include a pin and a pending one can be moved', async () => {
  await seed(async (db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1')));
  const owner = asUser('biz-1');
  await assertSucceeds(
    setDoc(doc(owner, 'businesses/biz-1/experiences/exp-5'), experienceDoc('exp-5', { latitude: 25.1, longitude: -77.3 })),
  );
  await assertSucceeds(
    updateDoc(doc(owner, 'businesses/biz-1/experiences/exp-5'), { latitude: 25.2, longitude: -77.4, updatedAt: now() }),
  );
  await assertSucceeds(
    updateDoc(doc(owner, 'businesses/biz-1/experiences/exp-5'), { latitude: deleteField(), longitude: deleteField(), updatedAt: now() }),
  );
  await assertFails(
    updateDoc(doc(owner, 'businesses/biz-1/experiences/exp-5'), { latitude: 200, updatedAt: now() }),
  );
});

test('an owner cannot move the pin on a live experience without review', async () => {
  await seedLiveExperience();
  await assertFails(updateDoc(liveRef(asUser('biz-1')), { latitude: 25.2, longitude: -77.4, updatedAt: now() }));
});

// ------------------------------------------------------------ business pulse

test('anyone can read Pulse posts, but nobody can write them from the app', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'pulses/exp-1'), {
      listingId: 'exp-1', businessId: 'biz-1', tag: 'Live Music', message: '', expiresAt: now(),
    }),
  );
  await assertSucceeds(getDoc(doc(signedOut(), 'pulses/exp-1')));
  await assertSucceeds(getDocs(query(collection(signedOut(), 'pulses'), where('expiresAt', '>', new Date(0)))));
  const post = { listingId: 'exp-2', businessId: 'biz-1', tag: 'Live Music', message: '', expiresAt: now() };
  await assertFails(setDoc(doc(asUser('biz-1'), 'pulses/exp-2'), post));
  await assertFails(setDoc(doc(asAdmin(), 'pulses/exp-2'), post));
  await assertFails(updateDoc(doc(asUser('biz-1'), 'pulses/exp-1'), { message: 'edited' }));
  await assertFails(deleteDoc(doc(asUser('biz-1'), 'pulses/exp-1')));
});

// ------------------------------------------------------------- highlight tag

test('an owner can propose a highlight tag, within the length limit', async () => {
  await seedLiveExperience();
  const ref = liveRef(asUser('biz-1'));
  await assertSucceeds(updateDoc(ref, submitRevisionFields(revisionFor({ highlight: 'Local Favorite' }))));
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ highlight: 'x'.repeat(41) }))));
  await assertFails(updateDoc(ref, submitRevisionFields(revisionFor({ highlight: 5 }))));
});

test('a new submission can include a highlight tag', async () => {
  await seed(async (db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1')));
  await assertSucceeds(
    setDoc(doc(asUser('biz-1'), 'businesses/biz-1/experiences/exp-7'), experienceDoc('exp-7', { highlight: 'Hidden Gem' })),
  );
});

// ------------------------------------------------------ plans and Featured

test('an owner can read their own plan but nobody can write it', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1'));
    await setDoc(doc(db, 'subscriptions/biz-1'), { plan: 'plus', status: 'active', packBalance: 5 });
  });
  await assertSucceeds(getDoc(doc(asUser('biz-1'), 'subscriptions/biz-1')));
  await assertSucceeds(getDoc(doc(asAdmin(), 'subscriptions/biz-1')));
  await assertFails(getDoc(doc(asUser('biz-2'), 'subscriptions/biz-1')));
  await assertFails(getDoc(doc(signedOut(), 'subscriptions/biz-1')));
  await assertFails(getDocs(collection(asUser('biz-1'), 'subscriptions')));
  await assertFails(setDoc(doc(asUser('biz-1'), 'subscriptions/biz-1'), { plan: 'pro', status: 'active' }));
  await assertFails(updateDoc(doc(asUser('biz-1'), 'subscriptions/biz-1'), { packBalance: 999 }));
  await assertFails(setDoc(doc(asAdmin(), 'subscriptions/biz-1'), { plan: 'pro', status: 'active' }));
});

test('Featured placement is public to read and never written by an app', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'featured/exp-1'), { listingId: 'exp-1', businessId: 'biz-1', endsAt: now() }),
  );
  await assertSucceeds(getDoc(doc(signedOut(), 'featured/exp-1')));
  await assertSucceeds(getDocs(collection(signedOut(), 'featured')));
  await assertFails(setDoc(doc(asUser('biz-1'), 'featured/exp-2'), { listingId: 'exp-2', businessId: 'biz-1' }));
  await assertFails(updateDoc(doc(asUser('biz-1'), 'featured/exp-1'), { endsAt: now() }));
  await assertFails(deleteDoc(doc(asAdmin(), 'featured/exp-1')));
});

test('Stripe ids and handled events cannot be read or written by any app', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'billing_private/biz-1'), { stripeCustomerId: 'cus_1' });
    await setDoc(doc(db, 'stripe_events/evt_1'), { type: 'x' });
  });
  for (const db of [asUser('biz-1'), asAdmin(), signedOut()]) {
    await assertFails(getDoc(doc(db, 'billing_private/biz-1')));
    await assertFails(setDoc(doc(db, 'billing_private/biz-1'), { stripeCustomerId: 'cus_2' }));
    await assertFails(getDoc(doc(db, 'stripe_events/evt_1')));
    await assertFails(setDoc(doc(db, 'stripe_events/evt_2'), { type: 'y' }));
  }
});

test('an owner cannot give themselves a paid tier on their business record', async () => {
  await seed(async (db) => setDoc(doc(db, 'businesses/biz-1'), businessDoc('biz-1')));
  await assertFails(updateDoc(doc(asUser('biz-1'), 'businesses/biz-1'), { subscriptionTier: 'pro' }));
});

// ------------------------------------------------------ claim your business

const shell = (overrides = {}) =>
  businessDoc('shell-1', {
    id: 'shell-1',
    ownerUid: '',
    status: 'approved',
    claimStatus: 'unclaimed',
    ...overrides,
  });

test('claimable listings are readable when signed in and never writable', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'claimable/shell-1'), { name: 'Cafe', emailHint: 'ow***@cafe.com' }),
  );
  await assertSucceeds(getDoc(doc(asUser('u1'), 'claimable/shell-1')));
  await assertSucceeds(getDocs(collection(asUser('u1'), 'claimable')));
  await assertFails(getDoc(doc(signedOut(), 'claimable/shell-1')));
  await assertFails(setDoc(doc(asUser('u1'), 'claimable/shell-2'), { name: 'Fake' }));
  await assertFails(setDoc(doc(asAdmin(), 'claimable/shell-2'), { name: 'Fake' }));
  await assertFails(deleteDoc(doc(asUser('u1'), 'claimable/shell-1')));
});

test('claim codes and send limits are closed to every app', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'claim_codes/shell-1'), { uid: 'u1', codeHash: 'x' });
    await setDoc(doc(db, 'claim_limits/u1'), { sends: [] });
  });
  for (const db of [asUser('u1'), asAdmin(), signedOut()]) {
    await assertFails(getDoc(doc(db, 'claim_codes/shell-1')));
    await assertFails(setDoc(doc(db, 'claim_codes/shell-1'), { uid: 'u1', codeHash: 'y', attempts: 0 }));
    await assertFails(getDoc(doc(db, 'claim_limits/u1')));
    await assertFails(setDoc(doc(db, 'claim_limits/u1'), { sends: [] }));
  }
});

test('only admins can read claim requests, and nobody can write them', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'claim_requests/r1'), { businessId: 'shell-1', uid: 'u1', status: 'pending' }),
  );
  await assertSucceeds(getDoc(doc(asAdmin(), 'claim_requests/r1')));
  await assertSucceeds(getDocs(collection(asAdmin(), 'claim_requests')));
  await assertFails(getDoc(doc(asUser('u1'), 'claim_requests/r1')));
  await assertFails(setDoc(doc(asUser('u1'), 'claim_requests/r2'), { businessId: 'shell-1', uid: 'u1' }));
  await assertFails(updateDoc(doc(asAdmin(), 'claim_requests/r1'), { status: 'approved' }));
});

test('an unclaimed business is private and nobody can act as its owner', async () => {
  await seed(async (db) => setDoc(doc(db, 'businesses/shell-1'), shell()));
  await assertFails(getDoc(doc(asUser('u1'), 'businesses/shell-1')));
  await assertFails(updateDoc(doc(asUser('u1'), 'businesses/shell-1'), { name: 'Mine now' }));
  await assertFails(
    setDoc(doc(asUser('u1'), 'businesses/shell-1/experiences/e1'), experienceDoc('e1')),
  );
  await assertFails(updateDoc(doc(asUser('u1'), 'businesses/shell-1'), { ownerUid: 'u1' }));
});

test('after a claim, the owner works under the business id, not their own uid', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'businesses/shell-1'), shell({ ownerUid: 'u1', claimStatus: 'claimed', claimedAt: now() })),
  );
  const owner = asUser('u1');
  await assertSucceeds(getDoc(doc(owner, 'businesses/shell-1')));
  await assertSucceeds(
    getDocs(query(collection(owner, 'businesses'), where('ownerUid', '==', 'u1'))),
  );
  await assertSucceeds(updateDoc(doc(owner, 'businesses/shell-1'), { name: 'New name' }));
  await assertSucceeds(
    setDoc(doc(owner, 'businesses/shell-1/experiences/e1'), experienceDoc('e1')),
  );
  await assertSucceeds(getDoc(doc(owner, 'subscriptions/shell-1')));
  // Another person still cannot.
  await assertFails(getDoc(doc(asUser('u2'), 'businesses/shell-1')));
  await assertFails(updateDoc(doc(asUser('u2'), 'businesses/shell-1'), { name: 'Hijack' }));
});

test('an owner cannot change claim fields or hand the business to someone else', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'businesses/shell-1'), shell({ ownerUid: 'u1', claimStatus: 'claimed', claimedAt: now() })),
  );
  const ref = doc(asUser('u1'), 'businesses/shell-1');
  await assertFails(updateDoc(ref, { claimStatus: 'unclaimed' }));
  await assertFails(updateDoc(ref, { claimedAt: now() }));
  await assertFails(updateDoc(ref, { ownerUid: 'u2' }));
});

test('nobody can list other businesses by guessing an owner id', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'businesses/shell-1'), shell({ ownerUid: 'u1', claimStatus: 'claimed' })),
  );
  await assertFails(
    getDocs(query(collection(asUser('u2'), 'businesses'), where('ownerUid', '==', 'u1'))),
  );
});

test('the ownership log is readable by admins only and never written by an app', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'ownership_log/l1'), { businessId: 'shell-1', action: 'revoke' }),
  );
  await assertSucceeds(getDoc(doc(asAdmin(), 'ownership_log/l1')));
  await assertSucceeds(getDocs(collection(asAdmin(), 'ownership_log')));
  await assertFails(getDoc(doc(asUser('u1'), 'ownership_log/l1')));
  await assertFails(setDoc(doc(asAdmin(), 'ownership_log/l2'), { businessId: 'shell-1' }));
});

test('a business taken back loses its owner at once', async () => {
  await seed(async (db) =>
    setDoc(doc(db, 'businesses/shell-1'), shell({ ownerUid: 'u1', claimStatus: 'claimed' })),
  );
  await assertSucceeds(updateDoc(doc(asUser('u1'), 'businesses/shell-1'), { name: 'Mine' }));
  await seed(async (db) =>
    setDoc(doc(db, 'businesses/shell-1'), shell({ ownerUid: '', claimStatus: 'unclaimed', revokedAt: now() })),
  );
  await assertFails(updateDoc(doc(asUser('u1'), 'businesses/shell-1'), { name: 'Still mine' }));
  await assertFails(getDoc(doc(asUser('u1'), 'businesses/shell-1')));
  await assertFails(setDoc(doc(asUser('u1'), 'businesses/shell-1/experiences/e9'), experienceDoc('e9')));
});
