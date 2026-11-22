const { initializeApp } = require('firebase-admin/app');
const { FieldValue, Timestamp, getFirestore } = require('firebase-admin/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret, defineString } = require('firebase-functions/params');
const { onRequest } = require('firebase-functions/v2/https');
const { getStorage } = require('firebase-admin/storage');
const logger = require('firebase-functions/logger');
const { planTransition } = require('./availability_logic');
const { planPhotoPublish, planSetCover } = require('./photos_logic');
const { planPulse } = require('./pulse_logic');
const {
  PRODUCTS,
  allowance,
  effectivePlan,
  featuredEnd,
  isFreeEdit,
  planPulseUse,
  subscriptionFields,
} = require('./plans_logic');
const {
  SHARE_DAILY_CAP,
  digest,
  isValidListingId,
  planShare,
  publishedBusinessId,
  transitionDelta,
  utcDay,
} = require('./metrics_logic');

initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });
const db = getFirestore();
const counterNames = ['views', 'likes', 'shares', 'saves'];

function requireUid(request) {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to record this activity.');
  }
  return request.auth.uid;
}

function requireListingId(data) {
  const id = data?.listingId;
  if (!isValidListingId(id)) {
    throw new HttpsError('invalid-argument', 'A valid listingId is required.');
  }
  return id;
}

async function getPublishedBusiness(listingId) {
  const listing = await db.collection('catalog').doc(listingId).get();
  if (!listing.exists) return null;
  const listingData = listing.data();
  const businessId = listingData?.businessId;
  if (typeof businessId !== 'string' || businessId.length === 0) return null;
  const business = await db.collection('businesses').doc(businessId).get();
  return publishedBusinessId(
    listingData,
    business.exists ? business.data() : null,
  );
}

