class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<TripDay> days;
  final double estimatedBudget;

  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    this.startDate,
    this.endDate,
    this.days = const [],
    this.estimatedBudget = 0,
  });
}

class TripDay {
  final String title;
  final List<String> morningListingIds;
  final List<String> afternoonListingIds;
  final List<String> eveningListingIds;

  const TripDay({
    required this.title,
    this.morningListingIds = const [],
    this.afternoonListingIds = const [],
    this.eveningListingIds = const [],
  });
}
