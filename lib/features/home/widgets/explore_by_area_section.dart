import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../repositories/destination_repository.dart';
import '../../../shared/components/sections/de_section_header.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';

class ExploreByAreaSection extends StatelessWidget {
  const ExploreByAreaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final destinationRepository = context.watch<DestinationRepository>();

    final areas = destinationRepository.getAreasForCurrentDestination();

    if (areas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DESectionHeader(
          title: "🏝 Explore by Area",
          subtitle: "Discover what each part of the destination has to offer.",
          actionText: "View Areas →",
          onAction: () {
            // Later: open the full area browser.
          },
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];

              return _AreaCard(
                name: area.name,
                imageUrl: area.imageUrl,
                onTap: () {
                  // Later: open Explore filtered to this area.
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AreaCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback? onTap;

  const _AreaCard({required this.name, required this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.large),
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: DESpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DERadius.large),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(DESpacing.md),
          alignment: Alignment.bottomLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DERadius.large),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.68),
              ],
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