async function incrementDaily({
  businessId,
  listingId,
  metric,
  bucket,
  receiptKey,
  eventTime,
}) {
  if (!counterNames.includes(metric)) return false;
  const day = utcDay(eventTime);
  const receiptRef = db.collection('engagementReceipts').doc(digest(receiptKey));
  const dailyRef = db
    .collection('businesses').doc(businessId)
    .collection('analytics').doc(listingId)
    .collection('daily').doc(day);

  return db.runTransaction(async (transaction) => {
    const receipt = await transaction.get(receiptRef);
    if (receipt.exists) return false;
    const daily = await transaction.get(dailyRef);
    const previous = daily.exists ? daily.data() : {};
    transaction.create(receiptRef, {
      metric,
      bucket,
      createdAt: FieldValue.serverTimestamp(),
      expireAt: Timestamp.fromDate(new Date(eventTime.getTime() + 90 * 86400000)),
    });
    transaction.set(dailyRef, {
      date: Timestamp.fromDate(new Date(`${day.slice(0, 4)}-${day.slice(4, 6)}-${day.slice(6, 8)}T00:00:00.000Z`)),
      views: previous.views || 0,
      likes: previous.likes || 0,
      shares: previous.shares || 0,
      saves: previous.saves || 0,
      [metric]: (previous[metric] || 0) + 1,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return true;
  });
}

function dayStart(day) {
  return Timestamp.fromDate(
    new Date(`${day.slice(0, 4)}-${day.slice(4, 6)}-${day.slice(6, 8)}T00:00:00.000Z`),
  );
}

// Shares are counted twice over: every share action (capped per account,
// listing, and UTC day) feeds the daily `shares` total, and the first counted
// share by each account feeds the listing's lifetime `uniqueSharers` count.
// Businesses only ever see the counts, never who shared.
async function recordShare({ businessId, listingId, uid, eventTime }) {
  const day = utcDay(eventTime);
  const countRef = db.collection('engagementReceipts')
    .doc(digest(`${uid}:shares-count:${listingId}:${day}`));
  const sharerRef = db.collection('engagementReceipts')
    .doc(digest(`${uid}:sharer:${listingId}`));
  const analyticsRef = db
    .collection('businesses').doc(businessId)
    .collection('analytics').doc(listingId);
  const dailyRef = analyticsRef.collection('daily').doc(day);

  return db.runTransaction(async (transaction) => {
    const [countSnap, sharerSnap, dailySnap] = await Promise.all([
      transaction.get(countRef),
      transaction.get(sharerRef),
      transaction.get(dailyRef),
    ]);
    const dailyCount = countSnap.exists ? countSnap.data().count || 0 : 0;
    const plan = planShare({
      dailyCount,
      sharerSeen: sharerSnap.exists,
      cap: SHARE_DAILY_CAP,
    });
    if (!plan.record) return { recorded: false, newSharer: false };

    transaction.set(countRef, {
      metric: 'shares',
      bucket: day,
      count: dailyCount + 1,
      updatedAt: FieldValue.serverTimestamp(),
      expireAt: Timestamp.fromDate(new Date(eventTime.getTime() + 90 * 86400000)),
    });
    if (plan.newSharer) {
      // One small receipt per account and listing, kept for the listing's
      // lifetime so the unique-sharer count is never double counted.
      transaction.create(sharerRef, {
        metric: 'sharer',
        createdAt: FieldValue.serverTimestamp(),
      });
      transaction.set(analyticsRef, {
        uniqueSharers: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    const previous = dailySnap.exists ? dailySnap.data() : {};
    transaction.set(dailyRef, {
      date: dayStart(day),
      views: previous.views || 0,
      likes: previous.likes || 0,
      saves: previous.saves || 0,
      shares: (previous.shares || 0) + 1,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { recorded: true, newSharer: plan.newSharer };
  });
}

async function recordCallableActivity(request, metric) {
  let listingId;
  try {
    const uid = requireUid(request);
    listingId = requireListingId(request.data);
    const businessId = await getPublishedBusiness(listingId);
    if (businessId == null) {
      throw new HttpsError('not-found', 'This experience is not in the published catalog.');
    }
    const eventTime = new Date();
    if (metric === 'shares') {
      const { recorded } = await recordShare({ businessId, listingId, uid, eventTime });
      return { recorded };
    }
    const bucket = utcDay(eventTime);
    const receiptKey = `${uid}:${metric}:${listingId}:${bucket}`;
    const recorded = await incrementDaily({
      businessId,
      listingId,
      metric,
      bucket,
      receiptKey,
      eventTime,
    });
    return { recorded };
  } catch (error) {
    logger.error('Failed to record business listing activity.', {
      metric,
      listingId: listingId || null,
      error: error?.stack || String(error),
    });
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', 'Could not record this listing activity.');
  }
}

exports.recordListingView = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true },
  (request) => recordCallableActivity(request, 'views'),
);

exports.recordListingShare = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true },
  (request) => recordCallableActivity(request, 'shares'),
);

exports.checkBusinessAnalyticsReady = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true },
  (request) => ({ ready: Boolean(requireUid(request)) }),
);

async function processLikeOrSave(event, metric) {
  const change = event.data;
  if (!change) return;
  const beforeExists = change.before.exists;
  const afterExists = change.after.exists;
  const delta = transitionDelta(beforeExists, afterExists);
  if (delta <= 0) return;

  const { userId, listingId } = event.params;
  const businessId = await getPublishedBusiness(listingId);
  if (businessId == null) return;
  const eventTime = new Date();
  const bucket = utcDay(eventTime);
  await incrementDaily({
    businessId,
    listingId,
    metric,
    bucket,
    receiptKey: `${userId}:${metric}:${listingId}:${bucket}`,
    eventTime,
  });
}

exports.aggregateBusinessSaves = onDocumentWritten(
  'users/{userId}/saved/{listingId}',
  (event) => processLikeOrSave(event, 'saves'),
);

exports.aggregateBusinessLikes = onDocumentWritten(
  'users/{userId}/likes/{listingId}',
  (event) => processLikeOrSave(event, 'likes'),
);

// ---------------------------------------------------------------------------
// Hiding, restoring, deleting and ending live experiences.
//
// The public catalog entry and the small `unavailable` notice that travelers
// who saved the place can read are changed together with the experience, in
// one transaction. Clients never write any of them directly.
// ---------------------------------------------------------------------------

async function assertOwnsBusiness(request, businessId, transaction) {
  const uid = requireUid(request);
  const token = request.auth.token || {};
  if (token.admin === true || token.business_id === businessId) return;
  const business = await transaction.get(db.collection('businesses').doc(businessId));
  if (!business.exists || business.data().ownerUid !== uid) {
    throw new HttpsError('permission-denied', 'You can only manage your own experiences.');
  }
}

// Applies one planned change atomically. `authorize` runs inside the
// transaction so ownership is checked against the same data being changed.
async function applyAvailabilityChange({
  businessId,
  experienceId,
  action,
  message,
  endsAt,
  now,
  authorize,
}) {
  const experienceRef = db
    .collection('businesses').doc(businessId)
    .collection('experiences').doc(experienceId);
  const catalogRef = db.collection('catalog').doc(experienceId);
  const unavailableRef = db.collection('unavailable').doc(experienceId);

  return db.runTransaction(async (transaction) => {
    if (authorize) await authorize(transaction);
    const [experienceSnap, catalogSnap] = await Promise.all([
      transaction.get(experienceRef),
      transaction.get(catalogRef),
    ]);
    const experience = experienceSnap.exists ? experienceSnap.data() : null;
    const plan = planTransition({ action, experience, message, endsAt, now });
    if (!plan.ok) throw new HttpsError(plan.code, plan.message);

    if (plan.deleteExperience) {
      transaction.delete(experienceRef);
      if (catalogSnap.exists) transaction.delete(catalogRef);
    } else {
      const update = { ...plan.experienceSet, updatedAt: FieldValue.serverTimestamp() };
      if (plan.experienceSet.availability) {
        update.availabilityChangedAt = FieldValue.serverTimestamp();
      }
      if (plan.experienceSet.endsAt) {
        update.endsAt = Timestamp.fromDate(plan.experienceSet.endsAt);
      }
      for (const field of plan.experienceClear) update[field] = FieldValue.delete();
      transaction.update(experienceRef, update);
      if (catalogSnap.exists) {
        // The public listing carries the end date so cards and trip planning
        // can show it.
        const catalogUpdate = {};
        if (plan.catalogStatus) catalogUpdate.status = plan.catalogStatus;
        if (plan.experienceSet.endsAt) {
          catalogUpdate.endsAt = Timestamp.fromDate(plan.experienceSet.endsAt);
        }
        if (plan.experienceClear.includes('endsAt')) {
          catalogUpdate.endsAt = FieldValue.delete();
        }
        if (Object.keys(catalogUpdate).length > 0) {
          transaction.update(catalogRef, catalogUpdate);
        }
      }
    }

    if (plan.unavailable) {
      const source = catalogSnap.exists ? catalogSnap.data() : experience;
      transaction.set(unavailableRef, {
        listingId: experienceId,
        title: source?.title || '',
        imageUrl: source?.imageUrl || '',
        destination: source?.destination || '',
        destinationId: source?.destinationId || '',
        category: source?.category || '',
        subcategory: source?.subcategory || '',
        location: source?.location || '',
        areaId: typeof source?.areaId === 'string' ? source.areaId : null,
        reason: plan.unavailable.reason,
        message: plan.unavailable.message,
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else if (plan.catalogStatus === 'published' || plan.deleteExperience) {
      transaction.delete(unavailableRef);
    }
    return { ok: true };
  });
}

function parseEndsAt(value) {
  if (value === null || value === undefined) return null;
  if (typeof value !== 'string') return new Date(NaN);
  return new Date(value);
}

exports.manageExperience = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true },
  async (request) => {
    const data = request.data || {};
    const { businessId, experienceId, action } = data;
    if (!isValidListingId(businessId) || !isValidListingId(experienceId)) {
      throw new HttpsError('invalid-argument', 'A business and experience are required.');
    }
    if (!['hide', 'unhide', 'delete', 'set_end_date', 'set_cover'].includes(action)) {
      throw new HttpsError('invalid-argument', 'Unknown action.');
    }
    if (action === 'set_cover') {
      return setCover({ request, businessId, experienceId, photoUrl: data.photoUrl });
    }
    // Delete is permanent; a deleted experience that was never public is
    // handled by the same path and simply leaves no traveler notice.
    try {
      return await applyAvailabilityChange({
        businessId,
        experienceId,
        action,
        message: data.message,
        endsAt: action === 'set_end_date' ? parseEndsAt(data.endsAt) : undefined,
        now: new Date(),
        authorize: (transaction) => assertOwnsBusiness(request, businessId, transaction),
      });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error('Failed to change experience availability.', {
        action,
        experienceId,
        error: error?.stack || String(error),
      });
      throw new HttpsError('internal', 'Could not update this experience.');
    }
  },
);

// Hourly sweep: anything live whose end date has passed is taken off the
// public list and marked "Ended" for the business and for travelers who saved
// it. Uses the existing collection-group index on `status`; the end date is
// checked here so no extra index is needed while volumes are small.
exports.endExpiredExperiences = onSchedule(
  { schedule: 'every 60 minutes', timeZone: 'UTC' },
  async () => {
    const now = new Date();
    const snapshot = await db
      .collectionGroup('experiences')
      .where('status', '==', 'published')
      .get();
    let ended = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const endsAt = data.endsAt?.toDate?.();
      if (!endsAt || endsAt > now || data.availability === 'ended') continue;
      const businessId = doc.ref.parent.parent.id;
      try {
        await applyAvailabilityChange({
          businessId,
          experienceId: doc.id,
          action: 'end',
          now,
        });
        ended += 1;
      } catch (error) {
        logger.error('Failed to end an expired experience.', {
          experienceId: doc.id,
          error: error?.stack || String(error),
        });
      }
    }
    logger.info('Ended expired experiences.', { ended });
  },
);

// ---------------------------------------------------------------------------
// Photos. Owners upload to a private `pending/` folder. Only an admin's
// approval copies a photo to `public/`, so an unapproved photo is never
// reachable by travelers. Changing which approved photo is the cover only
// reorders photos that were already approved, so it needs no review.
// ---------------------------------------------------------------------------

async function setCover({ request, businessId, experienceId, photoUrl }) {
  const experienceRef = db
    .collection('businesses').doc(businessId)
    .collection('experiences').doc(experienceId);
  const catalogRef = db.collection('catalog').doc(experienceId);
  try {
    return await db.runTransaction(async (transaction) => {
      await assertOwnsBusiness(request, businessId, transaction);
      const [experienceSnap, catalogSnap] = await Promise.all([
        transaction.get(experienceRef),
        transaction.get(catalogRef),
      ]);
      if (!experienceSnap.exists) {
        throw new HttpsError('not-found', 'This experience no longer exists.');
      }
      const plan = planSetCover({
        livePhotos: experienceSnap.data().photos,
        photoUrl,
      });
      if (!plan.ok) throw new HttpsError('invalid-argument', plan.message);
      transaction.update(experienceRef, {
        photos: plan.photos,
        imageUrl: plan.photos[0],
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (catalogSnap.exists) {
        transaction.update(catalogRef, {
          imageUrl: plan.photos[0],
          gallery: plan.photos.slice(1),
        });
      }
      return { ok: true };
    });
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error('Failed to set the cover photo.', {
      experienceId,
      error: error?.stack || String(error),
    });
    throw new HttpsError('internal', 'Could not change the cover photo.');
  }
}

// Admin-only. Copies the photos in a submission or proposed change from the
// private folder to the public one and returns their public urls, cover first.
// It does not change any Firestore document: the admin's review writes the
// urls. Nothing is deleted here, so a failed review loses nothing.
exports.publishExperiencePhotos = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true },
  async (request) => {
    requireUid(request);
    if (request.auth.token.admin !== true) {
      throw new HttpsError('permission-denied', 'Only reviewers can publish photos.');
    }
    const { businessId, experienceId } = request.data || {};
    if (!isValidListingId(businessId) || !isValidListingId(experienceId)) {
      throw new HttpsError('invalid-argument', 'A business and experience are required.');
    }
    const snap = await db
      .collection('businesses').doc(businessId)
      .collection('experiences').doc(experienceId).get();
    if (!snap.exists) throw new HttpsError('not-found', 'This experience no longer exists.');
    const data = snap.data();

    let requested;
    if (data.status === 'published'
        && data.revisionStatus === 'pending_review'
        && data.pendingRevision) {
      requested = data.pendingRevision.photos;
    } else if (data.status === 'pending_review') {
      requested = data.photos;
    } else {
      throw new HttpsError('failed-precondition', 'Nothing is waiting for review.');
    }

    const bucket = getStorage().bucket();
    const plan = planPhotoPublish({
      businessId,
      experienceId,
      requested: requested || [],
      livePhotos: data.photos,
      bucketName: bucket.name,
    });
    if (!plan.ok) throw new HttpsError('invalid-argument', plan.message);

    try {
      for (const entry of plan.entries) {
        if (entry.kind !== 'copy') continue;
        await bucket.file(entry.from).copy(bucket.file(entry.to));
      }
    } catch (error) {
      logger.error('Failed to publish experience photos.', {
        experienceId,
        error: error?.stack || String(error),
      });
      throw new HttpsError('internal', 'Could not publish the photos. Make sure each one finished uploading.');
    }
    return { photos: plan.urls };
  },
);

// The business name is copied onto each public listing, so when an owner
// corrects it the listings are updated to match (hidden ones included).
exports.syncBusinessName = onDocumentUpdated('businesses/{businessId}', async (event) => {
  const before = event.data?.before.data()?.name;
  const after = event.data?.after.data()?.name;
  if (typeof after !== 'string' || !after || before === after) return;
  const { businessId } = event.params;
  const listings = await db.collection('catalog').where('businessId', '==', businessId).get();
  for (let i = 0; i < listings.docs.length; i += 400) {
    const batch = db.batch();
    for (const listing of listings.docs.slice(i, i + 400)) {
      batch.update(listing.ref, { businessName: after, subtitle: after });
    }
    await batch.commit();
  }
  logger.info('Business renamed', { businessId, listings: listings.size });
});

// ---------------------------------------------------------------------------
// Business Pulse: a short timely update on a listing ("Live music tonight").
// One per listing, stored at pulses/{experienceId} and readable by everyone;
// only these functions write it. The text is capped, plain and link-free, so it
// goes live at once instead of waiting for review.
// ---------------------------------------------------------------------------

exports.postPulse = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true },
  async (request) => {
    const { businessId, experienceId, tag, message, hours } = request.data || {};
    if (!isValidListingId(businessId) || !isValidListingId(experienceId)) {
      throw new HttpsError('invalid-argument', 'A business and experience are required.');
    }
    const experienceRef = db
      .collection('businesses').doc(businessId)
      .collection('experiences').doc(experienceId);
    const pulseRef = db.collection('pulses').doc(experienceId);
    const subscriptionRef = db.collection('subscriptions').doc(businessId);
    try {
      return await db.runTransaction(async (transaction) => {
        await assertOwnsBusiness(request, businessId, transaction);
        const [experienceSnap, pulseSnap, subscriptionSnap] = await Promise.all([
          transaction.get(experienceRef),
          transaction.get(pulseRef),
          transaction.get(subscriptionRef),
        ]);
        const experience = experienceSnap.exists ? experienceSnap.data() : undefined;
        const existing = pulseSnap.exists ? pulseSnap.data() : undefined;
        const subscription = subscriptionSnap.exists ? subscriptionSnap.data() : undefined;
        const now = new Date();
        const plan = planPulse({ experience, tag, message, hours, existing, now });
        if (!plan.ok) throw new HttpsError(plan.code, plan.message);
        // A typo fix (same tag, same running time) is free and keeps the
        // original start and end; anything else is a new post that uses the
        // monthly allowance, then bought packs.
        const freeEdit = isFreeEdit({ existing, tag, hours, now });
        const use = planPulseUse({ subscription, freeEdit, now });
        if (!use.ok) throw new HttpsError(use.code, use.message);
        const startsAt = freeEdit ? existing.startsAt : Timestamp.fromDate(plan.pulse.startsAt);
        const expiresAt = freeEdit ? existing.expiresAt : Timestamp.fromDate(plan.pulse.expiresAt);
        transaction.set(pulseRef, {
          listingId: experienceId,
          businessId,
          destinationId: experience.destinationId || '',
          title: experience.title || '',
          category: experience.category || '',
          imageUrl: experience.imageUrl || '',
          tag: plan.pulse.tag,
          message: plan.pulse.message,
          startsAt,
          expiresAt,
        });
        if (Object.keys(use.update).length > 0) {
          transaction.set(subscriptionRef, use.update, { merge: true });
        }
        const after = allowance({ ...(subscription || {}), ...use.update }, now);
        return {
          expiresAt: expiresAt.toDate().toISOString(),
          usedAllowance: !freeEdit,
          remaining: after.remaining,
        };
      });
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error('Failed to post a Pulse.', { experienceId, error: error?.stack || String(error) });
      throw new HttpsError('internal', 'Could not post the Pulse.');
    }
  },
);

