import 'package:flutter/material.dart';

import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';

class HomeDestinationHeader extends StatelessWidget {
  final String destination;
  final String country;
  final String message;
  final VoidCallback? onDestinationTap;
  final VoidCallback? onPulseTap;
  final int unreadPulseCount;
  final String flagEmoji;

  const HomeDestinationHeader({
    super.key,
    required this.flagEmoji,
    required this.destination,
    required this.country,
    required this.message,
    this.unreadPulseCount = 0,
    this.onDestinationTap,
    this.onPulseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DESpacing.lg,
        DESpacing.md,
        DESpacing.lg,
        DESpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DERadius.large),
                    onTap: onDestinationTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DESpacing.sm,
                        vertical: DESpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(flagEmoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: DESpacing.sm),
                          Flexible(
                            child: Text(
                              "$destination, $country",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: DEColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: DEColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: DESpacing.sm),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: DEColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DESpacing.md),
          Material(
            color: DEColors.surface,
            borderRadius: BorderRadius.circular(DERadius.pill),
            child: InkWell(
              onTap: onPulseTap,
              borderRadius: BorderRadius.circular(DERadius.pill),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: DEColors.textPrimary,
                    ),
                    if (unreadPulseCount > 0)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadPulseCount > 9 ? "9+" : "$unreadPulseCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
