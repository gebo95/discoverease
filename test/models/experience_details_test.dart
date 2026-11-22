import 'package:discoverease/models/business_profile.dart';
import 'package:discoverease/models/experience_options.dart';
import 'package:flutter_test/flutter_test.dart';

BusinessExperience _live({
  String why = '',
  List<String> perfectFor = const [],
  List<String> features = const [],
  String price = r'$$',
  String subcategory = 'Boat Tour',
}) => BusinessExperience(
  id: 'exp',
  title: 'Sunset Cruise',
  description: 'Evening boat tour.',
  category: 'Tours',
  subcategory: subcategory,
  destinationId: 'nassau',
  destination: 'Nassau',
  location: 'Paradise Island',
  price: price,
  imageUrl: '',
  status: 'published',
  whyYoullLoveIt: why,
  perfectFor: perfectFor,
  features: features,
);

ExperienceRevision _revised(
  BusinessExperience live, {
  String? why,
  List<String>? perfectFor,
  List<String>? features,
  String? price,
}) {
  final base = ExperienceRevision.fromExperience(live);
  return ExperienceRevision(
    title: base.title,
    description: base.description,
    category: base.category,
    subcategory: base.subcategory,
    destinationId: base.destinationId,
    destination: base.destination,
    location: base.location,
    price: price ?? base.price,
    imageUrl: base.imageUrl,
    whyYoullLoveIt: why ?? base.whyYoullLoveIt,
    perfectFor: perfectFor ?? base.perfectFor,
    features: features ?? base.features,
  );
}

