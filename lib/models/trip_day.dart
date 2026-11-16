import 'trip_experience.dart';

class TripDay {
  final String title;

  final DateTime? date;

  final List<TripExperience> experiences;

  const TripDay({required this.title, this.date, this.experiences = const []});

  double get totalEstimatedCost => experiences.fold<double>(
    0,
    (total, experience) => total + (experience.estimatedCost ?? 0),
  );

  Map<String, Object?> toJson() => {
    'title': title,
    'date': date == null
        ? null
        : '${date!.year.toString().padLeft(4, '0')}-'
          '${date!.month.toString().padLeft(2, '0')}-'
          '${date!.day.toString().padLeft(2, '0')}',
    'experiences': experiences
        .map((experience) => experience.toJson())
        .toList(growable: false),
  };

  factory TripDay.fromJson(Map<String, Object?> json) => TripDay(
    title: json['title'] as String? ?? 'Day',
    date: json['date'] == null
        ? null
        : _parseDayDate(json['date']! as String),
    experiences: (json['experiences'] as List<Object?>? ?? const [])
        .map((item) => TripExperience.fromJson(Map<String, Object?>.from(item! as Map)))
        .toList(growable: false),
  );
}

DateTime _parseDayDate(String value) {
  final date = DateTime.parse(value);
  return DateTime(date.year, date.month, date.day);
}
