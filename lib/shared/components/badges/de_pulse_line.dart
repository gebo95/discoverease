import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../repositories/business_pulse_repository.dart';
import '../../theme/de_colors.dart';
import 'de_pulse_badge.dart';

/// The Pulse line at the bottom of a list card: the business's live Pulse (a
/// flashing tag plus its message, or how long it lasts), or else the listing's
/// older built-in update text, or nothing.
class DEPulseLine extends StatelessWidget {
  const DEPulseLine({super.key, required this.listingId, this.fallbackText});

  final String listingId;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final pulses = context.watch<BusinessPulseRepository?>();
    final pulse = pulses?.forListing(listingId);
    if (pulse != null) {
      return Row(
        children: [
          DEPulseBadge(label: pulse.tag, animate: !(pulses?.isSeen(pulse) ?? true)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pulse.message.isNotEmpty
                  ? pulse.message
                  : pulse.untilLabel(DateTime.now()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DEColors.accent,
              ),
            ),
          ),
        ],
      );
    }
    final text = fallbackText;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Text(
      '🔴 $text',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DEColors.accent,
      ),
    );
  }
}
