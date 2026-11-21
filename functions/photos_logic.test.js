const test = require('node:test');
const assert = require('node:assert/strict');
const {
  MAX_PHOTOS,
  planPhotoPublish,
  planSetCover,
  publicUrlFor,
} = require('./photos_logic');

const base = { businessId: 'biz-1', experienceId: 'exp-1', bucketName: 'demo.appspot.com' };
const pending = (name) => `pending/biz-1/exp-1/${name}`;
const liveUrl = publicUrlFor('demo.appspot.com', 'public/biz-1/exp-1/old.jpg');

test('a new upload is copied to the public folder and gets a public url', () => {
  const plan = planPhotoPublish({ ...base, requested: [pending('a1.jpg')], livePhotos: [] });
  assert.equal(plan.ok, true);
  assert.deepEqual(plan.entries[0].kind, 'copy');
  assert.equal(plan.entries[0].to, 'public/biz-1/exp-1/a1.jpg');
  assert.equal(
    plan.urls[0],
    'https://firebasestorage.googleapis.com/v0/b/demo.appspot.com/o/public%2Fbiz-1%2Fexp-1%2Fa1.jpg?alt=media',
  );
});

test('a photo that is already live can be kept, and order is preserved', () => {
  const plan = planPhotoPublish({
    ...base,
    requested: [pending('new.png'), liveUrl],
    livePhotos: [liveUrl],
  });
  assert.equal(plan.ok, true);
  assert.deepEqual(plan.entries.map((e) => e.kind), ['copy', 'keep']);
  assert.equal(plan.urls[1], liveUrl);
});

test('an unknown url is refused', () => {
  const plan = planPhotoPublish({ ...base, requested: ['https://evil.example/x.jpg'], livePhotos: [liveUrl] });
  assert.equal(plan.ok, false);
});

test('a path in another business or experience is refused', () => {
  for (const path of ['pending/biz-2/exp-1/a.jpg', 'pending/biz-1/exp-2/a.jpg', 'public/biz-1/exp-1/a.jpg']) {
    assert.equal(planPhotoPublish({ ...base, requested: [path], livePhotos: [] }).ok, false, path);
  }
});

test('file names are limited to safe image names', () => {
  for (const name of ['../a.jpg', 'a.gif', 'a b.jpg', 'a.jpg.exe', '.jpg', 'a/b.jpg']) {
    assert.equal(planPhotoPublish({ ...base, requested: [pending(name)], livePhotos: [] }).ok, false, name);
  }
  for (const name of ['a.jpg', 'A-1_b.PNG'.toLowerCase(), 'c.webp', 'd.jpeg']) {
    assert.equal(planPhotoPublish({ ...base, requested: [pending(name)], livePhotos: [] }).ok, true, name);
  }
});

test('too many, repeated or non-text photos are refused', () => {
  const many = Array.from({ length: MAX_PHOTOS + 1 }, (_, i) => pending(`p${i}.jpg`));
  assert.equal(planPhotoPublish({ ...base, requested: many, livePhotos: [] }).ok, false);
  assert.equal(planPhotoPublish({ ...base, requested: [pending('a.jpg'), pending('a.jpg')], livePhotos: [] }).ok, false);
  assert.equal(planPhotoPublish({ ...base, requested: [42], livePhotos: [] }).ok, false);
  assert.equal(planPhotoPublish({ ...base, requested: 'nope', livePhotos: [] }).ok, false);
});

test('exactly the maximum number of photos is fine, and none is fine', () => {
  const max = Array.from({ length: MAX_PHOTOS }, (_, i) => pending(`p${i}.jpg`));
  assert.equal(planPhotoPublish({ ...base, requested: max, livePhotos: [] }).ok, true);
  const none = planPhotoPublish({ ...base, requested: [], livePhotos: [] });
  assert.equal(none.ok, true);
  assert.deepEqual(none.urls, []);
});

test('setting a cover moves that photo first and keeps the rest in order', () => {
  const plan = planSetCover({ livePhotos: ['a', 'b', 'c'], photoUrl: 'c' });
  assert.deepEqual(plan, { ok: true, photos: ['c', 'a', 'b'] });
});

test('a cover must be one of the approved photos', () => {
  assert.equal(planSetCover({ livePhotos: ['a'], photoUrl: 'z' }).ok, false);
  assert.equal(planSetCover({ livePhotos: undefined, photoUrl: 'a' }).ok, false);
  assert.equal(planSetCover({ livePhotos: ['a'], photoUrl: 42 }).ok, false);
});
