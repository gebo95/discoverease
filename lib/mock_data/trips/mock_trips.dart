import '../../models/trip.dart';

const currentTrip = Trip(
  id: "bahamas-adventure",
  title: "Bahamas Adventure",
  destination: "Bahamas",
  estimatedBudget: 3200,
  days: [
    TripDay(
      title: "Day 1",
      morningListingIds: ["arawak-cay-fish-fry"],
      afternoonListingIds: ["sunset-cruise"],
      eveningListingIds: ["sandy-toes-beach-bar"],
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
