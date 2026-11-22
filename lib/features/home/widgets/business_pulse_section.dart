import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/business_pulse.dart';
import '../../../repositories/business_pulse_repository.dart';
import '../../../repositories/destination_repository.dart';
import '../../../repositories/listing_repository.dart';
import '../../../shared/components/badges/de_pulse_badge.dart';
import '../../../shared/components/sections/de_section_header.dart';
import '../../../shared/navigation/de_page_route.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../listing/pages/listing_detail_page.dart';

/// "Happening now": the live Pulse posts from businesses in the destination.
/// Shows nothing at all when no business has one up.
class BusinessPulseSection extends StatelessWidget {
  const BusinessPulseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<BusinessPulseRepository?>();
    if (repository == null) return const SizedBox.shrink();
    final destination = context.watch<DestinationRepository>().currentDestination;
    final listings = context.read<ListingRepository>();
    // Only posts whose listing the app can open are shown.
    final pulses = [
      for (final pulse in repository.forDestination(destination.id))
        if (listings.getById(pulse.listingId) != null) pulse,
    ];
    if (pulses.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DESectionHeader(
            title: 'Happening now',
            subtitle: 'Updates from places in ${destination.name}.',
            actionText: '',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pulses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _PulseCard(
                pulse: pulses[index],
                animate: !repository.isSeen(pulses[index]),
                onTap: () {
                  final listing = listings.getById(pulses[index].listingId);
                  if (listing == null) return;
                  Navigator.push(
                    context,
                    dePageRoute(page: ListingDetailPage(listing: listing)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({
    required this.pulse,
    required this.onTap,
    required this.animate,
  });

  final BusinessPulse pulse;
  final bool animate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.large),
      onTap: onTap,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DEColors.border.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(DERadius.large),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: DEPulseBadge(label: pulse.tag, animate: animate),
            ),
            const SizedBox(height: 10),
            Text(
              pulse.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                pulse.message.isNotEmpty ? pulse.message : 'Tap to see the place.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: DEColors.textSecondary),
              ),
            ),
            Text(
              pulse.untilLabel(DateTime.now()),
              style: const TextStyle(
                color: DEColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
