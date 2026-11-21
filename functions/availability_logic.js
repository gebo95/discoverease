// Pure rules for hiding, restoring, deleting and ending live experiences.
// Kept free of Firebase imports so every decision can be unit tested.

const MESSAGE_MAX = 280;

// Travelers see this text on their saved places and trips. It skips the
// review queue so a business can explain a closure right away, so it is kept
// to short plain text with no web addresses.
const LINK_PATTERN =
  /(https?:|www\.|\b[a-z0-9-]+\.(com|net|org|io|co|ca|app|me|ly|info|biz|xyz)\b)/i;

function cleanMessage(raw) {
  if (raw === undefined || raw === null) return { ok: true, value: '' };
  if (typeof raw !== 'string') {
    return { ok: false, code: 'invalid-argument', message: 'The message must be text.' };
  }
  const value = raw.trim().replace(/\s+/g, ' ');
  if (value.length > MESSAGE_MAX) {
    return {
      ok: false,
      code: 'invalid-argument',
      message: `Keep the message under ${MESSAGE_MAX} characters.`,
    };
  }
  if (LINK_PATTERN.test(value)) {
    return {
      ok: false,
      code: 'invalid-argument',
      message: 'Leave web addresses out of the message.',
    };
  }
  return { ok: true, value };
}

// A missing availability means the experience is live.
function availabilityOf(experience) {
  const value = experience?.availability;
  return value === 'hidden' || value === 'ended' ? value : 'live';
}

function toMillis(value) {
  if (value === undefined || value === null) return null;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return null;
}

function fail(code, message) {
  return { ok: false, code, message };
}

// Decides what a requested change does. `experience` is the stored
// experience data, `now` a Date, and `endsAt` (for set_end_date) a Date or null.
// Returns the field changes for the experience, whether the public catalog
// entry should be listed, and what travelers should be told.
function planTransition({ action, experience, message, endsAt, now }) {
  if (!experience) return fail('not-found', 'This experience no longer exists.');
  const live = experience.status === 'published';
  const current = availabilityOf(experience);
  const endMs = toMillis(experience.endsAt);

  const cleaned = cleanMessage(message);
  if (!cleaned.ok) return cleaned;

  switch (action) {
    case 'hide': {
      if (!live) return fail('failed-precondition', 'Only live experiences can be hidden.');
      if (current !== 'live') return fail('failed-precondition', 'This experience is already off the public list.');
      return {
        ok: true,
        experienceSet: {
          availability: 'hidden',
          availabilityMessage: cleaned.value,
        },
        experienceClear: [],
        catalogStatus: 'hidden',
        unavailable: { reason: 'temporary', message: cleaned.value },
        deleteExperience: false,
      };
    }
    case 'unhide': {
      if (!live) return fail('failed-precondition', 'Only live experiences can be shown again.');
      if (current === 'live') return fail('failed-precondition', 'This experience is already showing.');
      if (endMs !== null && endMs <= now.getTime()) {
        return fail(
          'failed-precondition',
          'The end date has passed. Set a new end date or remove it first.',
        );
      }
      return {
        ok: true,
        experienceSet: { availability: 'live' },
        experienceClear: ['availabilityMessage'],
        catalogStatus: 'published',
        unavailable: null,
        deleteExperience: false,
      };
    }
    case 'set_end_date': {
      if (endsAt !== null && !(endsAt instanceof Date && !Number.isNaN(endsAt.getTime()))) {
        return fail('invalid-argument', 'Enter a valid end date.');
      }
      if (endsAt !== null && endsAt.getTime() <= now.getTime()) {
        return fail('invalid-argument', 'The end date must be in the future.');
      }
      const result = {
        ok: true,
        experienceSet: {},
        experienceClear: [],
        catalogStatus: null,
        unavailable: null,
        deleteExperience: false,
      };
      if (endsAt === null) result.experienceClear.push('endsAt');
      else result.experienceSet.endsAt = endsAt;
      // Running an ended experience again with a new date puts it back.
      if (live && current === 'ended') {
        result.experienceSet.availability = 'live';
        result.experienceClear.push('availabilityMessage');
        result.catalogStatus = 'published';
        result.unavailable = null;
      }
      return result;
    }
    case 'end': {
      if (!live) return fail('failed-precondition', 'Only live experiences can end.');
      if (current === 'ended') return fail('failed-precondition', 'This experience has already ended.');
      if (endMs === null || endMs > now.getTime()) {
        return fail('failed-precondition', 'This experience has not reached its end date.');
      }
      return {
        ok: true,
        experienceSet: { availability: 'ended', availabilityMessage: '' },
        experienceClear: [],
        catalogStatus: 'hidden',
        unavailable: { reason: 'ended', message: '' },
        deleteExperience: false,
      };
    }
    case 'delete': {
      return {
        ok: true,
        experienceSet: {},
        experienceClear: [],
        catalogStatus: null,
        // Travelers only have something saved if the listing was ever public.
        unavailable: live ? { reason: 'removed', message: cleaned.value } : null,
        deleteExperience: true,
      };
    }
    default:
      return fail('invalid-argument', 'Unknown action.');
  }
}

module.exports = { MESSAGE_MAX, availabilityOf, cleanMessage, planTransition };
