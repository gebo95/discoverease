// Pure rules for business plans, the monthly Pulse allowance, Pulse packs and
// Featured placement. No Firebase or Stripe imports so every decision can be
// unit tested. Plan names and allowances are mirrored in
// lib/models/business_plan.dart.

const PLAN_IDS = ['free', 'plus', 'pro'];

// `monthlyPulses: null` means unlimited, held back only by the fair-use cap.
const PLANS = {
  free: { label: 'Free', monthlyPulses: 3 },
  plus: { label: 'Plus', monthlyPulses: 15 },
  pro: { label: 'Pro', monthlyPulses: null },
};

const FAIR_USE_MONTHLY_CAP = 300;

// One-time purchases. `pulses` adds to the pack balance; `featuredDays` buys
// Featured placement for one listing.
const PRODUCTS = {
  plus: { mode: 'subscription', plan: 'plus' },
  pro: { mode: 'subscription', plan: 'pro' },
  pack5: { mode: 'payment', pulses: 5 },
  pack15: { mode: 'payment', pulses: 15 },
  featured7: { mode: 'payment', featuredDays: 7 },
  featured30: { mode: 'payment', featuredDays: 30 },
};

// Stripe subscription states that still entitle a business to its paid plan.
const ENTITLED_STATUSES = ['active', 'trialing', 'past_due'];

function monthKey(now) {
  const m = String(now.getUTCMonth() + 1).padStart(2, '0');
  return `${now.getUTCFullYear()}-${m}`;
}

// The plan a business pays for: a lapsed or unknown plan falls back to Free.
function paidPlan(subscription) {
  const plan = subscription?.plan;
  if (!PLAN_IDS.includes(plan) || plan === 'free') return 'free';
  if (!ENTITLED_STATUSES.includes(subscription?.status)) return 'free';
  return plan;
}

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  return value instanceof Date ? value : null;
}

// A plan granted by the team (for example a founding partner's free months).
// It counts until `compUntil`, then stops by itself.
function compPlan(subscription, now) {
  const plan = subscription?.compPlan;
  if (!PLAN_IDS.includes(plan) || plan === 'free') return 'free';
  const until = toDate(subscription?.compUntil);
  return until && until.getTime() > now.getTime() ? plan : 'free';
}

// The plan a business actually gets right now: the better of what it pays for
// and what it was granted.
function effectivePlan(subscription, now = new Date()) {
  const paid = paidPlan(subscription);
  const granted = compPlan(subscription, now);
  return PLAN_IDS.indexOf(granted) > PLAN_IDS.indexOf(paid) ? granted : paid;
}

const MAX_GRANT_MONTHS = 24;

// Works out a grant: `free` or 0 months removes it. Returns the fields to
// store, or an error.
function planGrant({ plan, months, now }) {
  if (!PLAN_IDS.includes(plan)) {
    return { ok: false, message: 'Choose Plus, Pro or Remove.' };
  }
  if (plan === 'free' || months === 0) return { ok: true, clear: true };
  if (!Number.isInteger(months) || months < 1 || months > MAX_GRANT_MONTHS) {
    return { ok: false, message: `Choose 1 to ${MAX_GRANT_MONTHS} months.` };
  }
  const until = new Date(now.getTime());
  until.setUTCMonth(until.getUTCMonth() + months);
  return { ok: true, clear: false, plan, until };
}

function nonNegativeInt(value) {
  return Number.isInteger(value) && value > 0 ? value : 0;
}

// What the business has left this month. Usage from an earlier month counts
// as zero, so nothing needs a scheduled reset.
function allowance(subscription, now) {
  const plan = effectivePlan(subscription, now);
  const sameMonth = subscription?.pulseMonth === monthKey(now);
  const used = sameMonth ? nonNegativeInt(subscription?.pulsesUsed) : 0;
  const packBalance = nonNegativeInt(subscription?.packBalance);
  const monthly = PLANS[plan].monthlyPulses;
  const limit = monthly === null ? FAIR_USE_MONTHLY_CAP : monthly;
  const included = Math.max(0, limit - used);
  return {
    plan,
    unlimited: monthly === null,
    limit,
    used,
    packBalance,
    // Pulses that can still be posted: the plan's own, then bought packs.
    remaining: monthly === null ? included : included + packBalance,
    includedRemaining: included,
  };
}

// A typo fix keeps the same tag and the same running time and only changes
// the words, so it never uses an allowance. Anything else is a new post.
function isFreeEdit({ existing, tag, hours, now }) {
  if (!existing || existing.tag !== tag) return false;
  const expires = existing.expiresAt?.toMillis?.() ?? null;
  const started = existing.startsAt?.toMillis?.() ?? null;
  if (expires === null || started === null || expires <= now.getTime()) return false;
  return Math.round((expires - started) / 3600000) === hours;
}

// Decides what a post costs and what to store on the subscription doc.
// Returns { ok: true, source, update } or { ok: false, code, message }.
function planPulseUse({ subscription, freeEdit, now }) {
  if (freeEdit) return { ok: true, source: 'free-edit', update: {} };
  const a = allowance(subscription, now);
  const month = monthKey(now);
  if (a.includedRemaining > 0) {
    return {
      ok: true,
      source: a.unlimited ? 'unlimited' : 'monthly',
      update: { pulseMonth: month, pulsesUsed: a.used + 1 },
    };
  }
  if (!a.unlimited && a.packBalance > 0) {
    return {
      ok: true,
      source: 'pack',
      update: { pulseMonth: month, pulsesUsed: a.used, packBalance: a.packBalance - 1 },
    };
  }
  const message = a.unlimited
    ? 'You have reached this month\'s fair-use limit for Pulses.'
    : 'You are out of Pulses this month. Upgrade your plan or add a Pulse pack.';
  return { ok: false, code: 'resource-exhausted', message };
}

// Maps a Stripe price id back to one of our products, using the configured
// ids: { plus, pro, pack5, pack15, featured7, featured30 }.
function productForPrice(priceId, prices) {
  const key = Object.keys(PRODUCTS).find((k) => prices[k] && prices[k] === priceId);
  return key ? { key, ...PRODUCTS[key] } : null;
}

// Turns a Stripe subscription object into the fields we store.
function subscriptionFields(subscription, prices) {
  const priceId = subscription?.items?.data?.[0]?.price?.id;
  const product = productForPrice(priceId, prices);
  const plan = product?.plan || 'free';
  const endSeconds =
    subscription?.items?.data?.[0]?.current_period_end ?? subscription?.current_period_end;
  return {
    plan,
    status: subscription?.status || 'canceled',
    cancelAtPeriodEnd: subscription?.cancel_at_period_end === true,
    currentPeriodEnd: Number.isFinite(endSeconds) ? new Date(endSeconds * 1000) : null,
  };
}

// Extends Featured placement from whichever is later, now or the current end.
function featuredEnd({ currentEnd, days, now }) {
  const base = currentEnd && currentEnd.getTime() > now.getTime() ? currentEnd : now;
  return new Date(base.getTime() + days * 24 * 60 * 60 * 1000);
}

module.exports = {
  ENTITLED_STATUSES,
  FAIR_USE_MONTHLY_CAP,
  PLANS,
  PLAN_IDS,
  PRODUCTS,
  MAX_GRANT_MONTHS,
  allowance,
  compPlan,
  effectivePlan,
  featuredEnd,
  isFreeEdit,
  monthKey,
  paidPlan,
  planGrant,
  planPulseUse,
  productForPrice,
  subscriptionFields,
};
