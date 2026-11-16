const test = require('node:test');
const assert = require('node:assert/strict');
const {
  utcDay,
  utcMinute,
  digest,
  transitionDelta,
  publishedBusinessId,
} = require('./metrics_logic');

test('daily metric bucket uses UTC calendar day', () => {
  assert.equal(utcDay(new Date('2026-10-22T02:00:00.000Z')), '20261022');
});

test('share dedup bucket is minute-granular in UTC', () => {
  assert.equal(utcMinute(new Date('2026-10-22T02:34:59.000Z')), '202610220234');
});

test('receipt key is a stable opaque digest', () => {
  assert.equal(digest('uid:view:listing:day'), digest('uid:view:listing:day'));
  assert.notEqual(digest('uid:view:listing:day'), 'uid:view:listing:day');
});

test('like/save transitions count creates and ignore updates/deletes as additions', () => {
  assert.equal(transitionDelta(false, true), 1);
  assert.equal(transitionDelta(true, true), 0);
  assert.equal(transitionDelta(true, false), -1);
  assert.equal(transitionDelta(false, false), 0);
});

test('business activity requires both the listing and business to be published', () => {
  const business = { status: 'published' };
  assert.equal(
    publishedBusinessId(
      { status: 'pending_review', businessId: 'business-1' },
      business,
    ),
    null,
  );
  assert.equal(
    publishedBusinessId(
      { status: 'published', businessId: 'business-1' },
      { status: 'pending_review' },
    ),
    null,
  );
  assert.equal(
    publishedBusinessId(
      { status: 'published', businessId: '' },
      business,
    ),
    null,
  );
  assert.equal(
    publishedBusinessId(
      { status: 'published', businessId: 'business-1' },
      business,
    ),
    'business-1',
  );
});

const { SHARE_DAILY_CAP, isValidListingId, planShare } = require('./metrics_logic');

test('listing ids that cannot be Firestore document ids are rejected', () => {
  for (const bad of ['', '   ', 'a/b', '.', '..', '__reserved__', 'x'.repeat(257), 42, null]) {
    assert.equal(isValidListingId(bad), false, `expected ${String(bad)} to be invalid`);
  }
  for (const good of ['sunset-cruise', 'A1b2C3d4E5f6', 'tour_1.2']) {
    assert.equal(isValidListingId(good), true, `expected ${good} to be valid`);
  }
});

test('first share counts as a share and a new unique sharer', () => {
  assert.deepEqual(planShare({ dailyCount: 0, sharerSeen: false }), {
    record: true,
    newSharer: true,
  });
});

test('repeat shares by the same person count as shares but not new sharers', () => {
  assert.deepEqual(planShare({ dailyCount: 1, sharerSeen: true }), {
    record: true,
    newSharer: false,
  });
});

test('shares stop counting once the daily cap is reached', () => {
  assert.deepEqual(planShare({ dailyCount: SHARE_DAILY_CAP, sharerSeen: true }), {
    record: false,
    newSharer: false,
  });
  assert.equal(planShare({ dailyCount: SHARE_DAILY_CAP - 1, sharerSeen: true }).record, true);
});
