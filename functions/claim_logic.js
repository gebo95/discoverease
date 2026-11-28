// Pure rules for claiming a business: who may ask for a code, how long a code
// lives, how many wrong tries are allowed, and how contact details are hidden.
// No Firebase or email imports so every decision can be unit tested.

const crypto = require('node:crypto');

const CODE_DIGITS = 6;
const CODE_LIFETIME_MS = 15 * 60 * 1000;
const MAX_WRONG_TRIES = 5;
const RESEND_COOLDOWN_MS = 60 * 1000;
const WINDOW_MS = 60 * 60 * 1000;
const MAX_SENDS_PER_BUSINESS_PER_HOUR = 3;
const MAX_SENDS_PER_USER_PER_HOUR = 6;
const MAX_REQUESTS_PER_USER_PER_DAY = 3;

function fail(code, message) {
  return { ok: false, code, message };
}

// "jo***@gmail.com": enough for the owner to recognise it, not enough for a
// stranger to learn the address.
function maskEmail(email) {
  if (typeof email !== 'string') return '';
  const clean = email.trim();
  const at = clean.lastIndexOf('@');
  if (at < 1 || at === clean.length - 1) return '';
  const name = clean.slice(0, at);
  const shown = name.slice(0, Math.min(2, name.length - 1 > 0 ? 2 : 1));
  return `${shown}***${clean.slice(at)}`;
}

// "***-**67": only the last two digits.
function maskPhone(phone) {
  if (typeof phone !== 'string') return '';
  const digits = phone.replace(/\D/g, '');
  if (digits.length < 4) return '';
  return `***${digits.slice(-2)}`;
}