exports.endPulse = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true },
  async (request) => {
    const { businessId, experienceId } = request.data || {};
    if (!isValidListingId(businessId) || !isValidListingId(experienceId)) {
      throw new HttpsError('invalid-argument', 'A business and experience are required.');
    }
    try {
      await db.runTransaction(async (transaction) => {
        await assertOwnsBusiness(request, businessId, transaction);
        const pulseRef = db.collection('pulses').doc(experienceId);
        const pulse = await transaction.get(pulseRef);
        // A Pulse belongs to the business that posted it.
        if (pulse.exists && pulse.data().businessId === businessId) {
          transaction.delete(pulseRef);
        }
      });
      return { ended: true };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error('Failed to end a Pulse.', { experienceId, error: error?.stack || String(error) });
      throw new HttpsError('internal', 'Could not end the Pulse.');
    }
  },
);

// Expired Pulses are already hidden by the app; this tidies them away. Hiding or
// deleting a listing ends its Pulse straight away as well, so nobody sees
// "Live music" on something that is no longer available.
exports.cleanupExpiredPulses = onSchedule(
  { schedule: 'every 60 minutes', timeZone: 'UTC' },
  async () => {
    const now = new Date();
    const expired = await db
      .collection('pulses')
      .where('expiresAt', '<=', Timestamp.fromDate(now))
      .limit(400)
      .get();
    const batch = db.batch();
    expired.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    logger.info('Removed expired Pulses.', { removed: expired.size });
  },
);

