import 'package:flutter/material.dart';
import '../../../models/trip.dart';
// import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DETripHero extends StatelessWidget {
  final Trip trip;
  final String imageUrl;
  final int savedPlaces;

  const DETripHero({
    super.key,
    required this.trip,
    required this.imageUrl,
    this.savedPlaces = 0,
  });

  String _formatDateRange(DateTime startDate, DateTime endDate) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final start = '${months[startDate.month - 1]} ${startDate.day}';
    final end = '${months[endDate.month - 1]} ${endDate.day}';

    return '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      // The dashboard already provides page padding; avoid a second inset.
      margin: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7A8FA8), Color(0xFF243B53)],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.travel_explore_rounded, size: 56, color: Colors.white70),
                ),
              ),
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .15),
                      Colors.black.withValues(alpha: .82),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(DESpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  Text(
                    trip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 4),

                  if (trip.startDate != null && trip.endDate != null)
                    Text(
                      _formatDateRange(trip.startDate!, trip.endDate!),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 16,
                      ),
                    ),

                  const SizedBox(height: DESpacing.md),

                  Row(
                    children: [
                      Expanded(
                        child: _TripStat(
                          icon: Icons.place_rounded,
                          value: trip.plannedExperiences.toString(),
                          label: "Places",
                        ),
                      ),

                      const SizedBox(width: DESpacing.sm),

                      Expanded(
                        child: _TripStat(
                          icon: Icons.favorite_rounded,
                          value: savedPlaces.toString(),
                          label: "Saved",
                        ),
                      ),

                      const SizedBox(width: DESpacing.sm),

                      Expanded(
                        child: _TripStat(
                          icon: Icons.calendar_month_rounded,
                          value: trip.totalDays.toString(),
                          label: "Days",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: DESpacing.sm),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(DERadius.large),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.insight,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _TripStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(DERadius.large),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: .8)),
          ),
        ],
      ),
    );
  }
}
