import 'trip_day.dart';

class Trip {
  static const int schemaVersion = 1;
  final String id;
  final String title;
  final String destination;
  final String? destinationId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<TripDay> days;
  final double estimatedBudget;
  final String? notes;

  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    this.destinationId,
    this.startDate,
    this.endDate,
    this.days = const [],
    this.estimatedBudget = 0,
    this.notes,
  });

  /// Stable document shape for account-owned trip records.
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'title': title,
    'destination': destination,
    'destinationId': destinationId,
    'startDate': _formatDateOnly(startDate),
    'endDate': _formatDateOnly(endDate),
    'days': days.map((day) => day.toJson()).toList(growable: false),
    'estimatedBudget': estimatedBudget,
    'notes': notes,
  };

  factory Trip.fromJson(Map<String, Object?> json) {
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (version != schemaVersion) {
      throw FormatException('Unsupported Trip schema version: $version');
    }
    return Trip(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      destination: _requiredString(json, 'destination'),
      destinationId: json['destinationId'] as String?,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      days: (json['days'] as List<Object?>? ?? const [])
          .map((item) => TripDay.fromJson(Map<String, Object?>.from(item! as Map)))
          .toList(growable: false),
      estimatedBudget: (json['estimatedBudget'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  int get totalDays {
    if (startDate != null && endDate != null) {
      final difference = endDate!.difference(startDate!).inDays;
      return difference >= 0 ? difference + 1 : 0;
    }

    return days.length;
  }

  int get plannedExperiences {
    return days.fold<int>(0, (total, day) => total + day.experiences.length);
  }

  /// Sum of experience estimates that the traveler has entered.
  double get totalEstimatedCost => days.fold<double>(
    0,
    (total, day) => total + day.totalEstimatedCost,
  );

  String get insight {
    if (plannedExperiences == 0) {
      return 'A blank canvas ready for adventure';
    }

    if (totalDays == 0) {
      return 'Your journey is starting to take shape';
    }

    final experiencesPerDay = plannedExperiences / totalDays;

    if (experiencesPerDay < 1) {
      return 'Plenty of free time to explore';
    }

    if (experiencesPerDay <= 2.5) {
      return 'A balanced mix of plans and free time';
    }

    return 'Packed with unforgettable experiences';
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Trip.$key must be a non-empty string.');
  }
  return value;
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Trip dates must be ISO date strings.');
  final parsed = DateTime.parse(value);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String? _formatDateOnly(DateTime? value) => value == null
    ? null
    : '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