// When a listing stops being available, its Pulse goes with it.
exports.endPulseWhenUnavailable = onDocumentWritten(
  'catalog/{listingId}',
  async (event) => {
    const after = event.data?.after.data();
    if (after && after.status === 'published') return;
    const pulseRef = db.collection('pulses').doc(event.params.listingId);
    const pulse = await pulseRef.get();
    if (pulse.exists) await pulseRef.delete();
  },
);

// ---------------------------------------------------------------------------
// Plans, Pulse packs and Featured placement (Stripe)
//
// Only these functions change a business's plan, Pulse packs or Featured
// placement, and only after Stripe confirms the payment through the webhook.
// The app never writes to `subscriptions`, `billing_private` or `featured`.
// ---------------------------------------------------------------------------

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');
const appUrl = defineString('APP_URL', { default: '' });
const priceParams = {
  plus: defineString('STRIPE_PRICE_PLUS', { default: '' }),
  pro: defineString('STRIPE_PRICE_PRO', { default: '' }),
  pack5: defineString('STRIPE_PRICE_PACK5', { default: '' }),
  pack10: defineString('STRIPE_PRICE_PACK10', { default: '' }),
  featured7: defineString('STRIPE_PRICE_FEATURED7', { default: '' }),
  featured30: defineString('STRIPE_PRICE_FEATURED30', { default: '' }),
};

