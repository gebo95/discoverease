const test = require('node:test');
const assert = require('node:assert/strict');
const {
  FAIR_USE_MONTHLY_CAP,
  allowance,
  effectivePlan,
  featuredEnd,
  isFreeEdit,
  monthKey,
  planPulseUse,
  productForPrice,
  subscriptionFields,
} = require('./plans_logic');

const now = new Date('2026-11-21T12:00:00Z');
const ts = (d) => ({ toMillis: () => d.getTime() });

test('monthKey uses the UTC month', () => {
  assert.equal(monthKey(new Date('2026-01-31T23:30:00Z')), '2026-01');
  assert.equal(monthKey(new Date('2026-12-01T00:00:00Z')), '2026-12');
});

test('no subscription means Free with 3 Pulses', () => {
  const a = allowance(undefined, now);
  assert.equal(a.plan, 'free');
  assert.equal(a.limit, 3);
  assert.equal(a.remaining, 3);
});

test('a lapsed paid plan falls back to Free', () => {
  assert.equal(effectivePlan({ plan: 'pro', status: 'canceled' }), 'free');
  assert.equal(effectivePlan({ plan: 'plus', status: 'incomplete' }), 'free');
  assert.equal(effectivePlan({ plan: 'plus', status: 'past_due' }), 'plus');
  assert.equal(effectivePlan({ plan: 'gold', status: 'active' }), 'free');
});

test('usage from an earlier month does not count', () => {
  const a = allowance({ plan: 'free', pulseMonth: '2026-10', pulsesUsed: 3 }, now);
  assert.equal(a.used, 0);
  assert.equal(a.remaining, 3);
});

test('packs add to what is left, after the plan allowance', () => {
  const a = allowance({ plan: 'free', pulseMonth: '2026-11', pulsesUsed: 2, packBalance: 5 }, now);
  assert.equal(a.includedRemaining, 1);
  assert.equal(a.remaining, 6);
});

test('Plus has 15 and Pro is capped by fair use', () => {
  assert.equal(allowance({ plan: 'plus', status: 'active' }, now).limit, 15);
  const pro = allowance({ plan: 'pro', status: 'active' }, now);
  assert.equal(pro.unlimited, true);
  assert.equal(pro.limit, FAIR_USE_MONTHLY_CAP);
});

test('a new post uses the monthly allowance first', () => {
  const r = planPulseUse({ subscription: { plan: 'free' }, freeEdit: false, now });
  assert.equal(r.ok, true);
  assert.equal(r.source, 'monthly');
  assert.deepEqual(r.update, { pulseMonth: '2026-11', pulsesUsed: 1 });
});

test('when the plan is used up it spends a pack', () => {
  const r = planPulseUse({
    subscription: { plan: 'free', pulseMonth: '2026-11', pulsesUsed: 3, packBalance: 2 },
    freeEdit: false,
    now,
  });
  assert.equal(r.source, 'pack');
  assert.equal(r.update.packBalance, 1);
  assert.equal(r.update.pulsesUsed, 3);
});

test('out of Pulses is refused', () => {
  const r = planPulseUse({
    subscription: { plan: 'free', pulseMonth: '2026-11', pulsesUsed: 3 },
    freeEdit: false,
    now,
  });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'resource-exhausted');
});

test('Pro ignores packs and stops at the fair-use cap', () => {
  const r = planPulseUse({
    subscription: {
      plan: 'pro', status: 'active', pulseMonth: '2026-11',
      pulsesUsed: FAIR_USE_MONTHLY_CAP, packBalance: 10,
    },
    freeEdit: false,
    now,
  });
  assert.equal(r.ok, false);
});

test('a typo fix costs nothing, even with no Pulses left', () => {
  const r = planPulseUse({
    subscription: { plan: 'free', pulseMonth: '2026-11', pulsesUsed: 3 },
    freeEdit: true,
    now,
  });
  assert.equal(r.ok, true);
  assert.equal(r.source, 'free-edit');
  assert.deepEqual(r.update, {});
});

test('isFreeEdit needs an active Pulse with the same tag and duration', () => {
  const started = new Date('2026-11-21T10:00:00Z');
  const existing = {
    tag: 'Live Music',
    startsAt: ts(started),
    expiresAt: ts(new Date(started.getTime() + 6 * 3600000)),
  };
  assert.equal(isFreeEdit({ existing, tag: 'Live Music', hours: 6, now }), true);
  assert.equal(isFreeEdit({ existing, tag: 'Happy Hour', hours: 6, now }), false);
  assert.equal(isFreeEdit({ existing, tag: 'Live Music', hours: 12, now }), false);
  assert.equal(isFreeEdit({ existing: undefined, tag: 'Live Music', hours: 6, now }), false);
});

test('an expired Pulse is never a free edit', () => {
  const started = new Date('2026-11-20T10:00:00Z');
  const existing = {
    tag: 'Live Music',
    startsAt: ts(started),
    expiresAt: ts(new Date(started.getTime() + 6 * 3600000)),
  };
  assert.equal(isFreeEdit({ existing, tag: 'Live Music', hours: 6, now }), false);
});

test('prices map back to products', () => {
  const prices = { plus: 'price_a', pro: 'price_b', pack5: 'price_c' };
  assert.equal(productForPrice('price_b', prices).plan, 'pro');
  assert.equal(productForPrice('price_c', prices).pulses, 5);
  assert.equal(productForPrice('price_x', prices), null);
});

test('subscription fields come from the Stripe object', () => {
  const prices = { plus: 'price_a' };
  const fields = subscriptionFields(
    {
      status: 'active',
      cancel_at_period_end: true,
      items: { data: [{ price: { id: 'price_a' }, current_period_end: 1800000000 }] },
    },
    prices,
  );
  assert.equal(fields.plan, 'plus');
  assert.equal(fields.status, 'active');
  assert.equal(fields.cancelAtPeriodEnd, true);
  assert.equal(fields.currentPeriodEnd.getTime(), 1800000000 * 1000);
});

test('an unknown price leaves the business on Free', () => {
  const fields = subscriptionFields(
    { status: 'active', items: { data: [{ price: { id: 'price_zzz' } }] } },
    { plus: 'price_a' },
  );
  assert.equal(fields.plan, 'free');
});

test('Featured placement stacks onto the time left', () => {
  const end = new Date('2026-11-25T12:00:00Z');
  assert.equal(
    featuredEnd({ currentEnd: end, days: 7, now }).toISOString(),
    '2026-12-02T12:00:00.000Z',
  );
  assert.equal(
    featuredEnd({ currentEnd: new Date('2026-11-01T00:00:00Z'), days: 7, now }).toISOString(),
    '2026-11-28T12:00:00.000Z',
  );
});
