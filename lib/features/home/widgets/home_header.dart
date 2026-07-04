import 'package:flutter/material.dart';

import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Good Morning 👋",
            style: TextStyle(fontSize: 14, color: DEColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            "Where do you want to explore?",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: DEColors.textPrimary,
            ),
          ),
          const SizedBox(height: DESpacing.md),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.public,
                  title: "Destination",
                  value: "Bahamas • Nassau",
                ),
              ),
              const SizedBox(width: DESpacing.sm),
              const _WeatherPill(),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoPill({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.sm),
      decoration: BoxDecoration(
        color: DEColors.background,
        borderRadius: BorderRadius.circular(DERadius.large),
      ),
      child: Row(
        children: [
          Icon(icon, color: DEColors.primary),
          const SizedBox(width: DESpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: DEColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: DEColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherPill extends StatelessWidget {
  const _WeatherPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.sm),
      decoration: BoxDecoration(
        color: DEColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DERadius.large),
      ),
      child: const Column(
        children: [
          Text("☀️", style: TextStyle(fontSize: 20)),
          SizedBox(height: 2),
          Text("28°", style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