function configuredPrices() {
  const prices = {};
  for (const key of Object.keys(priceParams)) prices[key] = priceParams[key].value();
  return prices;
}

function stripeClient() {
  // Required lazily so the unit tests and emulator load without the package
  // being configured.
  const Stripe = require('stripe');
  return new Stripe(stripeSecretKey.value());
}

function appBaseUrl() {
  const base = appUrl.value().replace(/\/+$/, '');
  if (!base) throw new HttpsError('failed-precondition', 'Billing is not set up yet.');
  return base;
}

// Finds or creates the Stripe customer for a business. The ids live in
// `billing_private`, which no client can read.
async function customerFor(stripe, businessId, email) {
  const ref = db.collection('billing_private').doc(businessId);
  const snap = await ref.get();
  if (snap.exists && snap.data().stripeCustomerId) return snap.data().stripeCustomerId;
  const customer = await stripe.customers.create({
    email: email || undefined,
    metadata: { businessId },
  });
  await ref.set({ stripeCustomerId: customer.id }, { merge: true });
  return customer.id;
}

exports.createCheckoutSession = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true, secrets: [stripeSecretKey] },
  async (request) => {
    const { businessId, product, experienceId } = request.data || {};
    if (!isValidListingId(businessId)) {
      throw new HttpsError('invalid-argument', 'A business is required.');
    }
    const definition = PRODUCTS[product];
    if (!definition) throw new HttpsError('invalid-argument', 'Choose something to buy.');
    const priceId = configuredPrices()[product];
    if (!priceId) throw new HttpsError('failed-precondition', 'This option is not available yet.');
    if (definition.featuredDays && !isValidListingId(experienceId)) {
      throw new HttpsError('invalid-argument', 'Choose which experience to feature.');
    }
    const base = appBaseUrl();
    let email = '';
    await db.runTransaction(async (transaction) => {
      await assertOwnsBusiness(request, businessId, transaction);
      const business = await transaction.get(db.collection('businesses').doc(businessId));
      email = business.exists ? business.data().email || '' : '';
      if (definition.featuredDays) {
        const experience = await transaction.get(
          db.collection('businesses').doc(businessId)
            .collection('experiences').doc(experienceId),
        );
        if (!experience.exists || experience.data().status !== 'published') {
          throw new HttpsError('failed-precondition', 'Only live experiences can be featured.');
        }
      }
      if (definition.plan) {
        const subscription = await transaction.get(db.collection('subscriptions').doc(businessId));
        if (effectivePlan(subscription.exists ? subscription.data() : undefined) !== 'free') {
          throw new HttpsError(
            'failed-precondition',
            'You already have a plan. Use Manage billing to change it.',
          );
        }
      }
    });
    try {
      const stripe = stripeClient();
      const customer = await customerFor(stripe, businessId, email);
      const metadata = { businessId, product, experienceId: experienceId || '' };
      const session = await stripe.checkout.sessions.create({
        mode: definition.mode,
        customer,
        client_reference_id: businessId,
        line_items: [{ price: priceId, quantity: 1 }],
        metadata,
        ...(definition.mode === 'subscription' ? { subscription_data: { metadata } } : {}),
        success_url: `${base}/?billing=success`,
        cancel_url: `${base}/?billing=cancel`,
      });
      return { url: session.url };
    } catch (error) {
      logger.error('Failed to start checkout.', { businessId, product, error: error?.stack || String(error) });
      throw new HttpsError('internal', 'Could not start checkout.');
    }
  },
);

