import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/repositories/saved_repository.dart';

void main() {
  group('SavedRepository', () {
    test('account hydration replaces guest saves without copying them', () {
      final repository = SavedRepository();
      expect(repository.getAllSaved(), isNotEmpty);

      repository.loadAccountData(const []);

      expect(repository.usingDemoData, isFalse);
      expect(repository.getAllSaved(), isEmpty);
      repository.loadDemoData();
      expect(repository.usingDemoData, isTrue);
      expect(repository.getAllSaved(), isNotEmpty);
    });

    test('saves and removes an experience once per listing', () {
      final repository = SavedRepository();
      var notifications = 0;
      repository.addListener(() => notifications++);

      expect(
        repository.save(listingId: 'test-place', destination: 'Rome'),
        isTrue,
      );
      expect(repository.isSaved('test-place'), isTrue);
      expect(repository.getSavedForDestination('Rome').single.listingId, 'test-place');

      expect(
        repository.save(listingId: 'test-place', destination: 'Rome'),
        isFalse,
      );
      expect(repository.remove('test-place'), isTrue);
      expect(repository.isSaved('test-place'), isFalse);
      expect(repository.remove('test-place'), isFalse);
      expect(notifications, 2);
    });
  });
}
