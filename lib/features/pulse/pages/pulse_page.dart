import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/pulse_item.dart';
import '../../../repositories/pulse_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';
import '../../trips/pages/trip_dashboard_page.dart';

class PulsePage extends StatelessWidget {
  const PulsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pulseRepository = context.watch<PulseRepository>();
    final pulses = pulseRepository.getAll();
    final trip = context.watch<TripRepository>().getCurrentTrip();

    return Scaffold(
      backgroundColor: DEColors.background,
      appBar: AppBar(
        title: const Text(
          "Pulse",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: DEColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: pulseRepository.unreadCount() == 0
                ? null
                : pulseRepository.markAllAsRead,
            child: const Text("Mark all read"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DESpacing.lg),
        children: [
          const Text(
            "Your trip, right on time",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            "Reminders based on the dates, times, reservations, and travel estimates in your itinerary.",
            style: TextStyle(color: DEColors.textSecondary),
          ),
          const SizedBox(height: DESpacing.xl),
          if (pulses.isEmpty)
            _EmptyPulseState(
              onOpenTrip: trip.days.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TripDashboardPage(trip: trip),
                        ),
                      ),
            )
          else
            ...pulses.map(
              (pulse) => _PulseCard(
                pulse: pulse,
                onTap: () {
                  pulseRepository.markAsRead(pulse.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TripDashboardPage(
                        trip: trip,
                        initialDayIndex: pulse.dayIndex ?? 0,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  final PulseItem pulse;
  final VoidCallback? onTap;

  const _PulseCard({required this.pulse, this.onTap});

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(pulse.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DERadius.extraLarge),
      child: Container(
        margin: const EdgeInsets.only(bottom: DESpacing.md),
        padding: const EdgeInsets.all(DESpacing.md),
        decoration: BoxDecoration(
          color: DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          border: Border.all(
            color: pulse.isRead
                ? DEColors.border
                : presentation.color.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: presentation.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(DERadius.large),
              ),
              alignment: Alignment.center,
              child: Text(
                presentation.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: DESpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pulse.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!pulse.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pulse.message,
                    style: const TextStyle(
                      color: DEColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pulse.timeLabel,
                    style: TextStyle(
                      color: presentation.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DESpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: DEColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  _PulsePresentation _presentationFor(PulseType type) {
    switch (type) {
      case PulseType.liveNow:
        return const _PulsePresentation("🔴", Colors.red);

      case PulseType.reservation:
        return const _PulsePresentation("🎟️", Colors.deepPurple);

      case PulseType.departure:
        return const _PulsePresentation("🚶", Colors.orange);

      case PulseType.startingSoon:
        return const _PulsePresentation("⏰", Colors.orange);

      case PulseType.endingSoon:
        return const _PulsePresentation("⌛", Colors.deepOrange);

      case PulseType.trending:
        return const _PulsePresentation("🔥", DEColors.primary);
    }
  }
}

class _EmptyPulseState extends StatelessWidget {
  final VoidCallback? onOpenTrip;

  const _EmptyPulseState({required this.onOpenTrip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.lg),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
        border: Border.all(color: DEColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 30),
          const SizedBox(height: DESpacing.md),
          const Text(
            'No trip reminders right now',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add a trip date and a time to an experience. Reservation and leave-time reminders use the details you save.',
            style: TextStyle(color: DEColors.textSecondary, height: 1.4),
          ),
          if (onOpenTrip != null) ...[
            const SizedBox(height: DESpacing.md),
            OutlinedButton.icon(
              onPressed: onOpenTrip,
              icon: const Icon(Icons.luggage_outlined),
              label: const Text('Open current trip'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsePresentation {
  final String emoji;
  final Color color;

  const _PulsePresentation(this.emoji, this.color);
}
