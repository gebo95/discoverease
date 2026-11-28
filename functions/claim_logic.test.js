const test = require('node:test');
const assert = require('node:assert/strict');
const {
  CODE_LIFETIME_MS,
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
} = require('./claim_logic');

const now = new Date('2026-11-25T12:00:00Z');
const business = { claimStatus: 'unclaimed', email: 'owner@cafe.com' };

test('emails and phones are masked', () => {
  assert.equal(maskEmail('owner@cafe.com'), 'ow***@cafe.com');
  assert.equal(maskEmail('a@cafe.com'), 'a***@cafe.com');
  assert.equal(maskEmail('nonsense'), '');
  assert.equal(maskEmail(undefined), '');
  assert.equal(maskPhone('+1 (242) 555-0167'), '***67');
  assert.equal(maskPhone('12'), '');
});

test('email check is plain but strict about the basics', () => {
  assert.equal(isPlausibleEmail('a@b.co'), true);
  assert.equal(isPlausibleEmail('a b@c.com'), false);
  assert.equal(isPlausibleEmail('a@b'), false);
  assert.equal(isPlausibleEmail(''), false);
});

test('codes are six digits, padded', () => {
  assert.equal(newCode(() => 42), '000042');
  assert.match(newCode(), /^\d{6}$/);
});

test('only the right code matches, and a hash is stored not the code', () => {
  const hash = hashCode('123456', 'salt');
  assert.notEqual(hash, '123456');
  assert.equal(codeMatches('123456', 'salt', hash), true);
  assert.equal(codeMatches(' 123456 ', 'salt', hash), true);
  assert.equal(codeMatches('654321', 'salt', hash), false);
  assert.equal(codeMatches('123456', 'other', hash), false);
  assert.equal(codeMatches('12345', 'salt', hash), false);
  assert.equal(codeMatches('abcdef', 'salt', hash), false);
  assert.equal(codeMatches('123456', 'salt', ''), false);
});

test('a code is sent to the email on file with a hashed record', () => {
  const r = planSend({ business, userId: 'u1', pending: undefined, userSends: [], now });
  assert.equal(r.ok, true);
  assert.equal(r.email, 'owner@cafe.com');
  assert.match(r.code, /^\d{6}$/);
  assert.equal(r.pending.uid, 'u1');
  assert.equal(r.pending.attempts, 0);
  assert.equal(r.pending.expiresAt.getTime(), now.getTime() + CODE_LIFETIME_MS);
  assert.equal(codeMatches(r.code, r.pending.salt, r.pending.codeHash), true);
  assert.equal(JSON.stringify(r.pending).includes(r.code), false);
});

test('a claimed or missing business cannot be claimed', () => {
  assert.equal(planSend({ business: undefined, userId: 'u1', now }).code, 'not-found');
  assert.equal(
    planSend({ business: { ...business, claimStatus: 'claimed' }, userId: 'u1', now }).ok,
    false,
  );
});

test('no usable email on file is explained', () => {
  const r = planSend({ business: { claimStatus: 'unclaimed', email: '' }, userId: 'u1', now });
  assert.equal(r.ok, false);
  assert.match(r.message, /no email/);
});

test('codes are rate limited per business, per person, and with a cooldown', () => {
  const justNow = now.getTime() - (RESEND_COOLDOWN_MS - 1000);
  assert.equal(
    planSend({ business, userId: 'u1', pending: { sends: [justNow] }, userSends: [], now }).code,
    'resource-exhausted',
  );
  const t = now.getTime();
  const three = [t - 50 * 60000, t - 40 * 60000, t - 30 * 60000];
  assert.equal(
    planSend({ business, userId: 'u1', pending: { sends: three }, userSends: [], now }).ok,
    false,
  );
  const six = Array.from({ length: 6 }, (_, i) => t - (10 + i) * 60000);
  assert.equal(planSend({ business, userId: 'u1', pending: undefined, userSends: six, now }).ok, false);
  const old = [t - 2 * 3600 * 1000];
  assert.equal(planSend({ business, userId: 'u1', pending: { sends: old }, userSends: old, now }).ok, true);
});

function pendingFor(code, overrides = {}) {
  const salt = 'abc';
  return {
    uid: 'u1',
    salt,
    codeHash: hashCode(code, salt),
    expiresAt: new Date(now.getTime() + 60000),
    attempts: 0,
    ...overrides,
  };
}

test('the right code from the same person confirms', () => {
  assert.equal(planConfirm({ pending: pendingFor('111111'), userId: 'u1', code: '111111', now }).ok, true);
});

test('another person cannot use the code', () => {
  assert.equal(planConfirm({ pending: pendingFor('111111'), userId: 'u2', code: '111111', now }).ok, false);
  assert.equal(planConfirm({ pending: undefined, userId: 'u1', code: '111111', now }).ok, false);
});

test('a wrong code counts a try and says how many are left', () => {
  const r = planConfirm({ pending: pendingFor('111111'), userId: 'u1', code: '222222', now });
  assert.equal(r.ok, false);
  assert.equal(r.wrong, true);
  assert.match(r.message, /4 tries left/);
});

test('after too many wrong tries even the right code is refused', () => {
  const r = planConfirm({
    pending: pendingFor('111111', { attempts: MAX_WRONG_TRIES }),
    userId: 'u1',
    code: '111111',
    now,
  });
  assert.equal(r.ok, false);
  assert.equal(r.code, 'resource-exhausted');
});

test('an expired code is refused', () => {
  const r = planConfirm({
    pending: pendingFor('111111', { expiresAt: new Date(now.getTime() - 1) }),
    userId: 'u1',
    code: '111111',
    now,
  });
  assert.equal(r.code, 'deadline-exceeded');
});

test('help requests are limited per day', () => {
  assert.equal(planRequest({ business, recentRequests: [], now }).ok, true);
  const t = now.getTime();
  assert.equal(planRequest({ business, recentRequests: [t - 1000, t - 2000, t - 3000], now }).ok, false);
  assert.equal(planRequest({ business, recentRequests: [t - 30 * 3600 * 1000], now }).ok, true);
  assert.equal(planRequest({ business: { claimStatus: 'claimed' }, recentRequests: [], now }).ok, false);
});

test('free text is trimmed and capped', () => {
  assert.equal(cleanText('  hi   there ', 50), 'hi there');
  assert.equal(cleanText('x'.repeat(500), 10).length, 10);
  assert.equal(cleanText(5, 10), '');
});

test('only a claimed business can be taken back, and it goes back up for claiming', () => {
  const claimed = {
    claimStatus: 'claimed',
    ownerUid: 'u1',
    name: 'Cafe',
    email: 'owner@cafe.com',
    phone: '+1 242 555 0167',
  };
  const r = planRevoke({ business: claimed });
  assert.equal(r.ok, true);
  assert.equal(r.previousOwnerUid, 'u1');
  assert.deepEqual(r.claimable, { name: 'Cafe', emailHint: 'ow***@cafe.com', phoneHint: '***67' });
  assert.equal(planRevoke({ business: { ...claimed, claimStatus: 'unclaimed' } }).ok, false);
  assert.equal(planRevoke({ business: { ...claimed, ownerUid: '' } }).ok, false);
  assert.equal(planRevoke({ business: undefined }).code, 'not-found');
  // A business that signed up by itself is not touched by this tool.
  assert.equal(planRevoke({ business: { ownerUid: 'u1', name: 'Self' } }).ok, false);
});
