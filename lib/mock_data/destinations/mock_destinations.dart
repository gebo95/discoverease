import '../../models/destination.dart';
import '../../models/home_section.dart';

/// Local catalog entries used until the destination repository is backed by
/// the production content store.
const mockDestinations = [
  Destination(
    id: 'nassau',
    name: 'Nassau',
    country: 'Bahamas',
    countryCode: 'BS',
    region: 'New Providence',
    timezoneId: 'America/Nassau',
    flagEmoji: '🇧🇸',
    tagline: 'Island flavors, Bahamian culture, and time by the water.',
    heroImageUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e',
    areaIds: [
      'nassau',
      'downtown-nassau',
      'paradise-island',
      'cable-beach',
      'west-nassau',
    ],
    homeSections: [
      HomeSection(title: '🏖 Beaches', category: 'Beach'),
      HomeSection(title: '🍹 Beach Bars', category: 'Bar'),
      HomeSection(title: '🚤 Boat Tours', category: 'Tour'),
      HomeSection(title: '🎵 Live Music', category: 'Live Music'),
      HomeSection(title: '🍽 Local Dining', category: 'Dining'),
    ],
  ),
  Destination(
    id: 'tokyo',
    name: 'Tokyo',
    country: 'Japan',
    countryCode: 'JP',
    region: 'Kanto',
    timezoneId: 'Asia/Tokyo',
    flagEmoji: '🇯🇵',
    tagline: 'Neighbourhood food, late-night streets, and quiet gardens.',
    heroImageUrl:
        'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf',
    areaIds: [
      'shibuya',
      'shinjuku',
      'asakusa',
      'tsukiji',
      'ueno',
      'akihabara',
    ],
    homeSections: [
      HomeSection(title: '🍣 Sushi Worth Trying', category: 'Sushi'),
      HomeSection(title: '🍜 Ramen Stops', category: 'Ramen'),
      HomeSection(title: '🌸 Nature & Gardens', category: 'Nature'),
      HomeSection(
        title: '🎮 Arcades & Entertainment',
        category: 'Entertainment',
      ),
      HomeSection(title: '🌃 Tokyo After Dark', category: 'Nightlife'),
    ],
  ),
  Destination(
    id: 'rome',
    name: 'Rome',
    country: 'Italy',
    countryCode: 'IT',
    region: 'Lazio',
    timezoneId: 'Europe/Rome',
    flagEmoji: '🇮🇹',
    tagline: 'Ancient landmarks, neighbourhood dining, and evening walks.',
    heroImageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5',
    areaIds: ['historic-centre', 'trastevere', 'vatican', 'aventine-hill'],
    homeSections: [
      HomeSection(title: '🏛 Must See First', category: 'Landmark'),
      HomeSection(title: '🍝 Eat Like a Local', category: 'Dining'),
      HomeSection(title: '🍷 Wine Bars', category: 'Bar'),
      HomeSection(title: '🚶 Walking Tours', category: 'Tour'),
      HomeSection(title: '🌅 Sunset Spots', category: 'Sunset'),
    ],
  ),
];
