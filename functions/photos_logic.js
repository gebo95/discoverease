// Pure rules for experience photos. Owners upload to a private `pending/`
// folder; only an admin's approval copies a photo to the public `public/`
// folder, so an unapproved photo is never reachable by travelers.

const MAX_PHOTOS = 5;
const FILE_NAME = /^[A-Za-z0-9_-]{1,80}\.(jpg|jpeg|png|webp)$/;

function pendingPrefix(businessId, experienceId) {
  return `pending/${businessId}/${experienceId}/`;
}

function publicPrefix(businessId, experienceId) {
  return `public/${businessId}/${experienceId}/`;
}

// Public photos are readable by anyone, so a plain media URL works without a
// download token.
function publicUrlFor(bucketName, path) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(path)}?alt=media`;
}

// Works out what to do with a requested photo list (cover first). Each entry
// is either a new private upload to publish, or a photo that is already live
// and is being kept. Nothing is trusted from the client beyond the strings.
function planPhotoPublish({ businessId, experienceId, requested, livePhotos, bucketName }) {
  if (!Array.isArray(requested)) {
    return { ok: false, message: 'Photos must be a list.' };
  }
  if (requested.length > MAX_PHOTOS) {
    return { ok: false, message: `Use at most ${MAX_PHOTOS} photos.` };
  }
  if (new Set(requested).size !== requested.length) {
    return { ok: false, message: 'Each photo can only be used once.' };
  }
  const live = new Set(Array.isArray(livePhotos) ? livePhotos : []);
  const prefix = pendingPrefix(businessId, experienceId);
  const entries = [];
  const urls = [];
  for (const item of requested) {
    if (typeof item !== 'string') {
      return { ok: false, message: 'Every photo must be a text path.' };
    }
    if (item.startsWith(prefix)) {
      const name = item.slice(prefix.length);
      if (!FILE_NAME.test(name)) {
        return { ok: false, message: 'A photo has an invalid file name.' };
      }
      const to = `${publicPrefix(businessId, experienceId)}${name}`;
      const url = publicUrlFor(bucketName, to);
      entries.push({ kind: 'copy', from: item, to, url });
      urls.push(url);
    } else if (live.has(item)) {
      entries.push({ kind: 'keep', url: item });
      urls.push(item);
    } else {
      return { ok: false, message: 'A photo is not part of this experience.' };
    }
  }
  return { ok: true, entries, urls };
}

// Makes one already-approved photo the cover. Only reorders; it can never
// introduce a photo, so it needs no review.
function planSetCover({ livePhotos, photoUrl }) {
  const photos = Array.isArray(livePhotos) ? livePhotos : [];
  if (typeof photoUrl !== 'string' || !photos.includes(photoUrl)) {
    return { ok: false, message: 'Choose one of your approved photos.' };
  }
  return { ok: true, photos: [photoUrl, ...photos.filter((p) => p !== photoUrl)] };
}

module.exports = {
  MAX_PHOTOS,
  FILE_NAME,
  pendingPrefix,
  publicPrefix,
  publicUrlFor,
  planPhotoPublish,
  planSetCover,
};
