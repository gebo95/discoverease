import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../repositories/destination_repository.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

void showDEDestinationPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const DEDestinationPicker(),
  );
}

class DEDestinationPicker extends StatelessWidget {
  const DEDestinationPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final destinationRepository = context.watch<DestinationRepository>();

    final destinations = destinationRepository.getAll();
    final currentDestination = destinationRepository.currentDestination;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: DEColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DERadius.extraLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: DESpacing.md),

            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: DEColors.border,
                borderRadius: BorderRadius.circular(DERadius.pill),
              ),
            ),

            const SizedBox(height: DESpacing.lg),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DESpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Where are you exploring?",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
            ),

            const SizedBox(height: 6),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DESpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Choose a destination to personalize DiscoverEase.",
                  style: TextStyle(color: DEColors.textSecondary),
                ),
              ),
            ),

            const SizedBox(height: DESpacing.lg),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  DESpacing.lg,
                  0,
                  DESpacing.lg,
                  DESpacing.lg,
                ),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  final isSelected = destination.id == currentDestination.id;

                  return _DestinationCard(
                    name: destination.name,
                    country: destination.country,
                    flagEmoji: destination.flagEmoji,
                    message: destination.atmosphereMessage,
                    imageUrl: destination.heroImageUrl,
                    areaCount: destination.areaIds.length,
                    selected: isSelected,
                    onTap: () {
                      destinationRepository.selectDestination(destination.id);

                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final String name;
  final String country;
  final String flagEmoji;
  final String message;
  final String imageUrl;
  final int areaCount;
  final bool selected;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.name,
    required this.country,
    required this.flagEmoji,
    required this.message,
    required this.imageUrl,
    required this.areaCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DESpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
        child: Ink(
          height: 132,
          decoration: BoxDecoration(
            color: DEColors.surface,
            borderRadius: BorderRadius.circular(DERadius.extraLarge),
            border: Border.all(
              color: selected ? DEColors.primary : DEColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DERadius.extraLarge),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(DESpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              flagEmoji,
                              style: const TextStyle(fontSize: 23),
                            ),
                            const SizedBox(width: DESpacing.sm),
                            Expanded(
                              child: Text(
                                "$name, $country",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DEColors.textSecondary,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Text(
                              "$areaCount areas",
                              style: const TextStyle(
                                color: DEColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 17,
                                color: DEColors.primary,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "Current",
                                style: TextStyle(
                                  color: DEColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  width: 112,
                  height: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(
                        color: DEColors.border,
                        child: Icon(
                          Icons.landscape_rounded,
                          color: DEColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
