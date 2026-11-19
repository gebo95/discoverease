import 'package:discoverease/models/business_profile.dart';
import 'package:flutter_test/flutter_test.dart';

BusinessExperience _live() => const BusinessExperience(
  id: 'experience-1',
  title: 'Sunset Cruise',
  description: 'Evening boat tour.',
  category: 'Tours',
  subcategory: 'Boat',
  destinationId: 'nassau',
  destination: 'Nassau',
  location: 'Paradise Island',
  price: r'$$',
  imageUrl: '',
  status: 'published',
  phone: '+1 242 555 0100',
);

void main() {
  group('experience revisions', () {
    test('a revision with no edits has no changes', () {
      final live = _live();
      expect(ExperienceRevision.fromExperience(live).changesFrom(live), isEmpty);
    });

    test('changes list only what differs and ignore stray spaces', () {
      final live = _live();
      final revision = ExperienceRevision.fromExperience(live);
      final edited = ExperienceRevision(
        title: '  Sunset Cruise  ',
        description: 'Evening boat tour with dinner.',
        category: revision.category,
        subcategory: revision.subcategory,
        destinationId: revision.destinationId,
        destination: revision.destination,
        location: revision.location,
        price: revision.price,
        imageUrl: revision.imageUrl,
        phone: revision.phone,
        website: 'example.com',
      );

      final changes = edited.changesFrom(live);
      expect(changes.map((change) => change.label), ['Description', 'Website']);
      expect(changes.last.before, isEmpty);
      expect(changes.last.after, 'https://example.com');
    });

    test('a pending or rejected revision is read from stored data', () {
      final stored = {
        ..._live().toJson(),
        'pendingRevision': {
          ..._live().toJson(),
          'title': 'Sunset Cruise Deluxe',
        },
        'revisionStatus': 'pending_review',
        'revisionNote': '',
      };
      final pending = BusinessExperience.fromJson(stored);
      expect(pending.revision?.title, 'Sunset Cruise Deluxe');
      expect(pending.hasPendingRevision, isTrue);
      expect(pending.hasRejectedRevision, isFalse);

      final rejected = BusinessExperience.fromJson({
        ...stored,
        'revisionStatus': 'rejected',
        'revisionNote': 'Please fix the description.',
      });
      expect(rejected.hasRejectedRevision, isTrue);
      expect(rejected.revisionNote, 'Please fix the description.');
    });

    test('experiences without a proposed change have no revision', () {
      final experience = BusinessExperience.fromJson(_live().toJson());
      expect(experience.revision, isNull);
      expect(experience.hasPendingRevision, isFalse);
      expect(experience.hasRejectedRevision, isFalse);
      // Revision fields are never written when an experience is created.
      expect(experience.toJson().containsKey('pendingRevision'), isFalse);
    });
  });
}
