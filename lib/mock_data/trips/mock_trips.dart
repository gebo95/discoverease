import '../../models/trip.dart';

import '../../models/trip_day.dart';
import '../../models/trip_experience.dart';
import '../../models/trip_section.dart';

const currentTrip = Trip(
  id: "bahamas-adventure",
  title: "Bahamas Adventure",
  destination: "Bahamas",
  estimatedBudget: 3200,
  days: [
    TripDay(
      title: "Day 1",
      experiences: [
        TripExperience(
          id: "trip-exp-1",
          listingId: "arawak-cay-fish-fry",
          section: TripSection.morning,
        ),
        TripExperience(
          id: "trip-exp-2",
          listingId: "sunset-cruise",
          section: TripSection.afternoon,
        ),
        TripExperience(
          id: "trip-exp-3",
          listingId: "sandy-toes-beach-bar",
          section: TripSection.evening,
        ),
      ],
    ),
  ],
);
const upcomingTrip = Trip(
  id: "tokyo-2027",
  title: "Tokyo Adventure",
  destination: "Japan",
  estimatedBudget: 5200,
);

const memoryTrip1 = Trip(
  id: "rome-2025",
  title: "Rome Memories",
  destination: "Italy",
);

const memoryTrip2 = Trip(
  id: "banff-2024",
  title: "Banff Escape",
  destination: "Canada",
);