void main() {
  group('choices', () {
    test('price has four levels, each with a caption', () {
      expect(priceLevels, [r'$', r'$$', r'$$$', r'$$$$']);
      for (final level in priceLevels) {
        expect(priceCaptions[level], isNotEmpty);
      }
    });

    test('every category has subcategory buttons', () {
      for (final category in const [
        'Activities', 'Dining', 'Tours', 'Entertainment', 'Shopping', 'Other',
      ]) {
        expect(subcategoryChoices(category), isNotEmpty, reason: category);
      }
    });

    test('types from other categories are offered too, after the category\'s own', () {
      final choices = subcategoryChoices('Dining');
      expect(choices.first, subcategoryOptions['Dining']!.first);
      expect(choices, containsAll(['Beach', 'Party', 'Nightlife']));
      expect(choices.toSet().length, choices.length);
    });

    test('a saved type outside every list stays selectable', () {
      expect(subcategoryChoices('Tours', current: ['Pirate Cruise']).first, 'Pirate Cruise');
      expect(subcategoryChoices('Tours', current: ['Boat Tour']), isNot(contains('Pirate Cruise')));
    });

    test('several types are stored as one value and read back', () {
      expect(joinSubcategories(['Bar & Lounge', 'Beach', 'Party']), 'Bar & Lounge, Beach, Party');
      expect(splitSubcategories('Bar & Lounge, Beach,  Party '), ['Bar & Lounge', 'Beach', 'Party']);
      expect(splitSubcategories(''), isEmpty);
      expect(splitSubcategories('Sushi'), ['Sushi']);
    });

    test('tag lists have no duplicates and enough to choose from', () {
      expect(perfectForOptions.toSet().length, perfectForOptions.length);
      expect(featureOptions.toSet().length, featureOptions.length);
      expect(perfectForOptions.length, greaterThan(maxTagChoices));
      expect(featureOptions.length, greaterThan(maxTagChoices));
    });
  });

  group('details on an experience', () {
    test('survive a round trip and default to empty for older records', () {
      final live = _live(
        why: 'Golden hour on the water.',
        perfectFor: ['Couples', 'Friends'],
        features: ['Ocean View'],
      );
      final back = BusinessExperience.fromJson(live.toJson());
      expect(back.whyYoullLoveIt, 'Golden hour on the water.');
      expect(back.perfectFor, ['Couples', 'Friends']);
      expect(back.features, ['Ocean View']);

      final older = BusinessExperience.fromJson({
        'id': 'x',
        'title': 'T',
        'category': 'Tours',
        'destinationId': 'nassau',
        'destination': 'Nassau',
      });
      expect(older.whyYoullLoveIt, '');
      expect(older.perfectFor, isEmpty);
      expect(older.features, isEmpty);
    });

    test('are carried by a revision and shown as differences', () {
      final live = _live(perfectFor: ['Couples']);
      expect(_revised(live).changesFrom(live), isEmpty);

      final changes = _revised(
        live,
        why: ' Great sunsets. ',
        perfectFor: ['Couples', 'Friends'],
        features: ['Romantic'],
        price: r'$$$',
      ).changesFrom(live).map((c) => c.label).toList();
      expect(
        changes,
        containsAll(['Price', "Why you'll love it", 'Perfect for', 'What makes it special']),
      );
    });

    test('revision JSON includes them so approval can copy them to the listing', () {
      final json = _revised(_live(), why: 'Fun', features: ['Ocean View']).toJson();
      expect(json['whyYoullLoveIt'], 'Fun');
      expect(json['features'], ['Ocean View']);
      expect(json['perfectFor'], <String>[]);
    });
  });

  group('map pin', () {
    BusinessExperience withPin(double? lat, double? lng) => BusinessExperience(
      id: 'e', title: 'T', description: '', category: 'Tours', subcategory: '',
      destinationId: 'nassau', destination: 'Nassau', location: 'L', price: r'$',
      imageUrl: '', status: 'published', latitude: lat, longitude: lng,
    );

    test('survives a round trip and is left out when missing', () {
      final json = withPin(25.078, -77.343).toJson();
      expect(json['latitude'], 25.078);
      expect(BusinessExperience.fromJson(json).longitude, -77.343);
      expect(withPin(null, null).toJson().containsKey('latitude'), isFalse);
    });

    test('ignores impossible coordinates', () {
      final parsed = BusinessExperience.fromJson({
        'id': 'x', 'title': 'T', 'category': 'Tours', 'destinationId': 'n',
        'destination': 'N', 'latitude': 200, 'longitude': 'far',
      });
      expect(parsed.latitude, isNull);
      expect(parsed.longitude, isNull);
    });

    test('moving, adding or removing the pin is a reviewable change', () {
      final live = withPin(25.078, -77.343);
      ExperienceRevision pinned(double? lat, double? lng) {
        final base = ExperienceRevision.fromExperience(live);
        return ExperienceRevision(
          title: base.title, description: base.description, category: base.category,
          subcategory: base.subcategory, destinationId: base.destinationId,
          destination: base.destination, location: base.location, price: base.price,
          imageUrl: base.imageUrl, latitude: lat, longitude: lng,
        );
      }

      expect(pinned(25.078, -77.343).changesFrom(live), isEmpty);
      expect(pinned(25.1, -77.3).changesFrom(live).single.label, 'Map pin');
      expect(pinned(null, null).changesFrom(live).single.after, '');
      expect(pinText(25.0443, -77.3504), '25.04430, -77.35040');
    });
  });

  group('highlight tag', () {
    test('survives a round trip, defaults to none, and is a reviewable change', () {
      final live = BusinessExperience(
        id: 'e', title: 'T', description: '', category: 'Tours', subcategory: '',
        destinationId: 'nassau', destination: 'Nassau', location: 'L', price: r'$',
        imageUrl: '', status: 'published', highlight: 'Local Favorite',
      );
      expect(BusinessExperience.fromJson(live.toJson()).highlight, 'Local Favorite');
      expect(
        BusinessExperience.fromJson({
          'id': 'x', 'title': 'T', 'category': 'Tours', 'destinationId': 'n', 'destination': 'N',
        }).highlight,
        '',
      );
      final base = ExperienceRevision.fromExperience(live);
      expect(base.changesFrom(live), isEmpty);
      final changed = ExperienceRevision(
        title: base.title, description: base.description, category: base.category,
        subcategory: base.subcategory, destinationId: base.destinationId,
        destination: base.destination, location: base.location, price: base.price,
        imageUrl: base.imageUrl, highlight: 'Must Try',
      );
      expect(changed.changesFrom(live).single.label, 'Highlight');
    });

    test('choices are unique and short enough for the card', () {
      expect(highlightOptions.toSet().length, highlightOptions.length);
      for (final option in highlightOptions) {
        expect(option.length, lessThanOrEqualTo(40));
      }
    });
  });
}
