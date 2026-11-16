enum TripReservationType {
  restaurant,
  attraction,
  tour,
  flight,
  train,
  hotel,
  other,
}

class TripReservation {
  final TripReservationType type;
  final String? confirmationNumber;
  final String? ticketUrl;
  final DateTime? reminderTime;

  const TripReservation({
    required this.type,
    this.confirmationNumber,
    this.ticketUrl,
    this.reminderTime,
  });

  Map<String, Object?> toJson() => {
    'type': type.name,
    'confirmationNumber': confirmationNumber,
    'ticketUrl': ticketUrl,
    'reminderTime': reminderTime?.toUtc().toIso8601String(),
  };

  factory TripReservation.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String? ?? TripReservationType.other.name;
    final matchingType = TripReservationType.values
        .where((value) => value.name == typeName);
    if (matchingType.isEmpty) {
      throw FormatException('Unknown reservation type: $typeName');
    }
    return TripReservation(
      type: matchingType.first,
      confirmationNumber: json['confirmationNumber'] as String?,
      ticketUrl: json['ticketUrl'] as String?,
      reminderTime: json['reminderTime'] == null
          ? null
          : DateTime.parse(json['reminderTime']! as String),
    );
  }

  TripReservation copyWith({
    TripReservationType? type,
    String? confirmationNumber,
    String? ticketUrl,
    DateTime? reminderTime,
  }) {
    return TripReservation(
      type: type ?? this.type,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
