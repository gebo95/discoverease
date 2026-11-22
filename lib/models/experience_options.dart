/// The choices owners pick from when describing an experience. Keeping them
/// as fixed lists keeps travelers' filters and search consistent.
library;

/// Most tags an owner can pick for "Perfect for" and "What makes it special".
const int maxTagChoices = 5;

/// Longest "Why you'll love it" text.
const int whyYoullLoveItMax = 600;

const List<String> priceLevels = [r'$', r'$$', r'$$$', r'$$$$'];

const Map<String, String> priceCaptions = {
  r'$': 'Budget friendly',
  r'$$': 'Moderate',
  r'$$$': 'Pricey',
  r'$$$$': 'Splurge',
};

const List<String> perfectForOptions = [
  'Couples',
  'Friends',
  'Families',
  'Solo Travelers',
  'Groups',
  'Date Night',
  'Honeymooners',
  'Foodies',
  'Nightlife',
  'Adventure Seekers',
  'Photography',
  'Sunset Lovers',
  'Relaxing',
  'Culture Lovers',
  'Budget Travelers',
  'Special Occasions',
];

/// One optional highlight an owner can put on their card.
const List<String> highlightOptions = [
  'Local Favorite',
  'Hidden Gem',
  'Best Seller',
  'Great Value',
  'Limited Time',
  'Family Favorite',
  'Date Night Pick',
  'Must Try',
];

const List<String> featureOptions = [
  'Ocean View',
  'Local Favorite',
  'Hidden Gem',
  'Photo Friendly',
  'Historic',
  'Guided Experience',
  'Outdoor Seating',
  'Family Friendly',
  'Romantic',
  'Quick Stop',
  'Open Late',
  'Scenic View',
  'Live Music',
  'Free Entry',
  'Pet Friendly',
  'Reservations Recommended',
  'Wheelchair Accessible',
  'Locally Owned',
];

const Map<String, List<String>> subcategoryOptions = {
  'Activities': [
    'Water Sports', 'Snorkeling & Diving', 'Beach', 'Hiking', 'Spa & Wellness',
    'Golf', 'Fishing', 'Nature', 'Family Fun', 'Adventure',
  ],
  'Dining': [
    'Seafood', 'Sushi', 'Italian', 'Caribbean', 'Café', 'Bakery', 'Bar & Lounge',
    'Fine Dining', 'Casual Dining', 'Street Food', 'Brunch',
  ],
  'Tours': [
    'Boat Tour', 'Island Tour', 'Food Tour', 'Historic Tour', 'Nature Tour',
    'Sunset Cruise', 'Walking Tour', 'Private Tour',
  ],
  'Entertainment': [
    'Live Music', 'Nightlife', 'Nightclub', 'Party', 'Casino', 'Show', 'Festival',
    'Movies', 'Games',
  ],
  'Shopping': [
    'Local Crafts', 'Souvenirs', 'Fashion', 'Markets', 'Jewelry', 'Art',
  ],
  'Other': ['Services', 'Transport', 'Wellness', 'Events'],
};

/// Most types an owner can pick for one experience.
const int maxSubcategories = 3;

/// Every type an owner can pick. The ones for [category] come first, then the
/// rest, so a bar can also be tagged as a party or beach spot and then shows
/// up under each of them. Types already saved on the experience stay
/// selectable even if they are not in any list.
List<String> subcategoryChoices(
  String category, {
  List<String> current = const [],
}) {
  final ordered = <String>[
    ...?subcategoryOptions[category],
    for (final entry in subcategoryOptions.entries)
      if (entry.key != category) ...entry.value,
  ];
  final seen = <String>{};
  return [
    ...current.where((value) => !ordered.contains(value)),
    ...ordered,
  ].where(seen.add).toList();
}

/// Subcategories are stored as one text value, "Bar, Beach, Party", so search
/// and the category filters match on any of them.
List<String> splitSubcategories(String stored) => stored
    .split(',')
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toList();

String joinSubcategories(List<String> chosen) => chosen.join(', ');
