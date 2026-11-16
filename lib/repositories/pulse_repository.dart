import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/pulse/trip_pulse_engine.dart';
import '../models/pulse_item.dart';
import 'listing_repository.dart';
import 'trip_repository.dart';

/// In-app itinerary reminders. Platform push notifications are not configured.
class PulseRepository extends ChangeNotifier {
  final TripRepository _tripRepository;
  final ListingRepository _listingRepository;
  final Set<String> _readPulseIds = {};
  late final Map<String, String> _listingTitles;
  late final Timer _refreshTimer;

  PulseRepository({
    required this._tripRepository,
    required this._listingRepository,
  }) {
    _listingTitles = {
      for (final listing in _listingRepository.getAll())
        listing.id: listing.title,
    };
    _tripRepository.addListener(_onTripChanged);
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  List<PulseItem> getAll({DateTime? now}) {
    return _buildPulses(now: now);
  }

  List<PulseItem> getUnread({DateTime? now}) {
    return _buildPulses(now: now).where((pulse) => !pulse.isRead).toList();
  }

  int unreadCount({DateTime? now}) => getUnread(now: now).length;

  void markAsRead(String id) {
    final exists = _buildPulses().any((pulse) => pulse.id == id);
    if (!exists || !_readPulseIds.add(id)) return;
    notifyListeners();
  }

  void markAllAsRead() {
    final unread = getUnread();
    if (unread.isEmpty) return;
    _readPulseIds.addAll(unread.map((pulse) => pulse.id));
    notifyListeners();
  }

  List<PulseItem> _buildPulses({DateTime? now}) {
    final trip = _tripRepository.getCurrentTrip();
    return TripPulseEngine.build(
      trip: trip,
      now: now ?? DateTime.now(),
      listingTitles: _listingTitles,
    ).map((pulse) {
      if (!_readPulseIds.contains(pulse.id)) return pulse;
      return PulseItem(
        id: pulse.id,
        listingId: pulse.listingId,
        title: pulse.title,
        message: pulse.message,
        timeLabel: pulse.timeLabel,
        type: pulse.type,
        isRead: true,
        scheduledAt: pulse.scheduledAt,
        experienceId: pulse.experienceId,
        dayIndex: pulse.dayIndex,
        tripDayTitle: pulse.tripDayTitle,
      );
    }).toList(growable: false);
  }

  void _onTripChanged() => notifyListeners();

  @override
  void dispose() {
    _tripRepository.removeListener(_onTripChanged);
    _refreshTimer.cancel();
    super.dispose();
  }
}
