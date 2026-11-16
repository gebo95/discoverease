const { initializeApp } = require('firebase-admin/app');
const { FieldValue, Timestamp, getFirestore } = require('firebase-admin/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
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
