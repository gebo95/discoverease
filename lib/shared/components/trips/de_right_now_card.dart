import 'package:flutter/material.dart';

import '../../../features/trips/models/right_now_state.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_spacing.dart';

class DERightNowCard extends StatelessWidget {
  final RightNowState state;
  final VoidCallback? onAction;

  const DERightNowCard({super.key, required this.state, this.onAction});

  @override
  Widget build(BuildContext context) {
    final appearance = _appearanceFor(state.type);
    final canPerformAction = state.hasAction && onAction != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: appearance.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: appearance.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(appearance.icon, color: appearance.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: appearance.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Tooltip(
                message: 'Suggestions use your trip plan and saved reservation details.',
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 19,
                  color: DEColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: DESpacing.md),
          Text(
            state.title,
            style: const TextStyle(
              color: DEColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: const TextStyle(
              color: DEColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          if (state.hasAction) ...[
            const SizedBox(height: DESpacing.md),
            const Divider(height: 1),
            const SizedBox(height: DESpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: canPerformAction ? onAction : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(state.actionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: appearance.accent,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static _RightNowAppearance _appearanceFor(RightNowType type) {
    return switch (type) {
      RightNowType.departureSoon => const _RightNowAppearance(
        icon: Icons.directions_walk_rounded,
        accent: DEColors.primary,
      ),
      RightNowType.experienceStarting => const _RightNowAppearance(
        icon: Icons.schedule_rounded,
        accent: DEColors.primary,
      ),
      RightNowType.arrivingSoon => const _RightNowAppearance(
        icon: Icons.location_on_rounded,
        accent: DEColors.primary,
      ),
      RightNowType.nextExperience => const _RightNowAppearance(
        icon: Icons.near_me_rounded,
        accent: DEColors.primary,
      ),
      RightNowType.freeTime => const _RightNowAppearance(
        icon: Icons.explore_outlined,
        accent: DEColors.primary,
      ),
      RightNowType.reservationSoon => const _RightNowAppearance(
        icon: Icons.event_available_rounded,
        accent: DEColors.primary,
      ),
      RightNowType.closingSoon => const _RightNowAppearance(
        icon: Icons.schedule_rounded,
        accent: DEColors.primary,
      ),
      RightNowType.nearbySavedPlace => const _RightNowAppearance(
        icon: Icons.bookmark_outline_rounded,
        accent: DEColors.primary,
      ),
      RightNowType.weatherAlert => const _RightNowAppearance(
        icon: Icons.cloud_outlined,
        accent: DEColors.primary,
      ),
      RightNowType.nearbyEvent => const _RightNowAppearance(
        icon: Icons.celebration_outlined,
        accent: DEColors.primary,
      ),
      RightNowType.travelDay => const _RightNowAppearance(
        icon: Icons.flight_takeoff_rounded,
        accent: DEColors.primary,
      ),
      RightNowType.nothingPlanned => const _RightNowAppearance(
        icon: Icons.wb_sunny_outlined,
        accent: DEColors.primary,
      ),
    };
  }
}

class _RightNowAppearance {
  final IconData icon;
  final Color accent;

  const _RightNowAppearance({required this.icon, required this.accent});
}
