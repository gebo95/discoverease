import '../../models/app_user.dart';

const touristUser = AppUser(
  id: "user-alex-carter",
  name: "Alex Carter",
  homeLocation: "London, Ontario",
  userType: "Tourist",
  savedListIds: ["bahamas-unsorted", "bahamas-restaurants", "bahamas-beaches"],
  tripIds: ["bahamas-adventure", "banff-2024", "rome-2025"],
);

const localUser = AppUser(
  id: "user-maya-thompson",
  name: "Maya Thompson",
  homeLocation: "Nassau, Bahamas",
  userType: "Local",
  savedListIds: [
    "nassau-unsorted",
    "nassau-date-night",
    "nassau-live-music",
    "nassau-food-spots",
  ],
  tripIds: [],
);
