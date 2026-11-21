import 'dart:math';

/// Rules for experience photo files, shared by the upload form and tests.
/// The same limits are enforced again by Storage rules and the server.
const int maxExperiencePhotos = 5;
const int maxPhotoBytes = 5 * 1024 * 1024;

/// A photo entry is either a path in the private upload folder (not yet
/// approved) or the public web address of an approved photo.
bool isPendingPhoto(String entry) => entry.startsWith('pending/');

/// The stored extension for a picked file name, or null if it is not a
/// supported image type (JPEG, PNG or WebP).
String? photoExtension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot < 0 || dot == fileName.length - 1) return null;
  switch (fileName.substring(dot + 1).toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'jpg';
    case 'png':
      return 'png';
    case 'webp':
      return 'webp';
  }
  return null;
}

String photoContentType(String extension) => switch (extension) {
  'png' => 'image/png',
  'webp' => 'image/webp',
  _ => 'image/jpeg',
};

/// A random, never-reused file name (uploads are never overwritten).
String newPhotoFileName(String extension, {Random? random}) {
  final rng = random ?? Random.secure();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final id = List.generate(16, (_) => chars[rng.nextInt(chars.length)]).join();
  return '${DateTime.now().millisecondsSinceEpoch}-$id.$extension';
}

/// True if two photo lists hold the same photos, ignoring order.
bool samePhotoSet(List<String> a, List<String> b) =>
    a.length == b.length && a.toSet().containsAll(b);

bool samePhotoOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
