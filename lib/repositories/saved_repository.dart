import 'package:flutter/foundation.dart';

import '../mock_data/saved/mock_saved.dart';
import '../models/saved_experience.dart';

class SavedRepository extends ChangeNotifier {
  final List<SavedExperience> _saved = [...mockSavedExperiences];
  bool _usingDemoData = true;

  bool get usingDemoData => _usingDemoData;

  /// Replaces the local demo collection with the signed-in user's saved items.
  void loadAccountData(List<SavedExperience> saved) {
    _usingDemoData = false;
    _saved
      ..clear()
      ..addAll(saved);
    notifyListeners();
  }

  /// Restores demo saves after the signed-in account is disconnected.
  void loadDemoData() {
    _usingDemoData = true;
    _saved
      ..clear()
      ..addAll(mockSavedExperiences);
    notifyListeners();
  }

  List<SavedExperience> getSavedForDestination(String destination) {
    return List.unmodifiable(
      _saved.where((saved) => saved.destination == destination),
    );
  }

  List<SavedExperience> getAllSaved() => List.unmodifiable(_saved);

  bool isSaved(String listingId) {
    return _saved.any((saved) => saved.listingId == listingId);
  }

  /// Adds a saved experience. Account sync is handled by the sync coordinator.
  bool save({required String listingId, required String destination}) {
    if (isSaved(listingId)) return false;

    _saved.add(
      SavedExperience(
        id: 'saved-$listingId',
        listingId: listingId,
        destination: destination,
      ),
    );
    notifyListeners();
    return true;
  }

  bool remove(String listingId) {
    final previousLength = _saved.length;
    _saved.removeWhere((saved) => saved.listingId == listingId);
    if (_saved.length == previousLength) return false;
    notifyListeners();
    return true;
  }
}
