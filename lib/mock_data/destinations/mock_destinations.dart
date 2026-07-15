import '../../models/destination.dart';
import '../../models/home_section.dart';

const mockDestinations = [
  Destination(
    id: "bahamas",
    name: "Nassau",
    country: "Bahamas",
    flagEmoji: "🇧🇸",
    atmosphereMessage: "Perfect beach weather today ☀",
    heroImageUrl:
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
    areaIds: ["nassau", "paradise-island", "exuma", "harbour-island"],
    homeSections: [
      HomeSection(title: "🏖 Beaches", category: "Beach"),
      HomeSection(title: "🍹 Beach Bars", category: "Bar"),
      HomeSection(title: "🚤 Boat Tours", category: "Tour"),
      HomeSection(title: "🎵 Live Music", category: "Live Music"),
      HomeSection(title: "🍽 Local Dining", category: "Dining"),
    ],
  ),

  Destination(
    id: "tokyo",
    name: "Tokyo",
    country: "Japan",
    flagEmoji: "🇯🇵",
    atmosphereMessage: "Neon nights and hidden neighbourhoods await ✨",
    heroImageUrl:
        "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf",
    areaIds: ["shibuya", "shinjuku", "asakusa"],
    homeSections: [
      HomeSection(title: "🍣 Sushi Worth Trying", category: "Sushi"),
      HomeSection(title: "🍜 Ramen Stops", category: "Ramen"),
      HomeSection(title: "🌸 Nature & Gardens", category: "Nature"),
      HomeSection(
        title: "🎮 Arcades & Entertainment",
        category: "Entertainment",
      ),
      HomeSection(title: "🌃 Tokyo After Dark", category: "Nightlife"),
    ],
  ),

  Destination(
    id: "rome",
    name: "Rome",
    country: "Italy",
    flagEmoji: "🇮🇹",
    atmosphereMessage: "A beautiful evening for wandering historic streets 🌅",
    heroImageUrl: "https://images.unsplash.com/photo-1552832230-c0197dd311b5",
    areaIds: ["historic-centre", "trastevere", "vatican"],
    homeSections: [
      HomeSection(title: "🏛 Must See First", category: "Landmark"),
      HomeSection(title: "🍝 Eat Like a Local", category: "Dining"),
      HomeSection(title: "🍷 Wine Bars", category: "Bar"),
      HomeSection(title: "🚶 Walking Tours", category: "Tour"),
      HomeSection(title: "🌅 Sunset Spots", category: "Sunset"),
    ],
  ),
];
