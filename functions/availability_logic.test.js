const test = require('node:test');
const assert = require('node:assert/strict');
const {
  MESSAGE_MAX,
  availabilityOf,
  cleanMessage,
  planTransition,
} = require('./availability_logic');

const now = new Date('2026-11-18T12:00:00.000Z');
const later = new Date('2026-12-01T12:00:00.000Z');
const earlier = new Date('2026-11-01T12:00:00.000Z');
const live = (extra = {}) => ({ status: 'published', ...extra });

test('a missing or unknown availability means live', () => {
  assert.equal(availabilityOf({}), 'live');
  assert.equal(availabilityOf({ availability: 'weird' }), 'live');
  assert.equal(availabilityOf({ availability: 'hidden' }), 'hidden');
  assert.equal(availabilityOf(undefined), 'live');
});

test('messages are trimmed, capped and kept free of links', () => {
  assert.deepEqual(cleanMessage(undefined), { ok: true, value: '' });
  assert.equal(cleanMessage('  Back  in   spring! ').value, 'Back in spring!');
  assert.equal(cleanMessage('x'.repeat(MESSAGE_MAX)).ok, true);
  assert.equal(cleanMessage('x'.repeat(MESSAGE_MAX + 1)).ok, false);
  assert.equal(cleanMessage('See https://example.com').ok, false);
  assert.equal(cleanMessage('visit www.example.org').ok, false);
  assert.equal(cleanMessage('book at tours.com now').ok, false);
  assert.equal(cleanMessage(42).ok, false);
});

test('hiding a live experience unlists it and tells travelers it is temporary', () => {
  const plan = planTransition({ action: 'hide', experience: live(), message: 'Closed for repairs', now });
  assert.equal(plan.ok, true);
  assert.equal(plan.catalogStatus, 'hidden');
  assert.equal(plan.experienceSet.availability, 'hidden');
  assert.deepEqual(plan.unavailable, { reason: 'temporary', message: 'Closed for repairs' });
  assert.equal(plan.deleteExperience, false);
});

test('hiding without a message still marks it unavailable', () => {
  const plan = planTransition({ action: 'hide', experience: live(), now });
  assert.equal(plan.ok, true);
  assert.deepEqual(plan.unavailable, { reason: 'temporary', message: '' });
});

test('only live, showing experiences can be hidden', () => {
  assert.equal(planTransition({ action: 'hide', experience: { status: 'pending_review' }, now }).ok, false);
  assert.equal(planTransition({ action: 'hide', experience: live({ availability: 'hidden' }), now }).ok, false);
  assert.equal(planTransition({ action: 'hide', experience: live({ availability: 'ended' }), now }).ok, false);
});

test('hiding rejects a message with a link', () => {
  const plan = planTransition({ action: 'hide', experience: live(), message: 'go to https://x.co', now });
  assert.equal(plan.ok, false);
  assert.equal(plan.code, 'invalid-argument');
});

test('showing a hidden experience relists it and clears the notice', () => {
  const plan = planTransition({
    action: 'unhide',
    experience: live({ availability: 'hidden', availabilityMessage: 'Back soon' }),
    now,
  });
  assert.equal(plan.ok, true);
  assert.equal(plan.catalogStatus, 'published');
  assert.equal(plan.unavailable, null);
  assert.deepEqual(plan.experienceClear, ['availabilityMessage']);
});

test('an experience that is already showing cannot be shown again', () => {
  assert.equal(planTransition({ action: 'unhide', experience: live(), now }).ok, false);
});

test('an ended experience with a past end date cannot be shown without a new date', () => {
  const ended = live({ availability: 'ended', endsAt: earlier });
  assert.equal(planTransition({ action: 'unhide', experience: ended, now }).ok, false);
  const extended = live({ availability: 'ended', endsAt: later });
  assert.equal(planTransition({ action: 'unhide', experience: extended, now }).ok, true);
});

test('setting a future end date stores it and leaves the listing alone', () => {
  const plan = planTransition({ action: 'set_end_date', experience: live(), endsAt: later, now });
  assert.equal(plan.ok, true);
  assert.equal(plan.experienceSet.endsAt, later);
  assert.equal(plan.catalogStatus, null);
});

test('an end date in the past or invalid is refused', () => {
  assert.equal(planTransition({ action: 'set_end_date', experience: live(), endsAt: earlier, now }).ok, false);
  assert.equal(planTransition({ action: 'set_end_date', experience: live(), endsAt: new Date('nope'), now }).ok, false);
  assert.equal(planTransition({ action: 'set_end_date', experience: live(), endsAt: undefined, now }).ok, false);
});

test('removing the end date clears it', () => {
  const plan = planTransition({ action: 'set_end_date', experience: live({ endsAt: later }), endsAt: null, now });
  assert.equal(plan.ok, true);
  assert.deepEqual(plan.experienceClear, ['endsAt']);
});

test('a new end date on an ended experience runs it again', () => {
  const plan = planTransition({
    action: 'set_end_date',
    experience: live({ availability: 'ended', endsAt: earlier }),
    endsAt: later,
    now,
  });
  assert.equal(plan.ok, true);
  assert.equal(plan.experienceSet.availability, 'live');
  assert.equal(plan.catalogStatus, 'published');
  assert.equal(plan.unavailable, null);
});

test('an experience ends only once its end date has passed', () => {
  const due = planTransition({ action: 'end', experience: live({ endsAt: earlier }), now });
  assert.equal(due.ok, true);
  assert.equal(due.catalogStatus, 'hidden');
  assert.deepEqual(due.unavailable, { reason: 'ended', message: '' });
  assert.equal(due.experienceSet.availability, 'ended');

  assert.equal(planTransition({ action: 'end', experience: live({ endsAt: later }), now }).ok, false);
  assert.equal(planTransition({ action: 'end', experience: live(), now }).ok, false);
});

test('an experience that already ended is not ended twice', () => {
  const plan = planTransition({ action: 'end', experience: live({ availability: 'ended', endsAt: earlier }), now });
  assert.equal(plan.ok, false);
});

test('a hidden experience still ends when its date passes', () => {
  const plan = planTransition({ action: 'end', experience: live({ availability: 'hidden', endsAt: earlier }), now });
  assert.equal(plan.ok, true);
});

test('deleting a live experience leaves a notice for travelers who saved it', () => {
  const plan = planTransition({ action: 'delete', experience: live(), message: 'We have closed', now });
  assert.equal(plan.ok, true);
  assert.equal(plan.deleteExperience, true);
  assert.deepEqual(plan.unavailable, { reason: 'removed', message: 'We have closed' });
});

test('deleting something that was never public leaves no notice', () => {
  const plan = planTransition({ action: 'delete', experience: { status: 'pending_review' }, now });
  assert.equal(plan.ok, true);
  assert.equal(plan.deleteExperience, true);
  assert.equal(plan.unavailable, null);
});

test('unknown actions and missing experiences are refused', () => {
  assert.equal(planTransition({ action: 'explode', experience: live(), now }).ok, false);
  assert.equal(planTransition({ action: 'hide', experience: undefined, now }).code, 'not-found');
});
