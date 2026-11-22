import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../models/listing.dart';
import '../../repositories/saved_repository.dart';
import '../components/feedback/de_toast.dart';

/// Saves a listing, or removes it if it is already saved, and says so. Does
/// nothing for a place that is no longer available or when saving is not set up.
void toggleSavedListing(BuildContext context, Listing listing) {
  final repository = context.read<SavedRepository?>();
  if (repository == null || listing.isUnavailable) return;
  final saved = repository.isSaved(listing.id);
  if (saved) {
    repository.remove(listing.id);
  } else {
    repository.save(listingId: listing.id, destination: listing.destination);
  }
  showDEToast(
    context,
    title: saved ? 'Removed from saved' : 'Saved for later',
    message: listing.title,
  );
}
