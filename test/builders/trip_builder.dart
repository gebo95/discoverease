import 'package:discoverease/models/trip.dart';
import 'package:discoverease/models/trip_day.dart';
import 'package:discoverease/models/trip_experience.dart';
import 'package:discoverease/models/trip_section.dart';

import 'day_builder.dart';

class TripBuilder {
  String _id = 'trip-1';
  String _title = 'Test Trip';
  String _destination = 'Test Destination';
  DateTime? _startDate;
  DateTime? _endDate;
  double _estimatedBudget = 0;

  final List<TripDay> _days = [];

  TripBuilder id(String id) {
    _id = id;
    return this;
  }

  TripBuilder title(String title) {
    _title = title;
    return this;
  }

  TripBuilder withMorningExperience(TripExperience experience) {
    return withExperience(experience.copyWith(section: TripSection.morning));
  }

  TripBuilder withAfternoonExperience(TripExperience experience) {
    return withExperience(experience.copyWith(section: TripSection.afternoon));
  }

  TripBuilder withEveningExperience(TripExperience experience) {
    return withExperience(experience.copyWith(section: TripSection.evening));
  }

  TripBuilder destination(String destination) {
    _destination = destination;
    return this;
  }

  TripBuilder startDate(DateTime date) {
    _startDate = date;
    return this;
  }

  TripBuilder endDate(DateTime date) {
    _endDate = date;
    return this;
  }

  TripBuilder budget(double amount) {
    _estimatedBudget = amount;
    return this;
  }

  TripBuilder withDay(TripDay day) {
    _days.add(day);
    return this;
  }

  TripBuilder withDays(List<TripDay> days) {
    _days.addAll(days);
    return this;
  }

  TripBuilder withExperience(TripExperience experience) {
    if (_days.isEmpty) {
      _days.add(DayBuilder().withExperience(experience).build());
    } else {
      final firstDay = _days.first;

      _days[0] = TripDay(
        title: firstDay.title,
        date: firstDay.date,
        experiences: [...firstDay.experiences, experience],
      );
    }

    return this;
  }

  Trip build() {
    return Trip(
      id: _id,
      title: _title,
      destination: _destination,
      startDate: _startDate,
      endDate: _endDate,
      days: List.unmodifiable(_days),
      estimatedBudget: _estimatedBudget,
    );
  }
}
