import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/models/business_profile.dart';

void main() {
  group('BusinessExperience', () {
    test('serializes a pending owner submission with a stable schema', () {
      const experience = BusinessExperience(
        id: 'experience-1',
        title: 'Harbour Kayak Tour',
        description: 'A guided tour around the harbour.',
        category: 'Activities',
        subcategory: 'Kayaking',
        destinationId: 'nassau',
        destination: 'Nassau',
        location: 'Prince George Wharf',
        price: r'$$',
        imageUrl: '',
        status: 'pending_review',
      );

      final decoded = BusinessExperience.fromJson(experience.toJson());

      expect(decoded.id, experience.id);
      expect(decoded.title, experience.title);
      expect(decoded.destinationId, experience.destinationId);
      expect(decoded.status, 'pending_review');
      expect(experience.toJson()['schemaVersion'], 1);
    });

    test('reads reviewer feedback without changing the submission schema', () {
      final experience = BusinessExperience.fromJson({
        'schemaVersion': 1,
        'id': 'experience-2',
        'title': 'Harbour Kayak Tour',
        'description': 'A guided tour around the harbour.',
        'category': 'Activities',
        'subcategory': 'Kayaking',
        'destinationId': 'nassau',
        'destination': 'Nassau',
        'location': 'Prince George Wharf',
        'price': r'$$',
        'imageUrl': '',
        'status': 'rejected',
        'reviewNote': 'Please add the tour duration.',
      });

      expect(experience.status, 'rejected');
      expect(experience.reviewNote, 'Please add the tour duration.');
      expect(experience.toJson().containsKey('reviewNote'), isFalse);
    });
  });

  test('reads business profile review status and keeps verification separate', () {
    final profile = BusinessProfile.fromJson({
      'id': 'owner-1',
      'ownerUid': 'owner-1',
      'name': 'Harbour Tours',
      'email': 'hello@example.com',
      'phone': '',
      'website': '',
      'instagram': '',
      'status': 'pending_review',
      'verified': false,
      'subscriptionTier': 'free',
    });

    expect(profile.status, 'pending_review');
    expect(profile.verified, isFalse);
    expect(profile.subscriptionTier, 'free');
  });
}
