import 'package:discoverease/features/saved/utils/saved_group_builder.dart';
import 'package:discoverease/models/saved_experience.dart';
import 'package:discoverease/repositories/destination_repository.dart';
import 'package:discoverease/repositories/listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups saved experiences by country, area, then user-facing category', () {
    final listings = ListingRepository();
    final destinations = DestinationRepository();
    final groups = SavedGroupBuilder.build(
      saved: const [
        SavedExperience(
          id: 'save-food',
          listingId: 'arawak-cay-fish-fry',
          destination: 'Bahamas',
        ),
        SavedExperience(
          id: 'save-music',
          listingId: 'sandy-toes-beach-bar',
          destination: 'Bahamas',
        ),
        SavedExperience(
          id: 'save-tour',
          listingId: 'sunset-cruise',
          destination: 'Bahamas',
        ),
      ],
      listings: listings,
      destinations: destinations,
    );

    expect(groups, hasLength(1));
    expect(groups.single.name, 'Bahamas');
    final nassau = groups.single.areas.singleWhere((area) => area.name == 'Nassau');
    expect(nassau.categories.map((category) => category.name), ['Clubs & Nightlife', 'Food']);
    final paradiseIsland = groups.single.areas.singleWhere(
      (area) => area.name == 'Paradise Island',
    );
    expect(paradiseIsland.categories.single.name, 'Tours');
    expect(groups.single.count, 3);

    final japan = SavedGroupBuilder.build(
      saved: const [
        SavedExperience(
          id: 'save-shibuya',
          listingId: 'tokyo-conveyor-sushi',
          destination: 'Japan',
        ),
        SavedExperience(
          id: 'save-shinjuku',
          listingId: 'tokyo-golden-gai',
          destination: 'Japan',
        ),
      ],
      listings: listings,
      destinations: destinations,
    ).single;
    expect(japan.name, 'Japan');
    expect(japan.areas.map((area) => area.name), ['Shibuya', 'Shinjuku']);

    listings.dispose();
    destinations.dispose();
  });

  test('area groups carry a cover image for the saved area card', () {
    final listings = ListingRepository();
    final destinations = DestinationRepository();
    final groups = SavedGroupBuilder.build(
      saved: const [
        SavedExperience(
          id: 'save-tour',
          listingId: 'sunset-cruise',
          destination: 'Bahamas',
        ),
      ],
      listings: listings,
      destinations: destinations,
    );

    expect(groups.single.areas.single.imageUrl, isNotEmpty);

    listings.dispose();
    destinations.dispose();
  });
}