exports.createPortalSession = onCall(
  { cors: true, invoker: 'public', enforceAppCheck: true, secrets: [stripeSecretKey] },
  async (request) => {
    const { businessId } = request.data || {};
    if (!isValidListingId(businessId)) {
      throw new HttpsError('invalid-argument', 'A business is required.');
    }
    const base = appBaseUrl();
    await db.runTransaction(async (transaction) => {
      await assertOwnsBusiness(request, businessId, transaction);
    });
    const privateSnap = await db.collection('billing_private').doc(businessId).get();
    const customer = privateSnap.exists ? privateSnap.data().stripeCustomerId : null;
    if (!customer) throw new HttpsError('failed-precondition', 'There is no billing to manage yet.');
    try {
      const session = await stripeClient().billingPortal.sessions.create({
        customer,
        return_url: `${base}/`,
      });
      return { url: session.url };
    } catch (error) {
      logger.error('Failed to open the billing portal.', { businessId, error: error?.stack || String(error) });
      throw new HttpsError('internal', 'Could not open billing.');
    }
  },
);

// Writes a subscription's current state. `businessId` comes from the metadata
// we attached at checkout, or from the customer id as a fallback.
async function applySubscription(transaction, businessId, fields) {
  const subscriptionRef = db.collection('subscriptions').doc(businessId);
  const update = {
    plan: fields.plan,
    status: fields.status,
    cancelAtPeriodEnd: fields.cancelAtPeriodEnd,
    currentPeriodEnd: fields.currentPeriodEnd ? Timestamp.fromDate(fields.currentPeriodEnd) : null,
    updatedAt: FieldValue.serverTimestamp(),
  };
  transaction.set(subscriptionRef, update, { merge: true });
  transaction.set(
    db.collection('businesses').doc(businessId),
    { subscriptionTier: effectivePlan(fields) },
    { merge: true },
  );
}

