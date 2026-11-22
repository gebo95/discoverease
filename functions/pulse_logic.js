// Pure rules for business Pulse posts: a short, timely update ("Live music
// tonight") shown on a listing's card and in the Happening now section.
// Kept free of Firebase imports so every decision can be unit tested.
// The tag and duration lists are mirrored in lib/models/business_pulse.dart.

const { cleanMessage } = require('./availability_logic');

const PULSE_MESSAGE_MAX = 100;
const COOLDOWN_MS = 30 * 1000;

const PULSE_TAGS = [
  'Live Music',
  'Happy Hour',
  'Daily Special',
  'Event Tonight',
  'Limited Time',
  'Now Open',
  'Open Late',
  'Sunset Special',
  'Family Day',
  'Free Entry',
];

// How long a post stays up, in hours.
const PULSE_DURATIONS = [3, 6, 12, 24, 72, 168];

function fail(code, message) {
  return { ok: false, code, message };
}

function toMillis(value) {
  if (value === undefined || value === null) return null;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return null;
}

// Decides whether a Pulse can be posted and what to store. `experience` is the
// owner's stored experience, `existing` the listing's current Pulse (if any).
// A listing has one Pulse at a time; posting a new one replaces the old.
function planPulse({ experience, tag, message, hours, existing, now }) {
  if (!experience) return fail('not-found', 'This experience no longer exists.');
  if (experience.status !== 'published') {
    return fail('failed-precondition', 'Only live experiences can post a Pulse.');
  }
  if (experience.availability === 'hidden' || experience.availability === 'ended') {
    return fail('failed-precondition', 'Show this experience again before posting a Pulse.');
  }
  if (!PULSE_TAGS.includes(tag)) {
    return fail('invalid-argument', 'Choose what is happening from the list.');
  }
  if (!PULSE_DURATIONS.includes(hours)) {
    return fail('invalid-argument', 'Choose how long the Pulse should stay up.');
  }
  const cleaned = cleanMessage(message);
  if (!cleaned.ok) return cleaned;
  if (cleaned.value.length > PULSE_MESSAGE_MAX) {
    return fail('invalid-argument', `Keep the message under ${PULSE_MESSAGE_MAX} characters.`);
  }
  const startedMs = toMillis(existing?.startsAt);
  if (startedMs !== null && now.getTime() - startedMs < COOLDOWN_MS) {
    return fail('resource-exhausted', 'Please wait a moment before posting again.');
  }
  return {
    ok: true,
    pulse: {
      tag,
      message: cleaned.value,
      hours,
      startsAt: now,
      expiresAt: new Date(now.getTime() + hours * 60 * 60 * 1000),
    },
  };
}

// A Pulse is still showing until its expiry.
function isActive(pulse, now) {
  const expires = toMillis(pulse?.expiresAt);
  return expires !== null && expires > now.getTime();
}

module.exports = {
  COOLDOWN_MS,
  PULSE_DURATIONS,
  PULSE_MESSAGE_MAX,
  PULSE_TAGS,
  isActive,
  planPulse,
};
