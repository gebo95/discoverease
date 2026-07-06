import '../mock_data/saved/mock_saved.dart';
import '../models/saved_experience.dart';

class SavedRepository {
  const SavedRepository();

  List<SavedExperience> getSavedForDestination(String destination) {
    return mockSavedExperiences
        .where((saved) => saved.destination == destination)
        .toList();
  }
}
