import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../shared/utils/photo_files.dart';

/// Uploads experience photos to the private `pending/` folder and resolves
/// photo entries to viewable addresses. Photos only become public when an
/// admin approves them (a Cloud Function copies them to `public/`).
class ExperiencePhotoService {
  ExperiencePhotoService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads one image and returns its storage path (what is saved on the
  /// experience). Throws [StateError] with a plain message if the file is not
  /// allowed.
  Future<String> uploadPending({
    required String businessId,
    required String experienceId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = photoExtension(fileName);
    if (extension == null) {
      throw StateError('Use a JPEG, PNG or WebP photo.');
    }
    if (bytes.isEmpty) throw StateError('That photo appears to be empty.');
    if (bytes.length > maxPhotoBytes) {
      throw StateError('Each photo must be under 5 MB.');
    }
    final path =
        'pending/$businessId/$experienceId/${newPhotoFileName(extension)}';
    await _storage
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(contentType: photoContentType(extension)),
        );
    return path;
  }

  /// Removes a not-yet-approved upload. Approved photos are never deleted here.
  Future<void> deletePending(String path) async {
    if (!isPendingPhoto(path)) return;
    try {
      await _storage.ref(path).delete();
    } catch (_) {
      // Already gone or not ours to delete; nothing to do.
    }
  }

  /// A web address that can be shown for a photo entry. Approved photos
  /// already are one; pending uploads need a short-lived download address,
  /// which only the owner and reviewers are allowed to get.
  Future<String> urlFor(String entry) =>
      isPendingPhoto(entry) ? _storage.ref(entry).getDownloadURL() : Future.value(entry);
}
