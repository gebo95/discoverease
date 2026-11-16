import 'package:discoverease/models/trip_day.dart';
import 'package:discoverease/models/trip_experience.dart';

class DayBuilder {
  String _title = 'Day 1';
  DateTime? _date;
  final List<TripExperience> _experiences = [];

  DayBuilder title(String title) {
    _title = title;
    return this;
  }

  DayBuilder date(DateTime date) {
    _date = date;
    return this;
  }

  DayBuilder withExperience(TripExperience experience) {
    _experiences.add(experience);
    return this;
  }

  DayBuilder withExperiences(List<TripExperience> experiences) {
    _experiences.addAll(experiences);
    return this;
  }

  TripDay build() {
    return TripDay(
      title: _title,
      date: _date,
      experiences: List.unmodifiable(_experiences),
    );
  }
}