function isPlausibleEmail(email) {
  return typeof email === 'string'
    && email.length <= 254
    && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

// A fresh numeric code. `randomInt` can be replaced in tests.
function newCode(randomInt = crypto.randomInt) {
  return String(randomInt(0, 10 ** CODE_DIGITS)).padStart(CODE_DIGITS, '0');
}

function newSalt() {
  return crypto.randomBytes(16).toString('hex');
}

// Only a hash of the code is stored, so a leaked database does not leak codes.
function hashCode(code, salt) {
  return crypto.createHash('sha256').update(`${salt}:${code}`).digest('hex');
}

function codeMatches(code, salt, expectedHash) {
  if (typeof code !== 'string' || !/^\d{6}$/.test(code.trim())) return false;
  const actual = Buffer.from(hashCode(code.trim(), salt), 'hex');
  const expected = Buffer.from(String(expectedHash || ''), 'hex');
  return actual.length === expected.length && crypto.timingSafeEqual(actual, expected);
}

function recent(sends, now) {
  return (Array.isArray(sends) ? sends : []).filter(
    (ms) => Number.isFinite(ms) && now.getTime() - ms < WINDOW_MS,
  );
}

// Decides whether a code may be sent now. `business` is the stored business,
// `pending` the current claim_codes doc for it, `userSends` the sign-in's
// recent send times (milliseconds).
function planSend({ business, userId, pending, userSends, now }) {
  if (!business) return fail('not-found', 'That business was not found.');
  if (business.claimStatus !== 'unclaimed') {
    return fail('failed-precondition', 'This business has already been claimed.');
  }
  if (!isPlausibleEmail(business.email)) {
    return fail(
      'failed-precondition',
      'We have no email on file for this business. Use "I can\'t get the code".',
    );
  }
  const businessSends = recent(pending?.sends, now);
  const lastSend = Math.max(0, ...businessSends);
  if (lastSend && now.getTime() - lastSend < RESEND_COOLDOWN_MS) {
    return fail('resource-exhausted', 'Please wait a minute before asking for another code.');
  }
  if (businessSends.length >= MAX_SENDS_PER_BUSINESS_PER_HOUR) {
    return fail('resource-exhausted', 'Too many codes were requested for this business. Try again in an hour.');
  }
  const mine = recent(userSends, now);
  if (mine.length >= MAX_SENDS_PER_USER_PER_HOUR) {
    return fail('resource-exhausted', 'You have asked for too many codes. Try again in an hour.');
  }
  const salt = newSalt();
  const code = newCode();
  return {
    ok: true,
    code,
    email: business.email.trim(),
    pending: {
      uid: userId,
      salt,
      codeHash: hashCode(code, salt),
      expiresAt: new Date(now.getTime() + CODE_LIFETIME_MS),
      attempts: 0,
      sends: [...businessSends, now.getTime()],
    },
    userSends: [...mine, now.getTime()],
  };
}

// Decides what a typed code means. On a wrong code the caller stores the
// increased attempt count; on a right one it makes the user the owner.
function planConfirm({ pending, userId, code, now }) {
  if (!pending || pending.uid !== userId) {
    return fail('failed-precondition', 'Ask for a new code first.');
  }
  const expires = pending.expiresAt?.toMillis?.() ?? pending.expiresAt?.getTime?.() ?? 0;
  if (expires <= now.getTime()) {
    return fail('deadline-exceeded', 'That code has expired. Ask for a new one.');
  }
  if ((pending.attempts || 0) >= MAX_WRONG_TRIES) {
    return fail('resource-exhausted', 'Too many wrong tries. Ask for a new code.');
  }
  if (!codeMatches(code, pending.salt, pending.codeHash)) {
    const left = MAX_WRONG_TRIES - ((pending.attempts || 0) + 1);
    return {
      ok: false,
      wrong: true,
      code: 'permission-denied',
      message: left > 0
        ? `That code is not right. ${left} ${left === 1 ? 'try' : 'tries'} left.`
        : 'Too many wrong tries. Ask for a new code.',
    };
  }
  return { ok: true };
}

// Whether someone may submit another "I can't get the code" request.
function planRequest({ business, recentRequests, now }) {
  if (!business) return fail('not-found', 'That business was not found.');
  if (business.claimStatus !== 'unclaimed') {
    return fail('failed-precondition', 'This business has already been claimed.');
  }
  const day = 24 * 60 * 60 * 1000;
  const mine = (Array.isArray(recentRequests) ? recentRequests : []).filter(
    (ms) => Number.isFinite(ms) && now.getTime() - ms < day,
  );
  if (mine.length >= MAX_REQUESTS_PER_USER_PER_DAY) {
    return fail('resource-exhausted', 'You have sent enough requests for today. We will review them.');
  }
  return { ok: true, requests: [...mine, now.getTime()] };
}

// Whether an admin can take a business back from its owner, and what the
// business looks like for claiming again.
function planRevoke({ business }) {
  if (!business) return fail('not-found', 'That business was not found.');
  if (business.claimStatus !== 'claimed' || !business.ownerUid) {
    return fail('failed-precondition', 'Only a business that was claimed can be taken back this way.');
  }
  return {
    ok: true,
    previousOwnerUid: business.ownerUid,
    claimable: {
      name: business.name || '',
      emailHint: maskEmail(business.email),
      phoneHint: maskPhone(business.phone),
    },
  };
}

function cleanText(value, max) {
  return typeof value === 'string' ? value.trim().replace(/\s+/g, ' ').slice(0, max) : '';
}

module.exports = {
  CODE_DIGITS,
  CODE_LIFETIME_MS,
  MAX_REQUESTS_PER_USER_PER_DAY,
  MAX_SENDS_PER_BUSINESS_PER_HOUR,
  MAX_SENDS_PER_USER_PER_HOUR,
  MAX_WRONG_TRIES,
  RESEND_COOLDOWN_MS,
  cleanText,
  codeMatches,
  hashCode,
  isPlausibleEmail,
  maskEmail,
  maskPhone,
  newCode,
  planConfirm,
  planRequest,
  planRevoke,
  planSend,
};
