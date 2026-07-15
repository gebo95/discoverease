import '../../models/pulse_item.dart';

const mockPulses = [
  PulseItem(
    id: "pulse-sandy-toes-live",
    listingId: "sandy-toes-beach-bar",
    title: "Live reggae starts soon",
    message: "Sandy Toes Beach Bar starts live music in 20 minutes.",
    timeLabel: "20 min",
    type: PulseType.startingSoon,
  ),
  PulseItem(
    id: "pulse-sunset-cruise",
    listingId: "sunset-cruise",
    title: "Boarding begins soon",
    message: "Sunset Cruise begins boarding in 45 minutes.",
    timeLabel: "45 min",
    type: PulseType.startingSoon,
  ),
  PulseItem(
    id: "pulse-fish-fry",
    listingId: "arawak-cay-fish-fry",
    title: "Happy hour ending soon",
    message: "Happy hour at Arawak Cay Fish Fry ends in one hour.",
    timeLabel: "1 hr",
    type: PulseType.endingSoon,
  ),
  PulseItem(
    id: "pulse-trending-tonight",
    listingId: "aura-nightclub",
    title: "Trending tonight",
    message: "Aura Nightclub is getting more saves than usual tonight.",
    timeLabel: "Now",
    type: PulseType.trending,
    isRead: true,
  ),
];
