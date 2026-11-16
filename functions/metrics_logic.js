const { createHash } = require('node:crypto');

function utcDay(date) {
  return date.toISOString().slice(0, 10).replaceAll('-', '');
}

function utcMinute(date) {
  return date.toISOString().slice(0, 16).replaceAll(/[-:T]/g, '');
}

function digest(value) {
  return createHash('sha256').update(value).digest('hex');
}

function transitionDelta(beforeExists, afterExists) {
  if (!beforeExists && afterExists) return 1;
  if (beforeExists && !afterExists) return -1;
  return 0;
}

function publishedBusinessId(listing, business) {
  if (listing?.status !== 'published' || business?.status !== 'published') {
    return null;
  }
  const businessId = listing.businessId;
  return typeof businessId === 'string' && businessId.length > 0
    ? businessId
    : null;
}

// Share actions counted per account, listing, and UTC day. Extra taps are
// ignored so one person cannot inflate a business's share total.
const SHARE_DAILY_CAP = 5;

// Firestore document IDs cannot contain '/', cannot be '.' or '..', and cannot
// match the reserved __name__ pattern.
function isValidListingId(id) {
  return (
    typeof id === 'string' &&
    id.trim().length > 0 &&
    id.length <= 256 &&
    !id.includes('/') &&
    id !== '.' &&
    id !== '..' &&
    !/^__.*__$/.test(id)
  );
}

// Decides what a share action changes. `dailyCount` is how many shares this
// account already had counted for the listing today; `sharerSeen` is whether
// this account has ever had a share counted for the listing.
function planShare({ dailyCount, sharerSeen, cap = SHARE_DAILY_CAP }) {
  if (dailyCount >= cap) return { record: false, newSharer: false };
  return { record: true, newSharer: !sharerSeen };
}

module.exports = {
  SHARE_DAILY_CAP,
  isValidListingId,
  planShare,
  utcDay,
  utcMinute,
  digest,
  transitionDelta,
  publishedBusinessId,
};
