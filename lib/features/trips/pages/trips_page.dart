import 'package:flutter/material.dart';

import '../../../repositories/trip_repository.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';
import 'trip_dashboard_page.dart';
import 'package:provider/provider.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tripRepository = context.read<TripRepository>();

    final currentTrip = tripRepository.getCurrentTrip();
    final upcomingTrips = tripRepository.getUpcomingTrips();
    final memories = tripRepository.getMemories();

    return Scaffold(
      backgroundColor: DEColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DESpacing.md),
          children: [
            const SizedBox(height: 12),
            const Text(
              "Trips",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: DEColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Plan, experience, and remember your adventures.",
              style: TextStyle(fontSize: 15, color: DEColors.textSecondary),
            ),
            const SizedBox(height: 24),

            const Text(
              "🌴 Current Trip",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _TripCard(
              title: currentTrip.title,
              subtitle: "Day 1 • ${currentTrip.destination}",
              detail: "Today: Food, sunset cruise, live music",
              isPrimary: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripDashboardPage(trip: currentTrip),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text(
              "✈️ Upcoming Trips",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _TripCard(
              title: upcomingTrips.first.title,
              subtitle: upcomingTrips.first.destination,
              detail:
                  "Estimated budget \$${upcomingTrips.first.estimatedBudget.toStringAsFixed(0)}",
            ),

            const SizedBox(height: 24),
            const Text(
              "📸 Memories",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            ...memories.map(
              (trip) => _TripCard(
                title: trip.title,
                subtitle: trip.destination,
                detail: "Past adventure",
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _TripCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.extraLarge),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DESpacing.md),
        padding: const EdgeInsets.all(DESpacing.md),
        decoration: BoxDecoration(
          color: isPrimary ? DEColors.primary : DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isPrimary
                  ? Colors.white.withValues(alpha: 0.18)
                  : DEColors.background,
              child: Text(
                isPrimary ? "🌴" : "✈️",
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: DESpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isPrimary ? Colors.white : DEColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.85)
                          : DEColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.75)
                          : DEColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isPrimary ? Colors.white : DEColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
