const test = require('node:test');
const assert = require('node:assert/strict');
const {
  COOLDOWN_MS,
  PULSE_DURATIONS,
  PULSE_MESSAGE_MAX,
  PULSE_TAGS,
  isActive,
  planPulse,
} = require('./pulse_logic');

const now = new Date('2026-11-21T20:00:00.000Z');
const live = (extra = {}) => ({ status: 'published', ...extra });
const plan = (extra = {}) =>
  planPulse({ experience: live(), tag: 'Live Music', hours: 6, now, ...extra });

test('a live experience can post a Pulse that expires after the chosen time', () => {
  const result = plan({ message: '  Band starts at 8  ' });
  assert.equal(result.ok, true);
  assert.equal(result.pulse.tag, 'Live Music');
  assert.equal(result.pulse.message, 'Band starts at 8');
  assert.equal(result.pulse.expiresAt.toISOString(), '2026-11-22T02:00:00.000Z');
  assert.equal(result.pulse.startsAt, now);
});

test('the message is optional', () => {
  assert.equal(plan().ok, true);
  assert.equal(plan().pulse.message, '');
});

test('only live, showing experiences can post', () => {
  assert.equal(plan({ experience: undefined }).code, 'not-found');
  assert.equal(plan({ experience: { status: 'pending_review' } }).ok, false);
  assert.equal(plan({ experience: live({ availability: 'hidden' }) }).ok, false);
  assert.equal(plan({ experience: live({ availability: 'ended' }) }).ok, false);
  assert.equal(plan({ experience: live({ availability: 'live' }) }).ok, true);
});

test('the tag and duration must come from the lists', () => {
  assert.equal(plan({ tag: 'Buy my stuff' }).code, 'invalid-argument');
  assert.equal(plan({ tag: undefined }).ok, false);
  assert.equal(plan({ hours: 5 }).ok, false);
  assert.equal(plan({ hours: '6' }).ok, false);
  for (const tag of PULSE_TAGS) assert.equal(plan({ tag }).ok, true, tag);
  for (const hours of PULSE_DURATIONS) assert.equal(plan({ hours }).ok, true, String(hours));
});

test('the message is short plain text with no web addresses', () => {
  assert.equal(plan({ message: 'x'.repeat(PULSE_MESSAGE_MAX) }).ok, true);
  assert.equal(plan({ message: 'x'.repeat(PULSE_MESSAGE_MAX + 1) }).ok, false);
  assert.equal(plan({ message: 'see https://example.com' }).ok, false);
  assert.equal(plan({ message: 'visit tours.com' }).ok, false);
  assert.equal(plan({ message: 42 }).ok, false);
});

test('posting again too quickly is refused, but a new one replaces an old one later', () => {
  const justNow = { startsAt: new Date(now.getTime() - COOLDOWN_MS + 1000) };
  assert.equal(plan({ existing: justNow }).code, 'resource-exhausted');
  const earlier = { startsAt: new Date(now.getTime() - COOLDOWN_MS - 1000) };
  assert.equal(plan({ existing: earlier }).ok, true);
});

test('a Pulse shows until it expires', () => {
  assert.equal(isActive({ expiresAt: new Date(now.getTime() + 1000) }, now), true);
  assert.equal(isActive({ expiresAt: new Date(now.getTime() - 1000) }, now), false);
  assert.equal(isActive({ expiresAt: now }, now), false);
  assert.equal(isActive({}, now), false);
  assert.equal(isActive(undefined, now), false);
});
