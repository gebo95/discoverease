import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/trip.dart';
import '../../../repositories/trip_repository.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';
import 'trip_editor_page.dart';
import 'trip_dashboard_page.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tripRepository = context.watch<TripRepository>();
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
            FilledButton.icon(
              onPressed: () => _createTrip(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a trip'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 24),

            if (tripRepository.hasCurrentTrip) ...[
              const Text(
                "🌴 Current Trip",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _TripCard(
                title: currentTrip.title,
                subtitle: _tripSubtitle(context, currentTrip),
                detail:
                    '${currentTrip.days.length} days · '
                    '${currentTrip.plannedExperiences} planned experiences',
                isPrimary: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDashboardPage(trip: currentTrip),
                    ),
                  );
                },
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TripEditorPage(trip: currentTrip),
                  ),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(bottom: DESpacing.md),
                child: Text(
                  'Create a trip to start planning. Your account has no saved trips yet.',
                  style: TextStyle(color: DEColors.textSecondary),
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              "✈️ Upcoming Trips",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if (upcomingTrips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: DESpacing.md),
                child: Text(
                  'Trips you create will appear here.',
                  style: TextStyle(color: DEColors.textSecondary),
                ),
              )
            else
              ...upcomingTrips.map(
                (trip) => _TripCard(
                  title: trip.title,
                  subtitle: _tripSubtitle(context, trip),
                  detail: trip.plannedExperiences == 0
                      ? 'No experiences planned yet'
                      : '${trip.plannedExperiences} planned experiences',
                  onTap: () {
                    tripRepository.activateTrip(trip.id);
                    final activeTrip = tripRepository.getCurrentTrip();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDashboardPage(trip: activeTrip),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),
            const Text(
              "📸 Memories",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            if (memories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: DESpacing.md),
                child: Text(
                  'Completed trips will appear here when trip history is available.',
                  style: TextStyle(color: DEColors.textSecondary),
                ),
              )
            else
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

  String _tripSubtitle(BuildContext context, Trip trip) {
    if (trip.startDate != null && trip.endDate != null) {
      final localizations = MaterialLocalizations.of(context);
      return '${localizations.formatMediumDate(trip.startDate!)} – '
          '${localizations.formatMediumDate(trip.endDate!)} · '
          '${trip.destination}';
    }
    return '${trip.days.length} days · ${trip.destination}';
  }

  Future<void> _createTrip(BuildContext context) async {
    final createdTrip = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(builder: (_) => const TripEditorPage()),
    );
    if (!context.mounted || createdTrip == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TripDashboardPage(trip: createdTrip)),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const _TripCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    this.isPrimary = false,
    this.onTap,
    this.onEdit,
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
            if (onEdit != null)
              IconButton(
                tooltip: 'Edit trip',
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  color: isPrimary ? Colors.white : DEColors.textSecondary,
                ),
              )
            else
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