async function businessForCustomer(customerId) {
  if (!customerId) return null;
  const found = await db
    .collection('billing_private')
    .where('stripeCustomerId', '==', customerId)
    .limit(1)
    .get();
  return found.empty ? null : found.docs[0].id;
}

exports.stripeWebhook = onRequest(
  { secrets: [stripeSecretKey, stripeWebhookSecret], invoker: 'public' },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('POST only');
      return;
    }
    const stripe = stripeClient();
    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        req.headers['stripe-signature'],
        stripeWebhookSecret.value(),
      );
    } catch (error) {
      logger.warn('Rejected a webhook with a bad signature.');
      res.status(400).send('Bad signature');
      return;
    }
    const prices = configuredPrices();
    try {
      const object = event.data.object;
      // Work out what this event means before opening the transaction.
      let subscriptionChange = null;
      let purchase = null;
      if (event.type.startsWith('customer.subscription.')) {
        const businessId =
          object.metadata?.businessId || (await businessForCustomer(object.customer));
        if (businessId) {
          const fields = subscriptionFields(object, prices);
          if (event.type === 'customer.subscription.deleted') {
            fields.plan = 'free';
            fields.status = 'canceled';
          }
          subscriptionChange = { businessId, fields };
        }
      } else if (event.type === 'checkout.session.completed') {
        const businessId = object.metadata?.businessId;
        const definition = PRODUCTS[object.metadata?.product];
        if (businessId && definition) {
          if (definition.mode === 'subscription' && object.subscription) {
            const subscription = await stripe.subscriptions.retrieve(object.subscription);
            subscriptionChange = {
              businessId,
              fields: subscriptionFields(subscription, prices),
            };
          } else if (definition.mode === 'payment' && object.payment_status === 'paid') {
            purchase = {
              businessId,
              pulses: definition.pulses || 0,
              featuredDays: definition.featuredDays || 0,
              experienceId: object.metadata.experienceId || '',
            };
          }
        }
      }
      await db.runTransaction(async (transaction) => {
        const eventRef = db.collection('stripe_events').doc(event.id);
        if ((await transaction.get(eventRef)).exists) return; // already handled
        if (subscriptionChange) {
          await applySubscription(transaction, subscriptionChange.businessId, subscriptionChange.fields);
        }
        if (purchase && purchase.pulses > 0) {
          transaction.set(
            db.collection('subscriptions').doc(purchase.businessId),
            { packBalance: FieldValue.increment(purchase.pulses) },
            { merge: true },
          );
        }
        if (purchase && purchase.featuredDays > 0) {
          const featuredRef = db.collection('featured').doc(purchase.experienceId);
          const [featured, experience] = await Promise.all([
            transaction.get(featuredRef),
            transaction.get(
              db.collection('businesses').doc(purchase.businessId)
                .collection('experiences').doc(purchase.experienceId),
            ),
          ]);
          if (experience.exists) {
            const now = new Date();
            const current = featured.exists ? featured.data().endsAt?.toDate?.() : null;
            transaction.set(featuredRef, {
              listingId: purchase.experienceId,
              businessId: purchase.businessId,
              destinationId: experience.data().destinationId || '',
              startsAt: featured.exists ? featured.data().startsAt : Timestamp.fromDate(now),
              endsAt: Timestamp.fromDate(
                featuredEnd({ currentEnd: current, days: purchase.featuredDays, now }),
              ),
            });
          }
        }
        transaction.set(eventRef, { type: event.type, handledAt: FieldValue.serverTimestamp() });
      });
      res.status(200).send('ok');
    } catch (error) {
      logger.error('Failed to handle a Stripe event.', {
        type: event.type,
        error: error?.stack || String(error),
      });
      // A non-2xx reply makes Stripe retry later.
      res.status(500).send('error');
    }
  },
);
