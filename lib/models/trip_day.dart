import 'trip_experience.dart';

class TripDay {
  final String title;

  final DateTime? date;

  final List<TripExperience> experiences;

  const TripDay({required this.title, this.date, this.experiences = const []});
}
