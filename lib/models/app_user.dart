class AppUser {
  final String id;
  final String name;
  final String homeLocation;
  final String userType;
  final List<String> savedListIds;
  final List<String> tripIds;

  const AppUser({
    required this.id,
    required this.name,
    required this.homeLocation,
    required this.userType,
    this.savedListIds = const [],
    this.tripIds = const [],
  });
}
