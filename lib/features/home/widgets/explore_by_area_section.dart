import 'package:flutter/material.dart';

import '../../../shared/components/sections/de_section_header.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';

class ExploreByAreaSection extends StatelessWidget {
  const ExploreByAreaSection({super.key});

  static const _areas = [
    _AreaData(
      name: "Nassau",
      imageUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
    ),
    _AreaData(
      name: "Paradise Island",
      imageUrl: "https://images.unsplash.com/photo-1544550285-f813152fb2fd",
    ),
    _AreaData(
      name: "Exuma",
      imageUrl: "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
    ),
    _AreaData(
      name: "Harbour Island",
      imageUrl: "https://images.unsplash.com/photo-1473116763249-2faaef81ccda",
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
            itemCount: _areas.length,
            itemBuilder: (context, index) {
              final area = _areas[index];

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

class _AreaData {
  final String name;
  final String imageUrl;

  const _AreaData({required this.name, required this.imageUrl});
}
