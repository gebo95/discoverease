import '../mock_data/pulses/mock_pulses.dart';
import '../models/pulse_item.dart';
import 'package:flutter/foundation.dart';

class PulseRepository extends ChangeNotifier {
  final List<PulseItem> _pulses = List.from(mockPulses);

  List<PulseItem> getAll() {
    return List.unmodifiable(_pulses);
  }

  List<PulseItem> getUnread() {
    return _pulses.where((p) => !p.isRead).toList();
  }

  int unreadCount() {
    return _pulses.where((p) => !p.isRead).length;
  }

  void markAsRead(String id) {
    final index = _pulses.indexWhere((pulse) => pulse.id == id);

    if (index == -1 || _pulses[index].isRead) {
      return;
    }

    final current = _pulses[index];

    _pulses[index] = PulseItem(
      id: current.id,
      listingId: current.listingId,
      title: current.title,
      message: current.message,
      timeLabel: current.timeLabel,
      type: current.type,
      isRead: true,
    );

    notifyListeners();
  }

  void markAllAsRead() {
    var changed = false;

    for (var index = 0; index < _pulses.length; index++) {
      final current = _pulses[index];

      if (current.isRead) {
        continue;
      }

      _pulses[index] = PulseItem(
        id: current.id,
        listingId: current.listingId,
        title: current.title,
        message: current.message,
        timeLabel: current.timeLabel,
        type: current.type,
        isRead: true,
      );

      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }
}
