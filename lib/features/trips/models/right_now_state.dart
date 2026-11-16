enum RightNowType {
  departureSoon,
  experienceStarting,
  nextExperience,
  arrivingSoon,
  freeTime,
  reservationSoon,
  closingSoon,
  nearbySavedPlace,
  weatherAlert,
  nearbyEvent,
  travelDay,
  nothingPlanned,
}

enum CompanionAction { openExperience, viewReservation, browseExperiences }

class RightNowState {
  final RightNowType type;
  final String eyebrow;
  final String title;
  final String message;
  final String? actionLabel;
  final CompanionAction? action;
  final String? experienceId;
  final String? confirmationNumber;
  final String? ticketUrl;
  final String? browseFilter;

  const RightNowState({
    required this.type,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.actionLabel,
    this.action,
    this.experienceId,
    this.confirmationNumber,
    this.ticketUrl,
    this.browseFilter,
  });

  bool get hasAction => actionLabel != null && actionLabel!.trim().isNotEmpty;
}
