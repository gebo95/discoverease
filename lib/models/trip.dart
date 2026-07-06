import 'trip_day.dart';

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
